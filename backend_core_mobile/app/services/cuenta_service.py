# cuenta_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories import cuenta_repository, credito_repository, cronograma_repository, movimiento_repository
from app.models.movimiento_model import Movimiento, OperacionCliente
from app.schemas.cuenta_schema import TransferenciaRequest, PagoCreditoRequest
from datetime import datetime
import uuid
from decimal import Decimal

def get_cuentas_by_cliente_id(db: Session, id_cliente: uuid.UUID):
    return cuenta_repository.get_cuentas_by_cliente_id(db, id_cliente)

def get_tarjetas_by_cliente_id(db: Session, id_cliente: uuid.UUID):
    return cuenta_repository.get_tarjetas_by_cliente_id(db, id_cliente)

def transferir(db: Session, id_cliente: uuid.UUID, req: TransferenciaRequest) -> OperacionCliente:
    # 1. Validate source account
    cta_origen = cuenta_repository.get_cuenta_by_id(db, req.cuenta_origen_id)
    if not cta_origen or cta_origen.id_cliente != id_cliente:
        raise HTTPException(status_code=404, detail="Cuenta de origen no encontrada")
        
    if cta_origen.saldo_disponible < req.monto:
        raise HTTPException(status_code=400, detail="Saldo insuficiente en cuenta de origen")

    # 2. Validate destination account
    cta_destino = cuenta_repository.get_cuenta_by_numero(db, req.cuenta_destino_numero)
    if not cta_destino:
        raise HTTPException(status_code=404, detail="Cuenta de destino no encontrada")

    # 3. Create customer operation log
    operacion = OperacionCliente(
        id_operacion=uuid.uuid4(),
        id_cliente=id_cliente,
        tipo_operacion="TRANSFERENCIA",
        cuenta_origen=req.cuenta_origen_id,
        cuenta_destino=req.cuenta_destino_numero,
        monto=req.monto,
        moneda=cta_origen.moneda,
        descripcion=req.descripcion or f"Transferencia a cta {req.cuenta_destino_numero}",
        estado="PROCESADA",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    movimiento_repository.create_operacion(db, operacion)

    # 4. Perform balance updates
    cta_origen.saldo_disponible -= req.monto
    cta_origen.saldo_contable -= req.monto
    
    cta_destino.saldo_disponible += req.monto
    cta_destino.saldo_contable += req.monto
    
    db.commit()

    # 5. Create movements
    mov_orig = Movimiento(
        id_movimiento=uuid.uuid4(),
        id_cliente=id_cliente,
        id_cuenta=cta_origen.id_cuenta,
        tipo_movimiento="TRANSFERENCIA",
        descripcion=f"Transf. Enviada a cta {req.cuenta_destino_numero}",
        monto=-req.monto,
        moneda=cta_origen.moneda,
        fecha_movimiento=datetime.utcnow(),
        canal="BANCA_MOVIL",
        created_at=datetime.utcnow()
    )
    movimiento_repository.create_movimiento(db, mov_orig)

    mov_dest = Movimiento(
        id_movimiento=uuid.uuid4(),
        id_cliente=cta_destino.id_cliente,
        id_cuenta=cta_destino.id_cuenta,
        tipo_movimiento="TRANSFERENCIA",
        descripcion=f"Transf. Recibida de cta {cta_origen.numero_cuenta}",
        monto=req.monto,
        moneda=cta_destino.moneda,
        fecha_movimiento=datetime.utcnow(),
        canal="BANCA_MOVIL",
        created_at=datetime.utcnow()
    )
    movimiento_repository.create_movimiento(db, mov_dest)

    # Trigger notifications / sync_outbox if needed
    # ...
    
    return operacion

def pagar_cuota_credito(db: Session, id_cliente: uuid.UUID, req: PagoCreditoRequest) -> OperacionCliente:
    # 1. Validate source account
    cta_origen = cuenta_repository.get_cuenta_by_id(db, req.cuenta_origen_id)
    if not cta_origen or cta_origen.id_cliente != id_cliente:
        raise HTTPException(status_code=404, detail="Cuenta de origen no encontrada")
        
    if cta_origen.saldo_disponible < req.monto:
        raise HTTPException(status_code=400, detail="Saldo insuficiente en cuenta de origen")

    # 2. Validate active credit
    credito = credito_repository.get_credito_by_id(db, req.credito_id)
    if not credito or credito.id_cliente != id_cliente:
        raise HTTPException(status_code=404, detail="Crédito no encontrado")

    # 3. Validate installment cuota
    cuota = cronograma_repository.get_cuota_by_numero(db, req.credito_id, req.numero_cuota)
    if not cuota:
        raise HTTPException(status_code=404, detail="Cuota no encontrada")
    if cuota.estado == "PAGADA":
        raise HTTPException(status_code=400, detail="La cuota ya se encuentra pagada")

    # 4. Process payment
    restante_cuota = cuota.monto_cuota - cuota.monto_pagado
    monto_aplicado = min(req.monto, restante_cuota)

    # Deduct account balance
    cta_origen.saldo_disponible -= req.monto
    cta_origen.saldo_contable -= req.monto

    # Update cuota amounts and status
    cuota.monto_pagado += monto_aplicado
    if cuota.monto_pagado >= cuota.monto_cuota:
        cuota.estado = "PAGADA"
        cuota.fecha_pago_real = datetime.utcnow().date()
    else:
        cuota.estado = "PARCIAL"

    # Reduce loan capital
    # The paid capital portion of the cuota contributes to reducing the credit balance.
    # In French method: cuota = capital + interes. The capital portion paid is what reduces the balance.
    # Since we can pay partially, we reduce proportional capital or simply the capital of the cuota if fully paid.
    # For safety: capital_reduction = (monto_aplicado / cuota.monto_cuota) * cuota.capital
    capital_proporcion = (monto_aplicado / cuota.monto_cuota) * cuota.capital
    credito.saldo_capital = max(Decimal("0.00"), credito.saldo_capital - capital_proporcion)
    
    if credito.saldo_capital == 0:
        credito.estado = "CANCELADO"

    # 5. Create customer operation log
    operacion = OperacionCliente(
        id_operacion=uuid.uuid4(),
        id_cliente=id_cliente,
        tipo_operacion="PAGO_CREDITO",
        cuenta_origen=req.cuenta_origen_id,
        id_credito=req.credito_id,
        monto=req.monto,
        moneda=cta_origen.moneda,
        descripcion=f"Pago cuota {req.numero_cuota} de cred {credito.numero_credito}",
        estado="PROCESADA",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    movimiento_repository.create_operacion(db, operacion)
    db.commit()

    # 6. Create account movement
    mov_acc = Movimiento(
        id_movimiento=uuid.uuid4(),
        id_cliente=id_cliente,
        id_cuenta=cta_origen.id_cuenta,
        id_credito=req.credito_id,
        tipo_movimiento="PAGO_CUOTA",
        descripcion=f"Pago Cuota {req.numero_cuota} - Crédito {credito.numero_credito}",
        monto=-req.monto,
        moneda=cta_origen.moneda,
        fecha_movimiento=datetime.utcnow(),
        canal="BANCA_MOVIL",
        created_at=datetime.utcnow()
    )
    movimiento_repository.create_movimiento(db, mov_acc)

    # 7. Create credit movement
    mov_crd = Movimiento(
        id_movimiento=uuid.uuid4(),
        id_cliente=id_cliente,
        id_credito=req.credito_id,
        tipo_movimiento="PAGO_CUOTA",
        descripcion=f"Amortización Cuota {req.numero_cuota}",
        monto=monto_aplicado,
        moneda=credito.cliente.agencia.departamento, # wait, credit currency is PEN
        fecha_movimiento=datetime.utcnow(),
        canal="BANCA_MOVIL",
        created_at=datetime.utcnow()
    )
    # Fix currency
    mov_crd.moneda = "PEN"
    movimiento_repository.create_movimiento(db, mov_crd)

    # Send Notification to customer
    from app.services.notificacion_service import crear_notificacion_automatica
    crear_notificacion_automatica(
        db, 
        id_usuario=credito.cliente.id_usuario,
        titulo="Pago de cuota realizado",
        mensaje=f"Se debitó S/ {req.monto} de tu cuenta para pagar la cuota {req.numero_cuota} del crédito {credito.numero_credito}.",
        tipo="RECORDATORIO_PAGO"
    )

    return operacion
