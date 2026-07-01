# desembolso_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories import solicitud_repository, credito_repository, cronograma_repository, movimiento_repository, cuenta_repository
from app.models.credito_model import Credito
from app.models.cronograma_model import CronogramaPago
from app.models.movimiento_model import Movimiento
from app.models.sync_model import SyncLog
from app.services.preevaluacion_service import calcular_cuota_estimada
from app.services.notificacion_service import crear_notificacion_automatica
from app.services.sync_service import encolar_evento_sync
from datetime import datetime, date, timedelta
from decimal import Decimal
import uuid
import random
import math

def desembolsar_solicitud(db: Session, id_solicitud: uuid.UUID) -> Credito:
    # 1. Validate request state - eagerly load producto and cliente
    sol = solicitud_repository.get_solicitud_by_id_with_relations(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    if sol.estado != "APROBADO":
        raise HTTPException(status_code=400, detail="La solicitud debe estar aprobada para ser desembolsada")
    
    # Ensure related objects are loaded (avoid lazy loading issues)
    if not sol.producto:
        raise HTTPException(status_code=400, detail="Producto de crédito no encontrado para esta solicitud")
    if not sol.cliente:
        raise HTTPException(status_code=400, detail="Cliente no encontrado para esta solicitud")

    # 2. Get client accounts
    cuentas = cuenta_repository.get_cuentas_by_cliente_id(db, sol.id_cliente)
    if not cuentas:
        raise HTTPException(status_code=400, detail="El cliente no posee cuentas de ahorros para el desembolso")
    cta_destino = cuentas[0] # Deposit into their first savings account

    monto_des = Decimal(str(sol.monto_aprobado or sol.monto_solicitado))

    # 3. Create credit record
    num_credito = f"CRE-{random.randint(10000000, 99999999)}"
    tea_f = float(sol.tea_referencial) / 100.0
    tem_f = math.pow(1.0 + tea_f, 1.0 / 12.0) - 1.0
    tem_dec = Decimal(str(round(tem_f, 6)))

    cuota_mensual = calcular_cuota_estimada(monto_des, sol.tea_referencial, sol.plazo_meses)

    credito = Credito(
        id_credito=uuid.uuid4(),
        id_solicitud=sol.id_solicitud,
        id_cliente=sol.id_cliente,
        numero_credito=num_credito,
        producto=sol.producto.nombre,
        monto_desembolsado=monto_des,
        saldo_capital=monto_des,
        plazo_meses=sol.plazo_meses,
        tea=sol.tea_referencial,
        tem=tem_dec,
        cuota_mensual=cuota_mensual,
        fecha_desembolso=date.today(),
        dia_pago=date.today().day,
        estado="VIGENTE",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    credito_repository.create_credito(db, credito)

    # 4. Generate French Amortization Schedule
    # Formula:
    # interes = saldo_actual * TEM
    # capital = cuota - interes
    # saldo = saldo_actual - capital
    saldo_actual = monto_des
    cuotas = []
    fecha_base = date.today()

    for idx in range(1, sol.plazo_meses + 1):
        # Calculate interest and capital
        interes = saldo_actual * tem_dec
        interes = Decimal(str(round(float(interes), 2)))
        
        if idx == sol.plazo_meses:
            # Adjust final installment to match 0.00 balance
            capital = saldo_actual
            cuota_monto = capital + interes
            saldo_nuevo = Decimal("0.00")
        else:
            capital = cuota_mensual - interes
            capital = Decimal(str(round(float(capital), 2)))
            saldo_nuevo = saldo_actual - capital
            saldo_nuevo = Decimal(str(round(float(saldo_nuevo), 2)))
            cuota_monto = cuota_mensual

        # Next payment date (roughly 30 days later)
        # We can add months or simply 30 days
        fecha_pago = fecha_base + timedelta(days=30 * idx)

        cuota = CronogramaPago(
            id_cuota=uuid.uuid4(),
            id_credito=credito.id_credito,
            numero_cuota=idx,
            fecha_pago=fecha_pago,
            monto_cuota=cuota_monto,
            capital=capital,
            interes=interes,
            saldo=saldo_nuevo,
            estado="PENDIENTE",
            created_at=datetime.utcnow()
        )
        cuotas.append(cuota)
        saldo_actual = saldo_nuevo

    cronograma_repository.create_cuotas(db, cuotas)

    # 5. Credit Customer's Savings Account
    cta_destino.saldo_disponible += monto_des
    cta_destino.saldo_contable += monto_des
    db.commit()

    # 6. Create disbursement transaction log
    mov = Movimiento(
        id_movimiento=uuid.uuid4(),
        id_cliente=sol.id_cliente,
        id_cuenta=cta_destino.id_cuenta,
        id_credito=credito.id_credito,
        tipo_movimiento="DESEMBOLSO_CREDITO",
        descripcion=f"Desembolso Crédito {num_credito}",
        monto=monto_des,
        moneda=sol.moneda,
        fecha_movimiento=datetime.utcnow(),
        canal="VENTANILLA",
        created_at=datetime.utcnow()
    )
    movimiento_repository.create_movimiento(db, mov)

    # 7. Update credit request state
    sol.estado = "DESEMBOLSADO"
    db.commit()

    # 8. Dispatch notification
    crear_notificacion_automatica(
        db, 
        id_usuario=sol.cliente.id_usuario,
        titulo="Crédito Desembolsado",
        mensaje=f"Tu crédito {num_credito} por S/ {monto_des} ha sido desembolsado exitosamente en tu cuenta {cta_destino.numero_cuenta}.",
        tipo="CREDITO_DESEMBOLSADO"
    )

    # 9. Register sync_outbox & sync_log
    encolar_evento_sync(
        db, 
        tipo_evento="CREDITO_DESEMBOLSADO",
        entidad="cr_creditos",
        entidad_id=credito.id_credito,
        payload={"numero_credito": num_credito, "monto": float(monto_des), "cuenta_deposito": cta_destino.numero_cuenta}
    )

    return credito
