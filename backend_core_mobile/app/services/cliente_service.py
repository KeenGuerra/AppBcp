# cliente_service.py
from sqlalchemy.orm import Session
from app.repositories import cliente_repository, cuenta_repository, credito_repository
from app.core.exceptions import NotFoundException
from app.models.credito_model import Credito
from app.models.cronograma_model import CronogramaPago
from sqlalchemy import text
import uuid
import datetime

def get_cliente_by_usuario_id(db: Session, id_usuario: uuid.UUID):
    cli = cliente_repository.get_cliente_by_usuario_id(db, id_usuario)
    if not cli:
        raise NotFoundException("Cliente")
    _ = cli.negocios
    return cli

def get_ficha_cliente(db: Session, id_cliente: uuid.UUID):
    cli = cliente_repository.get_cliente_by_id(db, id_cliente)
    if not cli:
        raise NotFoundException("Cliente")
        
    cuentas = cuenta_repository.get_cuentas_by_cliente_id(db, id_cliente)
    creditos = credito_repository.get_creditos_by_cliente_id(db, id_cliente)
    
    resumen_cuentas = [{"id_cuenta": str(c.id_cuenta), "numero_cuenta": c.numero_cuenta, "saldo_disponible": float(c.saldo_disponible)} for c in cuentas]
    resumen_creditos = [{"id_credito": str(cr.id_credito), "numero_credito": cr.numero_credito, "saldo_capital": float(cr.saldo_capital), "estado": cr.estado} for cr in creditos]
    
    return {
        "cliente": cli,
        "resumen_cuentas": resumen_cuentas,
        "resumen_creditos": resumen_creditos
    }

def get_posicion_cliente(db: Session, id_cliente: uuid.UUID):
    cliente = cliente_repository.get_cliente_by_id(db, id_cliente)
    if not cliente:
        raise NotFoundException("Cliente")
        
    creditos = db.query(Credito).filter(
        Credito.id_cliente == id_cliente,
        Credito.estado != "CANCELADO"
    ).all()
    
    deuda_total_consolidada = sum(float(c.saldo_capital) for c in creditos)
    numero_cuentas_vigentes = len([c for c in creditos if c.estado == "VIGENTE"])
    
    credito_ids = [c.id_credito for c in creditos]
    cuotas = []
    if credito_ids:
        cuotas = db.query(CronogramaPago).filter(
            CronogramaPago.id_credito.in_(credito_ids)
        ).all()
        
    today = datetime.date.today()
    
    def parse_date(d_val):
        if not d_val:
            return None
        if isinstance(d_val, str):
            try:
                parts = [int(x) for x in d_val.split('T')[0].split('-')]
                return datetime.date(parts[0], parts[1], parts[2])
            except Exception:
                return None
        elif isinstance(d_val, datetime.datetime):
            return d_val.date()
        elif isinstance(d_val, datetime.date):
            return d_val
        return None

    def is_overdue(q):
        parsed = parse_date(q.fecha_pago)
        return parsed < today if parsed else False

    cuotas_mora = [q for q in cuotas if q.estado in ["VENCIDA", "PENDIENTE"] and is_overdue(q)]
    numero_cuentas_en_mora = len(set(q.id_credito for q in cuotas_mora))
    
    dias_de_mayor_mora_historica = 0
    for q in cuotas_mora:
        parsed = parse_date(q.fecha_pago)
        diff_days = (today - parsed).days if parsed else 0
        if diff_days > dias_de_mayor_mora_historica:
            dias_de_mayor_mora_historica = diff_days
            
    all_creditos = db.query(Credito).filter(Credito.id_cliente == id_cliente).all()
    all_credito_ids = [c.id_credito for c in all_creditos]
    
    fecha_del_ultimo_pago_registrado = None
    if all_credito_ids:
        last_payment_cuota = db.query(CronogramaPago).filter(
            CronogramaPago.id_credito.in_(all_credito_ids),
            CronogramaPago.monto_pagado > 0
        ).order_by(CronogramaPago.fecha_pago_real.desc()).first()
        
        if last_payment_cuota and last_payment_cuota.fecha_pago_real:
            fecha_del_ultimo_pago_registrado = last_payment_cuota.fecha_pago_real.isoformat()
            
    cuotas_al_dia = len([q for q in cuotas if q.estado == "PAGADA"])
    cuotas_en_mora = len([q for q in cuotas if q.estado == "VENCIDA" or (q.estado == "PENDIENTE" and is_overdue(q))])
    
    doc = cliente.documento if cliente else "0"
    last_char = doc[-1] if doc else "0"
    last_digit = int(last_char) if last_char.isdigit() else 0

    query_blacklisted = db.execute(
        text("SELECT motivo FROM listas_inhabilitados WHERE documento = :doc AND estado = 'ACTIVO'"),
        {"doc": doc}
    ).fetchone()
    
    esta_inhabilitado = bool(query_blacklisted)
    
    if esta_inhabilitado:
        calificacion_sbs = "PERDIDA"
    else:
        if last_digit in [0, 1, 2, 3]:
            calificacion_sbs = "NORMAL"
        elif last_digit in [4, 5]:
            calificacion_sbs = "CPP"
        elif last_digit in [6, 7]:
            calificacion_sbs = "DEFICIENTE"
        elif last_digit in [8]:
            calificacion_sbs = "DUDOSO"
        else:
            calificacion_sbs = "PERDIDA"
            
    return {
        "id_cliente": str(id_cliente),
        "deuda_total_consolidada": round(deuda_total_consolidada, 2),
        "numero_cuentas_vigentes": numero_cuentas_vigentes,
        "numero_cuentas_en_mora": numero_cuentas_en_mora,
        "dias_de_mayor_mora_historica": dias_de_mayor_mora_historica,
        "fecha_del_ultimo_pago_registrado": fecha_del_ultimo_pago_registrado,
        "cuotas_al_dia": cuotas_al_dia,
        "cuotas_en_mora": cuotas_en_mora,
        "calificacion_sbs": calificacion_sbs
    }

