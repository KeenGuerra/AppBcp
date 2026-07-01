# solicitud_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories import solicitud_repository, cliente_repository, asesor_repository
from app.models.solicitud_model import SolicitudCredito
from app.models.cartera_model import CarteraDiaria
from app.schemas.solicitud_schema import SolicitudCreditoCreate, SolicitudCreditoUpdate
from app.services.preevaluacion_service import calcular_cuota_estimada, evaluar_solicitud
from datetime import datetime, date
from decimal import Decimal
import uuid
import random

def generar_numero_expediente() -> str:
    # EXP- + 8 random digits
    return f"EXP-{random.randint(10000000, 99999999)}"

def crear_solicitud_cliente(db: Session, id_usuario_cliente: uuid.UUID, req: SolicitudCreditoCreate) -> SolicitudCredito:
    # 1. Verify client owns profile
    cliente = cliente_repository.get_cliente_by_usuario_id(db, id_usuario_cliente)
    if not cliente or cliente.id_cliente != req.id_cliente:
        raise HTTPException(status_code=403, detail="No autorizado para crear solicitudes para este cliente")

    # Verify business - auto-create if missing
    negocio = cliente_repository.get_negocio_by_id(db, req.id_negocio)
    if not negocio or negocio.id_cliente != req.id_cliente:
        negocios_existentes = cliente_repository.get_negocios_by_cliente_id(db, cliente.id_cliente)
        if negocios_existentes:
            negocio = negocios_existentes[0]
        else:
            from app.models.cliente_model import NegocioCliente
            negocio = NegocioCliente(
                id_negocio=uuid.uuid4(),
                id_cliente=cliente.id_cliente,
                nombre_comercial=f"Negocio de {cliente.nombres}",
                giro_negocio="Comercio General",
                antiguedad_meses=12,
                ingreso_mensual=Decimal("3000.00"),
                gasto_mensual=Decimal("1000.00"),
                estado="ACTIVO",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow()
            )
            db.add(negocio)
            db.commit()
            db.refresh(negocio)

    # Fetch product details
    prod = solicitud_repository.get_producto_by_id(db, req.id_producto_credito)
    if not prod:
        raise HTTPException(status_code=404, detail="Producto de crédito no encontrado")

    # Validate limits
    if req.monto_solicitado < prod.monto_minimo or req.monto_solicitado > prod.monto_maximo:
        raise HTTPException(status_code=400, detail=f"El monto debe estar entre {prod.monto_minimo} y {prod.monto_maximo}")
    if req.plazo_meses < prod.plazo_minimo or req.plazo_meses > prod.plazo_maximo:
        raise HTTPException(status_code=400, detail=f"El plazo debe estar entre {prod.plazo_minimo} y {prod.plazo_maximo} meses")

    # 2. Assign advisor (asesor)
    # Find advisors in the customer's agency
    asesores_agencia = db.query(asesor_repository.Asesor).filter(
        asesor_repository.Asesor.id_agencia == cliente.id_agencia,
        asesor_repository.Asesor.estado == "ACTIVO"
    ).all()

    if asesores_agencia:
        asesor_asignado = asesores_agencia[0]
    else:
        # Fallback to any advisor
        all_asesores = db.query(asesor_repository.Asesor).filter(asesor_repository.Asesor.estado == "ACTIVO").all()
        if not all_asesores:
            raise HTTPException(status_code=500, detail="No hay asesores activos disponibles en el sistema")
        asesor_asignado = all_asesores[0]

    # 3. Calculate initial cuota estimación
    tea = prod.tea_con_seguro if req.con_seguro_desgravamen else prod.tea_sin_seguro
    cuota_est = calcular_cuota_estimada(req.monto_solicitado, tea, req.plazo_meses)

    # 4. Create request
    solicitud = SolicitudCredito(
        id_solicitud=uuid.uuid4(),
        numero_expediente=generar_numero_expediente(),
        id_cliente=req.id_cliente,
        id_negocio=req.id_negocio,
        id_asesor=asesor_asignado.id_asesor,
        id_producto_credito=req.id_producto_credito,
        canal_origen="CLIENTE",
        monto_solicitado=req.monto_solicitado,
        monto_aprobado=None,
        plazo_meses=req.plazo_meses,
        moneda="PEN",
        tea_referencial=tea,
        con_seguro_desgravamen=req.con_seguro_desgravamen,
        garantia=req.garantia,
        destino_credito=req.destino_credito,
        cuota_estimada=cuota_est,
        estado="ENVIADO",
        lat_captura=req.lat_captura,
        lng_captura=req.lng_captura,
        pendiente_sync=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    solicitud_repository.create_solicitud(db, solicitud)

    # 5. Place in Advisor's daily portfolio
    cartera = CarteraDiaria(
        id_cartera=uuid.uuid4(),
        id_asesor=asesor_asignado.id_asesor,
        id_cliente=req.id_cliente,
        id_solicitud=solicitud.id_solicitud,
        fecha_asignacion=date.today(),
        tipo_gestion="NUEVA_SOLICITUD",
        prioridad="ALTA",
        score_prioridad=80,
        estado_visita="PENDIENTE",
        pendiente_sync=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(cartera)
    
    # Save sync outbox event
    from app.services.sync_service import encolar_evento_sync
    encolar_evento_sync(
        db, 
        tipo_evento="SOLICITUD_CREADA",
        entidad="solicitudes_credito",
        entidad_id=solicitud.id_solicitud,
        payload={"numero_expediente": solicitud.numero_expediente, "monto": float(solicitud.monto_solicitado)}
    )

    db.commit()
    db.refresh(solicitud)
    return solicitud

def crear_solicitud_asesor(db: Session, id_usuario_asesor: uuid.UUID, req: SolicitudCreditoCreate) -> SolicitudCredito:
    asesor = asesor_repository.get_asesor_by_usuario_id(db, id_usuario_asesor)
    if not asesor:
        raise HTTPException(status_code=403, detail="No autorizado: Usuario no es un asesor válido")

    prod = solicitud_repository.get_producto_by_id(db, req.id_producto_credito)
    if not prod:
        raise HTTPException(status_code=404, detail="Producto no encontrado")

    tea = prod.tea_con_seguro if req.con_seguro_desgravamen else prod.tea_sin_seguro
    cuota_est = calcular_cuota_estimada(req.monto_solicitado, tea, req.plazo_meses)

    target_client_id = req.id_cliente
    target_business_id = req.id_negocio

    # If cliente_documento is provided, resolve the client (or create it)
    if req.cliente_documento:
        from app.models.cliente_model import Cliente, NegocioCliente
        from app.models.usuario_model import Usuario
        
        # Look for existing client with this DNI
        existing_cli = db.query(Cliente).filter(Cliente.documento == req.cliente_documento).first()
        if existing_cli:
            target_client_id = existing_cli.id_cliente
            biz = db.query(NegocioCliente).filter(NegocioCliente.id_cliente == existing_cli.id_cliente).first()
            if biz:
                target_business_id = biz.id_negocio
            else:
                new_biz = NegocioCliente(
                    id_negocio=uuid.uuid4(),
                    id_cliente=existing_cli.id_cliente,
                    nombre_comercial=f"Bodega de {existing_cli.nombres}",
                    giro_negocio="Comercio General",
                    antiguedad_meses=12,
                    ingreso_mensual=3000.0,
                    gasto_mensual=1000.0,
                    estado="ACTIVO",
                    created_at=datetime.datetime.utcnow(),
                    updated_at=datetime.datetime.utcnow()
                )
                db.add(new_biz)
                db.commit()
                target_business_id = new_biz.id_negocio
        else:
            # Create a new user for this client
            new_user_id = uuid.uuid4()
            new_user = Usuario(
                id_usuario=new_user_id,
                documento=req.cliente_documento,
                correo=f"cliente.{req.cliente_documento}@bcp.com.pe",
                password_hash="$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe", # default password '123456'
                role="CLIENTE",  # Pydantic or SQLAlchemy model fields check: let's verify if the field is 'rol' or 'role'.
                estado="ACTIVO"
            )
            # Wait, in the database table we saw 'rol' not 'role'! Yes: 'rol VARCHAR(20)'. Let's use 'rol="CLIENTE"'
            new_user.rol = "CLIENTE"
            db.add(new_user)
            db.commit()
            
            # Split names and surnames
            nombres = req.cliente_nombres or "Cliente"
            apellidos = req.cliente_apellidos or "Nuevo"
            if " " in nombres and not req.cliente_apellidos:
                parts = nombres.split(" ", 1)
                nombres = parts[0]
                apellidos = parts[1]

            new_cli_id = uuid.uuid4()
            new_cli = Cliente(
                id_cliente=new_cli_id,
                id_usuario=new_user_id,
                id_agencia=asesor.id_agencia or uuid.UUID('d0000000-0000-0000-0000-000000000001'),
                documento=req.cliente_documento,
                nombres=nombres,
                apellidos=apellidos,
                telefono="999000111",
                correo=f"cliente.{req.cliente_documento}@bcp.com.pe",
                direccion="Calle Principal 123",
                distrito="Lima",
                provincia="Lima",
                departamento="Lima",
                fecha_nacimiento=datetime.date(1990, 1, 1),
                estado_civil="SOLTERO",
                ocupacion="Independiente",
                tipo_cliente="PN",
                estado="ACTIVO",
                created_at=datetime.datetime.utcnow(),
                updated_at=datetime.datetime.utcnow()
            )
            db.add(new_cli)
            db.commit()
            
            # Create a default business
            new_biz_id = uuid.uuid4()
            new_biz = NegocioCliente(
                id_negocio=new_biz_id,
                id_cliente=new_cli_id,
                nombre_comercial=f"Negocio de {nombres}",
                giro_negocio="Comercio General",
                antiguedad_meses=12,
                ingreso_mensual=3000.0,
                gasto_mensual=1000.0,
                estado="ACTIVO",
                created_at=datetime.datetime.utcnow(),
                updated_at=datetime.datetime.utcnow()
            )
            db.add(new_biz)
            db.commit()
            
            target_client_id = new_cli_id
            target_business_id = new_biz_id

    solicitud = SolicitudCredito(
        id_solicitud=uuid.uuid4(),
        numero_expediente=generar_numero_expediente(),
        id_cliente=target_client_id,
        id_negocio=target_business_id,
        id_asesor=asesor.id_asesor,
        id_producto_credito=req.id_producto_credito,
        canal_origen="ASESOR",
        monto_solicitado=req.monto_solicitado,
        monto_aprobado=None,
        plazo_meses=req.plazo_meses,
        moneda="PEN",
        tea_referencial=tea,
        con_seguro_desgravamen=req.con_seguro_desgravamen,
        garantia=req.garantia,
        destino_credito=req.destino_credito,
        cuota_estimada=cuota_est,
        estado="BORRADOR",
        lat_captura=req.lat_captura,
        lng_captura=req.lng_captura,
        pendiente_sync=False,
        created_at=datetime.datetime.utcnow(),
        updated_at=datetime.datetime.utcnow()
    )
    solicitud_repository.create_solicitud(db, solicitud)
    return solicitud

def preevaluar_solicitud_asesor(db: Session, id_solicitud: uuid.UUID) -> dict:
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    # Fetch business financial numbers
    negocio = sol.negocio
    if not negocio:
        raise HTTPException(status_code=400, detail="El cliente no registra datos de negocio")

    # Evaluate capacity of payment
    eval_res = evaluar_solicitud(negocio.ingreso_mensual, negocio.gasto_mensual, sol.cuota_estimada)

    # Save to request
    sol.resultado_preevaluacion = eval_res["resultado"]
    sol.puntaje_preevaluacion = eval_res["puntaje"]
    db.commit()

    return eval_res
