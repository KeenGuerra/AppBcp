# admin_routes.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, require_roles, get_current_user
from app.models.usuario_model import Usuario
from app.schemas.auth_schema import UsuarioResponse
from app.schemas.cliente_schema import ClienteResponse
from app.schemas.asesor_schema import AsesorResponse
from app.schemas.solicitud_schema import ProductoCreditoResponse
from app.repositories import usuario_repository, cliente_repository, asesor_repository, solicitud_repository
from app.models.solicitud_model import ProductoCredito
from app.core.security import get_password_hash
from pydantic import BaseModel, Field
from typing import List, Optional
import uuid
from datetime import datetime
from decimal import Decimal

router = APIRouter(prefix="/admin", tags=["Administrador"])

# Dependency shortcut for Admin Role
def get_admin(current_user: Usuario = Depends(require_roles(["ADMIN"]))):
    return current_user

class UsuarioCreateAdmin(BaseModel):
    documento: str
    codigo_empleado: Optional[str] = None
    correo: Optional[str] = None
    password: str
    rol: str = Field(..., pattern="^(CLIENTE|ASESOR|SUPERVISOR|ADMIN)$")
    estado: str = Field("ACTIVO", pattern="^(ACTIVO|BLOQUEADO|INACTIVO)$")

class UsuarioUpdateAdmin(BaseModel):
    documento: Optional[str] = None
    codigo_empleado: Optional[str] = None
    correo: Optional[str] = None
    password: Optional[str] = None
    rol: Optional[str] = None
    estado: Optional[str] = None

class ProductoCreditoCreateAdmin(BaseModel):
    codigo: str
    nombre: str
    tipo: str
    tea_con_seguro: Decimal
    tea_sin_seguro: Decimal
    monto_minimo: Decimal
    monto_maximo: Decimal
    plazo_minimo: int
    plazo_maximo: int
    moneda: str = "PEN"

class ProductoCreditoUpdateAdmin(BaseModel):
    codigo: Optional[str] = None
    nombre: Optional[str] = None
    tipo: Optional[str] = None
    tea_con_seguro: Optional[Decimal] = None
    tea_sin_seguro: Optional[Decimal] = None
    monto_minimo: Optional[Decimal] = None
    monto_maximo: Optional[Decimal] = None
    plazo_minimo: Optional[int] = None
    plazo_maximo: Optional[int] = None
    moneda: Optional[str] = None
    estado: Optional[str] = None

@router.get("/usuarios", response_model=List[UsuarioResponse])
def get_usuarios(current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    users = usuario_repository.get_usuarios(db)
    res = []
    for u in users:
        # Fetch name
        nombre = "Colaborador BCP"
        if u.rol == "CLIENTE":
            cli = cliente_repository.get_cliente_by_usuario_id(db, u.id_usuario)
            if cli:
                nombre = f"{cli.nombres} {cli.apellidos}"
        else:
            ase = asesor_repository.get_asesor_by_usuario_id(db, u.id_usuario)
            if ase:
                nombre = f"{ase.nombres} {ase.apellidos}"
        res.append(UsuarioResponse(id_usuario=u.id_usuario, rol=u.rol, nombre=nombre, documento=u.documento))
    return res

@router.post("/usuarios", response_model=UsuarioResponse)
def crear_usuario(req: UsuarioCreateAdmin, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    # Verify unique document
    if usuario_repository.get_usuario_by_documento(db, req.documento):
        raise HTTPException(status_code=400, detail="El documento ya se encuentra registrado")
        
    u = Usuario(
        id_usuario=uuid.uuid4(),
        documento=req.documento,
        codigo_empleado=req.codigo_empleado,
        correo=req.correo,
        password_hash=get_password_hash(req.password),
        rol=req.rol,
        estado=req.estado,
        intentos_fallidos=0,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    usuario_repository.create_usuario(db, u)
    return UsuarioResponse(id_usuario=u.id_usuario, rol=u.rol, nombre="Creado", documento=u.documento)

@router.put("/usuarios/{id_usuario}", response_model=UsuarioResponse)
def actualizar_usuario(id_usuario: uuid.UUID, req: UsuarioUpdateAdmin, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    u = usuario_repository.get_usuario_by_id(db, id_usuario)
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
        
    if req.documento is not None:
        u.documento = req.documento
    if req.codigo_empleado is not None:
        u.codigo_empleado = req.codigo_empleado
    if req.correo is not None:
        u.correo = req.correo
    if req.password is not None:
        u.password_hash = get_password_hash(req.password)
    if req.rol is not None:
        u.rol = req.rol
    if req.estado is not None:
        u.estado = req.estado
        if req.estado == "ACTIVO":
            u.intentos_fallidos = 0
            u.bloqueado_hasta = None

    usuario_repository.update_usuario(db, u)
    return UsuarioResponse(id_usuario=u.id_usuario, rol=u.rol, nombre="Actualizado", documento=u.documento)

@router.delete("/usuarios/{id_usuario}")
def eliminar_usuario(id_usuario: uuid.UUID, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    u = usuario_repository.get_usuario_by_id(db, id_usuario)
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    usuario_repository.delete_usuario(db, u)
    return {"message": "Usuario eliminado correctamente"}

@router.get("/clientes", response_model=List[ClienteResponse])
def get_clientes(current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    return cliente_repository.get_clientes(db)

@router.get("/asesores", response_model=List[AsesorResponse])
def get_asesores(current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    return asesor_repository.get_asesores(db)

@router.get("/creditos")
def get_creditos_admin(current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    from app.models.credito_model import Credito
    creditos = db.query(Credito).all()
    result = []
    for c in creditos:
        result.append({
            "id_credito": str(c.id_credito),
            "numero_credito": c.numero_credito,
            "id_cliente": str(c.id_cliente),
            "id_solicitud": str(c.id_solicitud) if c.id_solicitud else None,
            "monto_desembolsado": float(c.monto_desembolsado) if c.monto_desembolsado else 0.0,
            "tasa_interes": float(c.tasa_interes) if c.tasa_interes else 0.0,
            "plazo_meses": c.plazo_meses,
            "saldo_capital": float(c.saldo_capital) if c.saldo_capital else 0.0,
            "cuota_mensual": float(c.cuota_mensual) if c.cuota_mensual else 0.0,
            "estado": c.estado,
            "fecha_desembolso": c.fecha_desembolso.isoformat() if hasattr(c.fecha_desembolso, 'isoformat') else str(c.fecha_desembolso) if c.fecha_desembolso else None,
        })
    return result

@router.get("/creditos/{id_credito}/cronograma")
def get_cronograma_admin(id_credito: uuid.UUID, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    from app.models.cronograma_model import CronogramaPago
    pagos = db.query(CronogramaPago).filter(CronogramaPago.id_credito == id_credito).order_by(CronogramaPago.numero_cuota).all()
    return [
        {
            "id_pago": str(p.id_pago),
            "id_credito": str(p.id_credito),
            "numero_cuota": p.numero_cuota,
            "fecha_pago": p.fecha_pago.isoformat() if hasattr(p.fecha_pago, 'isoformat') else str(p.fecha_pago) if p.fecha_pago else None,
            "monto_cuota": float(p.monto_cuota) if p.monto_cuota else 0.0,
            "capital": float(p.capital) if p.capital else 0.0,
            "interes": float(p.interes) if p.interes else 0.0,
            "seguro_desgravamen": float(p.seguro_desgravamen) if p.seguro_desgravamen else 0.0,
            "monto_pagado": float(p.monto_pagado) if p.monto_pagado else 0.0,
            "estado": p.estado,
        }
        for p in pagos
    ]

@router.get("/productos-creditos", response_model=List[ProductoCreditoResponse])
def get_productos(current_user: Usuario = Depends(get_current_user), db: Session = Depends(get_db)):
    return solicitud_repository.get_productos(db)

@router.post("/productos-creditos", response_model=ProductoCreditoResponse)
def crear_producto(req: ProductoCreditoCreateAdmin, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    if solicitud_repository.get_producto_by_codigo(db, req.codigo):
        raise HTTPException(status_code=400, detail="Código de producto ya existe")
        
    p = ProductoCredito(
        id_producto_credito=uuid.uuid4(),
        codigo=req.codigo,
        nombre=req.nombre,
        tipo=req.tipo,
        tea_con_seguro=req.tea_con_seguro,
        tea_sin_seguro=req.tea_sin_seguro,
        monto_minimo=req.monto_minimo,
        monto_maximo=req.monto_maximo,
        plazo_minimo=req.plazo_minimo,
        plazo_maximo=req.plazo_maximo,
        moneda=req.moneda,
        estado="ACTIVO",
        created_at=datetime.utcnow()
    )
    solicitud_repository.create_producto(db, p)
    return p

@router.put("/productos-creditos/{id_producto}", response_model=ProductoCreditoResponse)
def actualizar_producto(id_producto: uuid.UUID, req: ProductoCreditoUpdateAdmin, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    p = solicitud_repository.get_producto_by_id(db, id_producto)
    if not p:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
        
    if req.codigo is not None:
        p.codigo = req.codigo
    if req.nombre is not None:
        p.nombre = req.nombre
    if req.tipo is not None:
        p.tipo = req.tipo
    if req.tea_con_seguro is not None:
        p.tea_con_seguro = req.tea_con_seguro
    if req.tea_sin_seguro is not None:
        p.tea_sin_seguro = req.tea_sin_seguro
    if req.monto_minimo is not None:
        p.monto_minimo = req.monto_minimo
    if req.monto_maximo is not None:
        p.monto_maximo = req.monto_maximo
    if req.plazo_minimo is not None:
        p.plazo_minimo = req.plazo_minimo
    if req.plazo_maximo is not None:
        p.plazo_maximo = req.plazo_maximo
    if req.moneda is not None:
        p.moneda = req.moneda
    if req.estado is not None:
        p.estado = req.estado

    solicitud_repository.update_producto(db, p)
    return p

# Real-time / live dashboard endpoints
@router.get("/banking/stats")
def get_banking_stats(current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    from app.models.banking_model import (
        BankingTransaccion, BankingTransferencia, BankingPagoServicio,
        BankingRecarga, BankingPrestamo, BankingAhorro, BankingComprobante
    )
    from sqlalchemy import func
    
    total_transacciones = db.query(BankingTransaccion).count()
    total_transferencias = db.query(BankingTransferencia).count()
    total_pagos = db.query(BankingPagoServicio).count()
    total_recargas = db.query(BankingRecarga).count()
    total_prestamos = db.query(BankingPrestamo).count()
    total_ahorros = db.query(BankingAhorro).count()

    monto_transacciones = sum(float(t.monto or 0) for t in db.query(BankingTransaccion).all())
    monto_transferencias = sum(float(t.monto or 0) for t in db.query(BankingTransferencia).all())
    monto_pagos = sum(float(t.monto or 0) for t in db.query(BankingPagoServicio).all())
    monto_comprobantes = sum(float(t.monto or 0) for t in db.query(BankingComprobante).all())

    return {
        "totales": {
            "transacciones": total_transacciones,
            "transferencias": total_transferencias,
            "pagos_servicios": total_pagos,
            "recargas": total_recargas,
            "prestamos": total_prestamos,
            "ahorros": total_ahorros,
        },
        "montos": {
            "transacciones": round(float(monto_transacciones), 2),
            "transferencias": round(float(monto_transferencias), 2),
            "pagos_servicios": round(float(monto_pagos), 2),
            "monto_total_operado": round(float(monto_comprobantes), 2),
        }
    }

@router.get("/banking/transacciones")
def get_admin_transacciones(limit: int = 50, offset: int = 0, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    from app.models.banking_model import BankingTransaccion
    txs = db.query(BankingTransaccion).order_by(BankingTransaccion.created_at.desc()).offset(offset).limit(limit).all()
    
    res = []
    for t in txs:
        fecha_str = t.created_at.isoformat() if isinstance(t.created_at, datetime) else str(t.created_at) if t.created_at else datetime.utcnow().isoformat()
        res.append({
            "id": str(t.id),
            "user_id": str(t.id_usuario),
            "cuenta_id": t.cuenta_id,
            "tipo": t.tipo,
            "monto": float(t.monto),
            "descripcion": t.descripcion,
            "fecha": fecha_str,
            "estado": t.estado
        })
    return res

@router.get("/resumen-live")
def get_resumen_live(current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    from app.models.banking_model import (
        BankingTransaccion, BankingTransferencia, BankingPagoServicio,
        BankingRecarga, BankingPrestamo, BankingAhorro, BankingComprobante
    )
    from app.models.usuario_model import Usuario as DB_Usuario
    from app.models.solicitud_model import SolicitudCredito
    from sqlalchemy import func

    # Core Stats
    total_usuarios = db.query(DB_Usuario).count()
    total_clientes = db.query(DB_Usuario).filter(DB_Usuario.rol == "CLIENTE").count()
    total_asesores = db.query(DB_Usuario).filter(DB_Usuario.rol == "ASESOR").count()
    total_solicitudes = db.query(SolicitudCredito).count()
    solicitudes_pendientes = db.query(SolicitudCredito).filter(SolicitudCredito.estado == "PENDIENTE").count()

    # Banking Stats
    total_transacciones = db.query(BankingTransaccion).count()
    total_transferencias = db.query(BankingTransferencia).count()
    total_pagos = db.query(BankingPagoServicio).count()
    
    monto_transacciones = sum(float(t.monto or 0) for t in db.query(BankingTransaccion).all())
    monto_transferencias = sum(float(t.monto or 0) for t in db.query(BankingTransferencia).all())
    monto_pagos = sum(float(t.monto or 0) for t in db.query(BankingPagoServicio).all())
    monto_comprobantes = sum(float(t.monto or 0) for t in db.query(BankingComprobante).all())

    return {
        "usuarios": {
            "total": total_usuarios,
            "clientes": total_clientes,
            "asesores": total_asesores
        },
        "solicitudes": {
            "total": total_solicitudes,
            "pendientes": solicitudes_pendientes
        },
        "banking": {
            "transacciones": total_transacciones,
            "transferencias": total_transferencias,
            "pagos": total_pagos,
            "monto_operado": round(float(monto_comprobantes), 2),
            "monto_depositos": round(float(monto_transacciones), 2)
        },
        "timestamp": datetime.utcnow().isoformat()
    }

@router.get("/fventas/mora")
def get_admin_mora_list(current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    from app.models.cartera_model import CarteraDiaria
    from app.models.cronograma_model import CronogramaPago
    from app.models.credito_model import Credito
    from app.models.asesor_model import Asesor
    import datetime

    # Get all items in recuperacion mora
    items = db.query(CarteraDiaria).filter(
        CarteraDiaria.tipo_gestion == "RECUPERACION_MORA"
    ).all()

    today = datetime.date.today()
    result = []
    monto_total_vencido = 0.0

    for item in items:
        cliente = item.cliente
        if not cliente:
            continue

        # Get advisor name
        asesor_name = "Sin Asesor"
        if item.id_asesor:
            ase = db.query(Asesor).filter(Asesor.id_asesor == item.id_asesor).first()
            if ase:
                asesor_name = f"{ase.nombres} {ase.apellidos}"

        creditos = db.query(Credito).filter(Credito.id_cliente == cliente.id_cliente).all()
        credito_ids = [c.id_credito for c in creditos]
        
        monto_vencido = 0.0
        dias_mora = 0
        
        if credito_ids:
            overdue_cuotas = db.query(CronogramaPago).filter(
                CronogramaPago.id_credito.in_(credito_ids),
                CronogramaPago.estado.in_(["VENCIDA", "PENDIENTE"]),
                CronogramaPago.fecha_pago < today
            ).all()
            
            monto_vencido = sum(float(q.monto_cuota - q.monto_pagado) for q in overdue_cuotas)
            if overdue_cuotas:
                def get_days_diff(q):
                    fp = q.fecha_pago
                    if isinstance(fp, str):
                        try:
                            parts = [int(x) for x in fp.split('T')[0].split('-')]
                            fp_date = datetime.date(parts[0], parts[1], parts[2])
                        except Exception:
                            fp_date = today
                    elif isinstance(fp, datetime.datetime):
                        fp_date = fp.date()
                    elif isinstance(fp, datetime.date):
                        fp_date = fp
                    else:
                        fp_date = today
                    return (today - fp_date).days if fp_date else 0
                dias_mora = max(get_days_diff(q) for q in overdue_cuotas)

        from app.models.visita_model import VisitaCliente
        last_visit = db.query(VisitaCliente).filter(
            VisitaCliente.id_cliente == cliente.id_cliente
        ).order_by(VisitaCliente.fecha_hora.desc()).first()
        fecha_ultimo_contacto = None
        if last_visit and last_visit.fecha_hora:
            fecha_ultimo_contacto = last_visit.fecha_hora.isoformat() if hasattr(last_visit.fecha_hora, 'isoformat') else last_visit.fecha_hora

        result.append({
            "id_cartera": str(item.id_cartera),
            "id_cliente": str(cliente.id_cliente),
            "cliente_nombre": f"{cliente.nombres} {cliente.apellidos}",
            "documento": cliente.documento,
            "dias_mora": dias_mora,
            "monto_vencido": round(monto_vencido, 2),
            "fecha_ultimo_contacto": fecha_ultimo_contacto,
            "prioridad": item.prioridad,
            "asesor_nombre": asesor_name
        })
        monto_total_vencido += monto_vencido

    result.sort(key=lambda x: x["dias_mora"], reverse=True)

    return {
        "mora_list": result,
        "monto_total_vencido": round(monto_total_vencido, 2)
    }


