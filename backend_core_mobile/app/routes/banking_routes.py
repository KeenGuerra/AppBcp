# banking_routes.py — BCP Banca Móvil operaciones (SQLAlchemy / Supabase)
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, require_roles
from app.models.usuario_model import Usuario
from app.models.banking_model import (
    BankingTransaccion, BankingTransferencia, BankingTransferenciaProgramada,
    BankingPagoServicio, BankingSimulacion, BankingSolicitudPrestamo,
    BankingPrestamo, BankingPagoPrestamo, BankingAhorro, BankingAbonoAhorro,
    BankingMetaAhorro, BankingAporteMeta, BankingDepositoPlazo, BankingRecarga,
    BankingGasto, BankingPresupuesto, BankingComparacionSim, BankingSimTasa,
    BankingComprobante, BankingRetiroProgramado, BankingReglaAhorro,
    BankingAhorroAutomaticoLog
)
from pydantic import BaseModel
from typing import List, Optional, Any
import uuid
from datetime import datetime, date
from decimal import Decimal

router = APIRouter(prefix="/banking", tags=["Banking Operations"])

# ─────────────────────────────────────────────
# Shared dependency
# ─────────────────────────────────────────────
def get_user(current_user: Usuario = Depends(require_roles(["CLIENTE", "ADMIN"]))):
    return current_user

def get_admin(current_user: Usuario = Depends(require_roles(["ADMIN"]))):
    return current_user

# ─────────────────────────────────────────────
# Serializers for frontend compatibility
# ─────────────────────────────────────────────
def serialize_transaccion(t: BankingTransaccion):
    fecha_str = t.created_at.isoformat() if isinstance(t.created_at, datetime) else str(t.created_at) if t.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(t.id),
        "user_id": str(t.id_usuario),
        "cuenta_id": t.cuenta_id,
        "tipo": t.tipo,
        "monto": float(t.monto),
        "descripcion": t.descripcion,
        "fecha": fecha_str,
        "estado": t.estado
    }

def serialize_transferencia(t: BankingTransferencia):
    fecha_str = t.created_at.isoformat() if isinstance(t.created_at, datetime) else str(t.created_at) if t.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(t.id),
        "user_id": str(t.id_usuario),
        "cuenta_origen": t.cuenta_origen,
        "cuenta_destino": t.cuenta_destino,
        "monto": float(t.monto),
        "tipo": t.tipo,
        "numero_operacion": t.numero_operacion,
        "estado": t.estado,
        "fecha_programada": t.fecha_programada.isoformat() if isinstance(t.fecha_programada, datetime) else str(t.fecha_programada) if t.fecha_programada else None,
        "fecha": fecha_str
    }

def serialize_transferencia_programada(t: BankingTransferenciaProgramada):
    fecha_str = t.created_at.isoformat() if isinstance(t.created_at, datetime) else str(t.created_at) if t.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(t.id),
        "user_id": str(t.id_usuario),
        "cuenta_origen": t.cuenta_origen,
        "cuenta_destino": t.cuenta_destino,
        "monto": float(t.monto),
        "fecha_programada": str(t.fecha_programada),
        "estado": t.estado,
        "fecha_creacion": fecha_str
    }

def serialize_pago_servicio(p: BankingPagoServicio):
    fecha_str = p.created_at.isoformat() if isinstance(p.created_at, datetime) else str(p.created_at) if p.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(p.id),
        "user_id": str(p.id_usuario),
        "servicio": p.servicio,
        "referencia": p.referencia,
        "monto": float(p.monto),
        "proveedor": p.proveedor,
        "operadora": p.operadora,
        "empresa": p.empresa,
        "numero_operacion": p.numero_operacion,
        "estado": p.estado,
        "fecha": fecha_str
    }

def serialize_simulacion(s: BankingSimulacion):
    fecha_str = s.created_at.isoformat() if isinstance(s.created_at, datetime) else str(s.created_at) if s.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(s.id),
        "user_id": str(s.id_usuario),
        "monto": float(s.monto),
        "plazo": s.plazo,
        "cuota_calculada": float(s.cuota_calculada),
        "tea": float(s.tea) if s.tea else 38.4,
        "tabla_json": s.tabla_json,
        "fecha": fecha_str
    }

def serialize_solicitud_prestamo(s: BankingSolicitudPrestamo):
    fecha_str = s.created_at.isoformat() if isinstance(s.created_at, datetime) else str(s.created_at) if s.created_at else datetime.utcnow().isoformat()
    user_doc = ""
    user_email = ""
    client_name = "Cliente BCP"
    if s.usuario:
        user_doc = s.usuario.documento
        user_email = s.usuario.correo
        session = getattr(s, '_session', None)
        if session:
            from app.models.cliente_model import Cliente
            cli = session.query(Cliente).filter_by(id_usuario=s.id_usuario).first()
            if cli:
                client_name = f"{cli.nombres} {cli.apellidos}"
    return {
        "id": str(s.id),
        "user_id": str(s.id_usuario),
        "monto": float(s.monto),
        "plazo": s.plazo,
        "cuota_calculada": float(s.cuota_calculada),
        "tea": float(s.tea) if s.tea else 38.4,
        "estado": s.estado,
        "fecha": fecha_str,
        "documento": user_doc,
        "email": user_email,
        "cliente_nombre": client_name
    }

def serialize_prestamo(p: BankingPrestamo):
    fecha_str = p.created_at.isoformat() if isinstance(p.created_at, datetime) else str(p.created_at) if p.created_at else datetime.utcnow().isoformat()
    user_doc = ""
    user_email = ""
    client_name = "Cliente BCP"
    if p.usuario:
        user_doc = p.usuario.documento
        user_email = p.usuario.correo
        session = getattr(p, '_session', None)
        if session:
            from app.models.cliente_model import Cliente
            cli = session.query(Cliente).filter_by(id_usuario=p.id_usuario).first()
            if cli:
                client_name = f"{cli.nombres} {cli.apellidos}"
    return {
        "id": str(p.id),
        "user_id": str(p.id_usuario),
        "monto_original": float(p.monto_original),
        "saldo_pendiente": float(p.saldo_pendiente),
        "cuota_mensual": float(p.cuota_mensual),
        "cuotas_pagadas": p.cuotas_pagadas,
        "cuotas_restantes": p.cuotas_restantes,
        "tea": float(p.tea) if p.tea else 38.4,
        "estado": p.estado,
        "fecha_cancelacion": p.fecha_cancelacion.isoformat() if isinstance(p.fecha_cancelacion, datetime) else str(p.fecha_cancelacion) if p.fecha_cancelacion else None,
        "fecha": fecha_str,
        "documento": user_doc,
        "email": user_email,
        "cliente_nombre": client_name
    }

def serialize_pago_prestamo(p: BankingPagoPrestamo):
    fecha_str = p.created_at.isoformat() if isinstance(p.created_at, datetime) else str(p.created_at) if p.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(p.id),
        "user_id": str(p.id_usuario),
        "prestamo_id": str(p.prestamo_id),
        "monto": float(p.monto),
        "tipo": p.tipo,
        "descuento_aplicado": float(p.descuento_aplicado) if p.descuento_aplicado else 0.0,
        "cuotas_restantes_post": p.cuotas_restantes_post,
        "fecha": fecha_str
    }

def serialize_ahorro(a: BankingAhorro):
    fecha_str = a.created_at.isoformat() if isinstance(a.created_at, datetime) else str(a.created_at) if a.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(a.id),
        "user_id": str(a.id_usuario),
        "nombre": a.nombre,
        "monto_meta": float(a.monto_meta),
        "monto_actual": float(a.monto_actual),
        "frecuencia": a.frecuencia,
        "activo": a.activo,
        "fecha_inicio": fecha_str,
        "estado": a.estado
    }

def serialize_abono_ahorro(a: BankingAbonoAhorro):
    fecha_str = a.created_at.isoformat() if isinstance(a.created_at, datetime) else str(a.created_at) if a.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(a.id),
        "user_id": str(a.id_usuario),
        "ahorro_id": str(a.ahorro_id),
        "monto": float(a.monto),
        "fecha": fecha_str
    }

def serialize_meta_ahorro(m: BankingMetaAhorro):
    fecha_str = m.created_at.isoformat() if isinstance(m.created_at, datetime) else str(m.created_at) if m.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(m.id),
        "user_id": str(m.id_usuario),
        "nombre": m.nombre,
        "categoria": m.categoria,
        "monto_objetivo": float(m.monto_objetivo),
        "monto_actual": float(m.monto_actual),
        "fecha_limite": str(m.fecha_limite),
        "estado": m.estado,
        "fecha_creacion": fecha_str
    }

def serialize_aporte_meta(a: BankingAporteMeta):
    fecha_str = a.created_at.isoformat() if isinstance(a.created_at, datetime) else str(a.created_at) if a.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(a.id),
        "user_id": str(a.id_usuario),
        "meta_id": str(a.meta_id),
        "monto": float(a.monto),
        "fecha": fecha_str
    }

def serialize_deposito_plazo(d: BankingDepositoPlazo):
    fecha_str = d.created_at.isoformat() if isinstance(d.created_at, datetime) else str(d.created_at) if d.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(d.id),
        "user_id": str(d.id_usuario),
        "cuenta_origen": d.cuenta_origen,
        "monto": float(d.monto),
        "plazo_dias": d.plazo_dias,
        "tasa": float(d.tasa),
        "interes_estimado": float(d.interes_estimado),
        "monto_final": float(d.monto_final),
        "fecha_inicio": d.fecha_inicio.isoformat() if isinstance(d.fecha_inicio, datetime) else str(d.fecha_inicio) if d.fecha_inicio else None,
        "fecha_vencimiento": d.fecha_vencimiento.isoformat() if isinstance(d.fecha_vencimiento, datetime) else str(d.fecha_vencimiento) if d.fecha_vencimiento else None,
        "estado": d.estado,
        "penalidad": float(d.penalidad) if d.penalidad else 0.0,
        "monto_retiro": float(d.monto_retiro) if d.monto_retiro else None,
        "fecha_retiro": d.fecha_retiro.isoformat() if isinstance(d.fecha_retiro, datetime) else str(d.fecha_retiro) if d.fecha_retiro else None
    }

def serialize_recarga(r: BankingRecarga):
    fecha_str = r.created_at.isoformat() if isinstance(r.created_at, datetime) else str(r.created_at) if r.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(r.id),
        "user_id": str(r.id_usuario),
        "celular_destino": r.celular_destino,
        "celular_enmascarado": r.celular_enmascarado,
        "operadora": r.operadora,
        "monto": float(r.monto),
        "cuenta_origen": r.cuenta_origen,
        "numero_operacion": r.numero_operacion,
        "estado": r.estado,
        "fecha": fecha_str
    }

def serialize_gasto(g: BankingGasto):
    fecha_str = g.created_at.isoformat() if isinstance(g.created_at, datetime) else str(g.created_at) if g.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(g.id),
        "user_id": str(g.id_usuario),
        "descripcion": g.descripcion,
        "monto": float(g.monto),
        "categoria": g.categoria,
        "fecha": fecha_str
    }

def serialize_presupuesto(p: BankingPresupuesto):
    return {
        "id": str(p.id),
        "user_id": str(p.id_usuario),
        "categoria": p.categoria,
        "limite": float(p.limite),
        "mes": p.mes,
        "anio": p.anio
    }

def serialize_comparacion_sim(c: BankingComparacionSim):
    fecha_str = c.created_at.isoformat() if isinstance(c.created_at, datetime) else str(c.created_at) if c.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(c.id),
        "user_id": str(c.id_usuario),
        "sim1_json": c.sim1_json,
        "sim2_json": c.sim2_json,
        "sim3_json": c.sim3_json,
        "fecha": fecha_str
    }

def serialize_sim_tasa(s: BankingSimTasa):
    fecha_str = s.created_at.isoformat() if isinstance(s.created_at, datetime) else str(s.created_at) if s.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(s.id),
        "user_id": str(s.id_usuario),
        "monto": float(s.monto),
        "plazo": s.plazo,
        "cuota_tem2": float(s.cuota_tem2) if s.cuota_tem2 else None,
        "cuota_tem3": float(s.cuota_tem3) if s.cuota_tem3 else None,
        "cuota_tem4": float(s.cuota_tem4) if s.cuota_tem4 else None,
        "ahorro_vs_max": float(s.ahorro_vs_max) if s.ahorro_vs_max else None,
        "fecha": fecha_str
    }

def serialize_comprobante(c: BankingComprobante):
    fecha_str = c.created_at.isoformat() if isinstance(c.created_at, datetime) else str(c.created_at) if c.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(c.id),
        "user_id": str(c.id_usuario),
        "tipo": c.tipo,
        "monto": float(c.monto),
        "referencia_uuid": str(c.referencia_uuid) if c.referencia_uuid else None,
        "datos_json": c.datos_json,
        "fecha": fecha_str
    }

def serialize_retiro_programado(r: BankingRetiroProgramado):
    fecha_str = r.created_at.isoformat() if isinstance(r.created_at, datetime) else str(r.created_at) if r.created_at else datetime.utcnow().isoformat()
    return {
        "id": str(r.id),
        "user_id": str(r.id_usuario),
        "cuenta_id": r.cuenta_id,
        "monto": float(r.monto),
        "fecha_programada": str(r.fecha_programada),
        "estado": r.estado,
        "fecha_creacion": fecha_str
    }

def serialize_regla_ahorro(r: BankingReglaAhorro):
    fecha_str = r.fecha_creacion.isoformat() if isinstance(r.fecha_creacion, datetime) else str(r.fecha_creacion) if r.fecha_creacion else datetime.utcnow().isoformat()
    return {
        "id": str(r.id),
        "user_id": str(r.id_usuario),
        "cuenta_origen": r.cuenta_origen,
        "cuenta_destino": r.cuenta_destino,
        "porcentaje": float(r.porcentaje),
        "activa": r.activa,
        "fecha_creacion": fecha_str
    }

def serialize_ahorro_automatico_log(l: BankingAhorroAutomaticoLog):
    fecha_str = l.fecha.isoformat() if isinstance(l.fecha, datetime) else str(l.fecha) if l.fecha else datetime.utcnow().isoformat()
    return {
        "id": str(l.id),
        "user_id": str(l.id_usuario),
        "regla_id": str(l.regla_id),
        "monto": float(l.monto),
        "fecha": fecha_str
    }


# ═══════════════════════════════════════════════════════════
# ADMIN: monitoring endpoints
# ═══════════════════════════════════════════════════════════

@router.get("/admin/transacciones")
def admin_transacciones(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    txs = db.query(BankingTransaccion).order_by(BankingTransaccion.created_at.desc()).limit(limit).all()
    return [serialize_transaccion(t) for t in txs]

@router.get("/admin/transferencias")
def admin_transferencias(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    tfs = db.query(BankingTransferencia).order_by(BankingTransferencia.created_at.desc()).limit(limit).all()
    return [serialize_transferencia(t) for t in tfs]

@router.get("/admin/pagos-servicios")
def admin_pagos_servicios(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    pagos = db.query(BankingPagoServicio).order_by(BankingPagoServicio.created_at.desc()).limit(limit).all()
    return [serialize_pago_servicio(p) for p in pagos]

@router.get("/admin/prestamos")
def admin_prestamos(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    pr = db.query(BankingPrestamo).order_by(BankingPrestamo.created_at.desc()).limit(limit).all()
    return [serialize_prestamo(p) for p in pr]

@router.get("/admin/solicitudes-prestamo")
def admin_solicitudes(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    sol = db.query(BankingSolicitudPrestamo).order_by(BankingSolicitudPrestamo.created_at.desc()).limit(limit).all()
    return [serialize_solicitud_prestamo(s) for s in sol]

@router.get("/admin/recargas")
def admin_recargas(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    rec = db.query(BankingRecarga).order_by(BankingRecarga.created_at.desc()).limit(limit).all()
    return [serialize_recarga(r) for r in rec]

@router.get("/admin/gastos")
def admin_gastos(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    gst = db.query(BankingGasto).order_by(BankingGasto.created_at.desc()).limit(limit).all()
    return [serialize_gasto(g) for g in gst]

@router.get("/admin/ahorros")
def admin_ahorros(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    ah = db.query(BankingAhorro).order_by(BankingAhorro.created_at.desc()).limit(limit).all()
    return [serialize_ahorro(a) for a in ah]

@router.get("/admin/metas-ahorro")
def admin_metas(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    met = db.query(BankingMetaAhorro).order_by(BankingMetaAhorro.created_at.desc()).limit(limit).all()
    return [serialize_meta_ahorro(m) for m in met]

@router.get("/admin/comprobantes")
def admin_comprobantes(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    cmp = db.query(BankingComprobante).order_by(BankingComprobante.created_at.desc()).limit(limit).all()
    return [serialize_comprobante(c) for c in cmp]

@router.get("/admin/depositos-plazo")
def admin_depositos_plazo(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    dep = db.query(BankingDepositoPlazo).order_by(BankingDepositoPlazo.created_at.desc()).limit(limit).all()
    return [serialize_deposito_plazo(d) for d in dep]

@router.get("/admin/simulaciones")
def admin_simulaciones(limit: int = 100, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    sim = db.query(BankingSimulacion).order_by(BankingSimulacion.created_at.desc()).limit(limit).all()
    return [serialize_simulacion(s) for s in sim]

@router.get("/admin/stats")
def admin_stats(current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    """Global stats for the admin dashboard."""
    total_transacciones = db.query(BankingTransaccion).count()
    total_transferencias = db.query(BankingTransferencia).count()
    total_pagos = db.query(BankingPagoServicio).count()
    total_recargas = db.query(BankingRecarga).count()
    total_prestamos = db.query(BankingPrestamo).count()
    total_ahorros = db.query(BankingAhorro).count()

    # Sums (computed in python for emulator compatibility)
    monto_transacciones = sum(float(t.monto or 0) for t in db.query(BankingTransaccion).all())
    monto_transferencias = sum(float(t.monto or 0) for t in db.query(BankingTransferencia).all())
    monto_pagos = sum(float(t.monto or 0) for t in db.query(BankingPagoServicio).all())

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
        }
    }


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 1 & 2 — Depósito / Retiro simple
# ═══════════════════════════════════════════════════════════

class TransaccionCreate(BaseModel):
    cuenta_id: str
    tipo: str          # DEPOSITO | RETIRO | RETIRO_PLAZO
    monto: float
    descripcion: Optional[str] = None

@router.post("/transacciones")
def crear_transaccion(req: TransaccionCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    if req.monto <= 0:
        raise HTTPException(status_code=400, detail="El monto debe ser mayor a 0")
    if req.tipo == "DEPOSITO" and req.monto > 10000:
        raise HTTPException(status_code=400, detail="El monto máximo de depósito es S/ 10,000")
    
    t = BankingTransaccion(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        cuenta_id=req.cuenta_id,
        tipo=req.tipo,
        monto=Decimal(str(req.monto)),
        descripcion=req.descripcion or req.tipo,
        estado="COMPLETADA",
        created_at=datetime.utcnow()
    )
    db.add(t)
    
    # Auto-generate comprobante
    comp = BankingComprobante(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        tipo=req.tipo,
        monto=Decimal(str(req.monto)),
        referencia_uuid=t.id,
        datos_json={
            "id": str(t.id),
            "cuenta_id": t.cuenta_id,
            "tipo": t.tipo,
            "monto": float(t.monto),
            "descripcion": t.descripcion,
            "fecha": t.created_at.isoformat() if isinstance(t.created_at, datetime) else str(t.created_at),
            "estado": t.estado
        },
        created_at=datetime.utcnow()
    )
    db.add(comp)
    db.commit()
    db.refresh(t)
    return serialize_transaccion(t)

@router.get("/transacciones")
def get_transacciones(
    user_id: Optional[str] = None,
    tipo: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    current_user: Usuario = Depends(get_user),
    db: Session = Depends(get_db)
):
    uid = uuid.UUID(user_id) if user_id else current_user.id_usuario
    q = db.query(BankingTransaccion).filter(BankingTransaccion.id_usuario == uid)
    if tipo:
        q = q.filter(BankingTransaccion.tipo == tipo)
    q = q.order_by(BankingTransaccion.created_at.desc())
    txs = q.offset(offset).limit(limit).all()
    return [serialize_transaccion(t) for t in txs]

@router.delete("/transacciones/{id_transaccion}")
def delete_transaccion(id_transaccion: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    tx_uuid = uuid.UUID(id_transaccion)
    item = db.query(BankingTransaccion).filter(
        BankingTransaccion.id == tx_uuid,
        BankingTransaccion.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Transacción no encontrada")
    
    created = item.created_at
    if isinstance(created, str):
        created = datetime.fromisoformat(created.replace('Z', '+00:00')).replace(tzinfo=None)
    elif created.tzinfo is not None:
        created = created.replace(tzinfo=None)

    diff = (datetime.utcnow() - created).total_seconds()
    if diff > 86400:
        raise HTTPException(status_code=400, detail="Solo se pueden eliminar depósitos con menos de 24 horas")
    if item.tipo != "DEPOSITO":
        raise HTTPException(status_code=400, detail="Solo se pueden eliminar transacciones de tipo DEPOSITO")
    
    db.delete(item)
    db.commit()
    return {"message": "Transacción eliminada"}


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 3 & 17 & 18 & 19 — Transferencias
# ═══════════════════════════════════════════════════════════

class TransferenciaCreate(BaseModel):
    cuenta_origen: str
    cuenta_destino: str
    monto: float
    tipo: str = "PROPIA"     # PROPIA | TERCERO
    fecha_programada: Optional[str] = None
    estado: str = "COMPLETADA"

@router.post("/transferencias")
def crear_transferencia(req: TransferenciaCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    if req.monto <= 0:
        raise HTTPException(status_code=400, detail="El monto debe ser mayor a 0")
    
    t = BankingTransferencia(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        cuenta_origen=req.cuenta_origen,
        cuenta_destino=req.cuenta_destino,
        monto=Decimal(str(req.monto)),
        tipo=req.tipo,
        estado=req.estado,
        numero_operacion=str(uuid.uuid4())[:8].upper(),
        created_at=datetime.utcnow()
    )
    db.add(t)
    
    comp = BankingComprobante(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        tipo="TRANSFERENCIA",
        monto=Decimal(str(req.monto)),
        referencia_uuid=t.id,
        datos_json={
            "id": str(t.id),
            "cuenta_origen": t.cuenta_origen,
            "cuenta_destino": t.cuenta_destino,
            "monto": float(t.monto),
            "tipo": t.tipo,
            "numero_operacion": t.numero_operacion,
            "estado": t.estado,
            "fecha": t.created_at.isoformat() if isinstance(t.created_at, datetime) else str(t.created_at)
        },
        created_at=datetime.utcnow()
    )
    db.add(comp)
    db.commit()
    db.refresh(t)
    return serialize_transferencia(t)

@router.get("/transferencias")
def get_transferencias(
    cuenta_id: Optional[str] = None,
    tipo_filtro: Optional[str] = None,
    limit: int = 50,
    current_user: Usuario = Depends(get_user),
    db: Session = Depends(get_db)
):
    q = db.query(BankingTransferencia).filter(BankingTransferencia.id_usuario == current_user.id_usuario)
    if cuenta_id:
        from sqlalchemy import or_
        q = q.filter(or_(BankingTransferencia.cuenta_origen == cuenta_id, BankingTransferencia.cuenta_destino == cuenta_id))
    if tipo_filtro == "ENVIADAS" and cuenta_id:
        q = q.filter(BankingTransferencia.cuenta_origen == cuenta_id)
    elif tipo_filtro == "RECIBIDAS" and cuenta_id:
        q = q.filter(BankingTransferencia.cuenta_destino == cuenta_id)
    
    q = q.order_by(BankingTransferencia.created_at.desc())
    tfs = q.limit(limit).all()
    return [serialize_transferencia(t) for t in tfs]


# TRANSFERENCIAS PROGRAMADAS (casuística 19)
class TransferenciaProgramadaCreate(BaseModel):
    cuenta_origen: str
    cuenta_destino: str
    monto: float
    fecha_programada: str

@router.post("/transferencias-programadas")
def crear_transferencia_programada(req: TransferenciaProgramadaCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    try:
        f_prog = date.fromisoformat(req.fecha_programada)
    except Exception:
        raise HTTPException(status_code=400, detail="Fecha programada inválida, debe ser YYYY-MM-DD")
        
    t = BankingTransferenciaProgramada(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        cuenta_origen=req.cuenta_origen,
        cuenta_destino=req.cuenta_destino,
        monto=Decimal(str(req.monto)),
        fecha_programada=f_prog,
        estado="PENDIENTE",
        created_at=datetime.utcnow()
    )
    db.add(t)
    db.commit()
    db.refresh(t)
    return serialize_transferencia_programada(t)

@router.get("/transferencias-programadas")
def get_transferencias_programadas(current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    tfs = db.query(BankingTransferenciaProgramada).filter(
        BankingTransferenciaProgramada.id_usuario == current_user.id_usuario
    ).order_by(BankingTransferenciaProgramada.created_at.desc()).all()
    return [serialize_transferencia_programada(t) for t in tfs]

@router.patch("/transferencias-programadas/{id}")
def update_transferencia_programada(id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    t_uuid = uuid.UUID(id)
    item = db.query(BankingTransferenciaProgramada).filter(
        BankingTransferenciaProgramada.id == t_uuid,
        BankingTransferenciaProgramada.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Transferencia programada no encontrada")
    item.estado = "CANCELADA"
    db.commit()
    db.refresh(item)
    return serialize_transferencia_programada(item)


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 4,5,6,20,29 — Pagos de Servicios
# ═══════════════════════════════════════════════════════════

class PagoServicioCreate(BaseModel):
    servicio: str      # LUZ | AGUA | INTERNET | TELEFONO | GAS
    referencia: str
    monto: float
    proveedor: Optional[str] = None
    operadora: Optional[str] = None
    empresa: Optional[str] = None

@router.post("/pagos-servicios")
def crear_pago_servicio(req: PagoServicioCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    if req.monto <= 0:
        raise HTTPException(status_code=400, detail="El monto debe ser mayor a 0")
    
    p = BankingPagoServicio(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        servicio=req.servicio,
        referencia=req.referencia,
        monto=Decimal(str(req.monto)),
        proveedor=req.proveedor,
        operadora=req.operadora,
        empresa=req.empresa,
        estado="PAGADO",
        numero_operacion=str(uuid.uuid4())[:8].upper(),
        created_at=datetime.utcnow()
    )
    db.add(p)
    
    comp = BankingComprobante(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        tipo=f"PAGO_{req.servicio}",
        monto=Decimal(str(req.monto)),
        referencia_uuid=p.id,
        datos_json={
            "id": str(p.id),
            "servicio": p.servicio,
            "referencia": p.referencia,
            "monto": float(p.monto),
            "proveedor": p.proveedor,
            "operadora": p.operadora,
            "empresa": p.empresa,
            "estado": p.estado,
            "numero_operacion": p.numero_operacion,
            "fecha": p.created_at.isoformat() if isinstance(p.created_at, datetime) else str(p.created_at)
        },
        created_at=datetime.utcnow()
    )
    db.add(comp)
    db.commit()
    db.refresh(p)
    return serialize_pago_servicio(p)

@router.get("/pagos-servicios")
def get_pagos_servicios(
    servicio: Optional[str] = None,
    proveedor: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
    current_user: Usuario = Depends(get_user),
    db: Session = Depends(get_db)
):
    q = db.query(BankingPagoServicio).filter(BankingPagoServicio.id_usuario == current_user.id_usuario)
    if servicio and servicio != "TODOS":
        q = q.filter(BankingPagoServicio.servicio == servicio)
    if proveedor:
        from sqlalchemy import or_
        q = q.filter(or_(BankingPagoServicio.proveedor == proveedor, BankingPagoServicio.operadora == proveedor, BankingPagoServicio.empresa == proveedor))
    
    q = q.order_by(BankingPagoServicio.created_at.desc())
    pagos = q.offset(offset).limit(limit).all()
    return [serialize_pago_servicio(p) for p in pagos]

@router.patch("/pagos-servicios/{id}")
def update_pago_servicio(id: str, monto_corregido: float, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    p_uuid = uuid.UUID(id)
    item = db.query(BankingPagoServicio).filter(
        BankingPagoServicio.id == p_uuid,
        BankingPagoServicio.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Pago de servicio no encontrado")
    item.monto = Decimal(str(monto_corregido))
    item.estado = "CORREGIDO"
    db.commit()
    db.refresh(item)
    return serialize_pago_servicio(item)

@router.delete("/pagos-servicios/{id}")
def delete_pago_servicio(id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    p_uuid = uuid.UUID(id)
    item = db.query(BankingPagoServicio).filter(
        BankingPagoServicio.id == p_uuid,
        BankingPagoServicio.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Pago de servicio no encontrado")
    db.delete(item)
    db.commit()
    return {"message": "Registro eliminado"}


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 7 & 8 — Simulaciones de cuota y amortización
# ═══════════════════════════════════════════════════════════

class SimulacionCreate(BaseModel):
    monto: float
    plazo: int
    cuota_calculada: float
    tea: float = 38.4
    tabla_json: Optional[Any] = None

@router.post("/simulaciones")
def crear_simulacion(req: SimulacionCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    s = BankingSimulacion(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        monto=Decimal(str(req.monto)),
        plazo=req.plazo,
        cuota_calculada=Decimal(str(req.cuota_calculada)),
        tea=Decimal(str(req.tea)),
        tabla_json=req.tabla_json,
        created_at=datetime.utcnow()
    )
    db.add(s)
    db.commit()
    db.refresh(s)
    return serialize_simulacion(s)

@router.get("/simulaciones")
def get_simulaciones(limit: int = 5, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    sims = db.query(BankingSimulacion).filter(
        BankingSimulacion.id_usuario == current_user.id_usuario
    ).order_by(BankingSimulacion.created_at.desc()).limit(limit).all()
    return [serialize_simulacion(s) for s in sims]


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 9 — Solicitud de préstamo
# ═══════════════════════════════════════════════════════════

class SolicitudPrestamoCreate(BaseModel):
    monto: float
    plazo: int     # months: 6|12|18|24|36
    cuota_calculada: float
    tea: float = 38.4

@router.post("/solicitudes-prestamo")
def crear_solicitud_prestamo(req: SolicitudPrestamoCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    if req.monto < 500 or req.monto > 50000:
        raise HTTPException(status_code=400, detail="El monto debe estar entre S/ 500 y S/ 50,000")
    s = BankingSolicitudPrestamo(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        monto=Decimal(str(req.monto)),
        plazo=req.plazo,
        cuota_calculada=Decimal(str(req.cuota_calculada)),
        tea=Decimal(str(req.tea)),
        estado="PENDIENTE",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db.add(s)
    db.commit()
    db.refresh(s)
    return serialize_solicitud_prestamo(s)

@router.get("/solicitudes-prestamo")
def get_solicitudes_prestamo(current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    sol = db.query(BankingSolicitudPrestamo).filter(
        BankingSolicitudPrestamo.id_usuario == current_user.id_usuario
    ).order_by(BankingSolicitudPrestamo.created_at.desc()).all()
    return [serialize_solicitud_prestamo(s) for s in sol]

@router.patch("/solicitudes-prestamo/{id}/estado")
def update_estado_solicitud(id: str, estado: str, current_user: Usuario = Depends(get_admin), db: Session = Depends(get_db)):
    s_uuid = uuid.UUID(id)
    item = db.query(BankingSolicitudPrestamo).filter(BankingSolicitudPrestamo.id == s_uuid).first()
    if not item:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    
    new_estado = estado.upper()
    item.estado = new_estado
    item.updated_at = datetime.utcnow()
    
    # If approved or disbursed, trigger full disbursement flow
    if new_estado in ["APROBADO", "DESEMBOLSADO"]:
        item.estado = "DESEMBOLSADO"
        
        # Create corresponding BankingPrestamo
        p = BankingPrestamo(
            id=uuid.uuid4(),
            id_usuario=item.id_usuario,
            monto_original=item.monto,
            saldo_pendiente=item.monto,
            cuota_mensual=item.cuota_calculada,
            cuotas_pagadas=0,
            cuotas_restantes=item.plazo,
            tea=item.tea,
            estado="ACTIVO",
            created_at=datetime.utcnow()
        )
        db.add(p)
        
        # Increment savings account balance for the client
        from app.models.cliente_model import Cliente
        from app.models.cuenta_model import CuentaAhorro
        
        cliente = db.query(Cliente).filter(Cliente.id_usuario == item.id_usuario).first()
        if cliente:
            cuenta = db.query(CuentaAhorro).filter(CuentaAhorro.id_cliente == cliente.id_cliente).first()
            if cuenta:
                cuenta.saldo_disponible += item.monto
                cuenta.saldo_contable += item.monto
                
                # Log deposit transaction
                from app.models.banking_model import BankingTransaccion
                t = BankingTransaccion(
                    id=uuid.uuid4(),
                    id_usuario=item.id_usuario,
                    cuenta_id=str(cuenta.id_cuenta),
                    tipo="DEPOSITO",
                    monto=item.monto,
                    descripcion="Desembolso Préstamo Bancario BCP",
                    estado="COMPLETADA",
                    created_at=datetime.utcnow()
                )
                db.add(t)
        
    db.commit()
    db.refresh(item)
    return serialize_solicitud_prestamo(item)


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 10, 11, 12, 32 — Préstamos activos y pagos
# ═══════════════════════════════════════════════════════════

class PagoPrestamoCreate(BaseModel):
    prestamo_id: str
    monto: float
    tipo: str = "CUOTA"    # CUOTA | ADELANTO | CANCELACION_ANTICIPADA

@router.get("/prestamos")
def get_prestamos(estado: Optional[str] = None, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    q = db.query(BankingPrestamo).filter(BankingPrestamo.id_usuario == current_user.id_usuario)
    if estado:
        q = q.filter(BankingPrestamo.estado == estado)
    pr = q.order_by(BankingPrestamo.created_at.desc()).all()
    return [serialize_prestamo(p) for p in pr]

@router.post("/pagos-prestamo")
def crear_pago_prestamo(req: PagoPrestamoCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    p_uuid = uuid.UUID(req.prestamo_id)
    prestamo = db.query(BankingPrestamo).filter(BankingPrestamo.id == p_uuid).first()
    if not prestamo:
        # Create a demo prestamo on the fly
        prestamo = BankingPrestamo(
            id=p_uuid,
            id_usuario=current_user.id_usuario,
            monto_original=Decimal("10000.00"),
            saldo_pendiente=Decimal("10000.00"),
            cuota_mensual=Decimal("490.50"),
            cuotas_pagadas=0,
            cuotas_restantes=24,
            tea=Decimal("38.4"),
            estado="ACTIVO",
            created_at=datetime.utcnow()
        )
        db.add(prestamo)
        db.commit()
        db.refresh(prestamo)

    descuento = 0.0
    monto_dec = Decimal(str(req.monto))
    if req.tipo == "CANCELACION_ANTICIPADA":
        descuento = float(prestamo.saldo_pendiente) * 0.05
        prestamo.saldo_pendiente = max(Decimal("0.00"), prestamo.saldo_pendiente - monto_dec + Decimal(str(descuento)))
        prestamo.estado = "CANCELADO"
        prestamo.fecha_cancelacion = datetime.utcnow()
    elif req.tipo == "ADELANTO":
        cuotas_cubiertas = int(req.monto / float(prestamo.cuota_mensual))
        prestamo.saldo_pendiente = max(Decimal("0.00"), prestamo.saldo_pendiente - monto_dec)
        prestamo.cuotas_restantes = max(0, prestamo.cuotas_restantes - cuotas_cubiertas)
    else:
        prestamo.saldo_pendiente = max(Decimal("0.00"), prestamo.saldo_pendiente - monto_dec)
        prestamo.cuotas_pagadas = (prestamo.cuotas_pagadas or 0) + 1
        prestamo.cuotas_restantes = max(0, (prestamo.cuotas_restantes or 1) - 1)
        if prestamo.saldo_pendiente <= 0:
            prestamo.estado = "CANCELADO"
            prestamo.fecha_cancelacion = datetime.utcnow()

    pago = BankingPagoPrestamo(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        prestamo_id=p_uuid,
        monto=monto_dec,
        tipo=req.tipo,
        descuento_aplicado=Decimal(str(descuento)),
        cuotas_restantes_post=prestamo.cuotas_restantes,
        created_at=datetime.utcnow()
    )
    db.add(pago)
    db.commit()
    db.refresh(pago)
    db.refresh(prestamo)
    
    res = serialize_pago_prestamo(pago)
    res["nuevo_saldo"] = float(prestamo.saldo_pendiente)
    return res

@router.get("/pagos-prestamo")
def get_pagos_prestamo(prestamo_id: Optional[str] = None, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    q = db.query(BankingPagoPrestamo).filter(BankingPagoPrestamo.id_usuario == current_user.id_usuario)
    if prestamo_id:
        p_uuid = uuid.UUID(prestamo_id)
        q = q.filter(BankingPagoPrestamo.prestamo_id == p_uuid)
    pagos = q.order_by(BankingPagoPrestamo.created_at.desc()).all()
    return [serialize_pago_prestamo(p) for p in pagos]


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 13, 14 — Ahorros programados
# ═══════════════════════════════════════════════════════════

class AhorroCreate(BaseModel):
    nombre: str
    monto_meta: float
    monto_inicial: float = 0.0
    frecuencia: str   # Diario | Semanal | Mensual

@router.post("/ahorros")
def crear_ahorro(req: AhorroCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    a = BankingAhorro(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        nombre=req.nombre,
        monto_meta=Decimal(str(req.monto_meta)),
        monto_actual=Decimal(str(req.monto_inicial)),
        frecuencia=req.frecuencia,
        activo=True,
        estado="ACTIVO",
        created_at=datetime.utcnow()
    )
    db.add(a)
    db.commit()
    db.refresh(a)
    return serialize_ahorro(a)

@router.get("/ahorros")
def get_ahorros(current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    ah = db.query(BankingAhorro).filter(
        BankingAhorro.id_usuario == current_user.id_usuario
    ).order_by(BankingAhorro.created_at.desc()).all()
    return [serialize_ahorro(a) for a in ah]

@router.patch("/ahorros/{id}")
def update_ahorro(id: str, monto_abono: float, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    a_uuid = uuid.UUID(id)
    ahorro = db.query(BankingAhorro).filter(
        BankingAhorro.id == a_uuid,
        BankingAhorro.id_usuario == current_user.id_usuario
    ).first()
    if not ahorro:
        raise HTTPException(status_code=404, detail="Ahorro no encontrado")
        
    ahorro.monto_actual = (ahorro.monto_actual or 0) + Decimal(str(monto_abono))
    if ahorro.monto_actual >= ahorro.monto_meta:
        ahorro.activo = False
        ahorro.estado = "COMPLETADO"
        
    abono = BankingAbonoAhorro(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        ahorro_id=a_uuid,
        monto=Decimal(str(monto_abono)),
        created_at=datetime.utcnow()
    )
    db.add(abono)
    db.commit()
    db.refresh(ahorro)
    
    return {**serialize_ahorro(ahorro), "meta_alcanzada": not ahorro.activo}

@router.delete("/ahorros/{id}")
def delete_ahorro(id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    a_uuid = uuid.UUID(id)
    item = db.query(BankingAhorro).filter(
        BankingAhorro.id == a_uuid,
        BankingAhorro.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Ahorro no encontrado")
    db.delete(item)
    db.commit()
    return {"message": "Ahorro eliminado"}

@router.get("/abonos-ahorro")
def get_abonos_ahorro(ahorro_id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    a_uuid = uuid.UUID(ahorro_id)
    abonos = db.query(BankingAbonoAhorro).filter(
        BankingAbonoAhorro.ahorro_id == a_uuid,
        BankingAbonoAhorro.id_usuario == current_user.id_usuario
    ).order_by(BankingAbonoAhorro.created_at.desc()).all()
    return [serialize_abono_ahorro(a) for a in abonos]


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 15, 16 — Depósito a plazo fijo
# ═══════════════════════════════════════════════════════════

TASAS_PLAZO = {30: 3.0, 60: 4.0, 90: 5.0, 180: 6.5, 360: 8.0}

class DepositoPlazoCreate(BaseModel):
    cuenta_origen: str
    monto: float
    plazo_dias: int   # 30|60|90|180|360

@router.post("/depositos-plazo")
def crear_deposito_plazo(req: DepositoPlazoCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    if req.monto < 500:
        raise HTTPException(status_code=400, detail="El monto mínimo es S/ 500")
    tasa = TASAS_PLAZO.get(req.plazo_dias)
    if not tasa:
        raise HTTPException(status_code=400, detail="Plazo no válido")
        
    interes = req.monto * (tasa / 100.0) * (req.plazo_dias / 365.0)
    monto_final = req.monto + interes
    
    from datetime import timedelta
    fecha_ini = datetime.utcnow()
    fecha_venc = fecha_ini + timedelta(days=req.plazo_dias)
    
    d = BankingDepositoPlazo(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        cuenta_origen=req.cuenta_origen,
        monto=Decimal(str(req.monto)),
        plazo_dias=req.plazo_dias,
        tasa=Decimal(str(tasa)),
        interes_estimado=Decimal(str(round(interes, 2))),
        monto_final=Decimal(str(round(monto_final, 2))),
        fecha_inicio=fecha_ini,
        fecha_vencimiento=fecha_venc,
        estado="ACTIVO",
        created_at=datetime.utcnow()
    )
    db.add(d)
    db.commit()
    db.refresh(d)
    return serialize_deposito_plazo(d)

@router.get("/depositos-plazo")
def get_depositos_plazo(estado: Optional[str] = None, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    q = db.query(BankingDepositoPlazo).filter(BankingDepositoPlazo.id_usuario == current_user.id_usuario)
    if estado:
        q = q.filter(BankingDepositoPlazo.estado == estado)
    deps = q.order_by(BankingDepositoPlazo.created_at.desc()).all()
    return [serialize_deposito_plazo(d) for d in deps]

@router.patch("/depositos-plazo/{id}/retirar")
def retirar_deposito_plazo(id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    d_uuid = uuid.UUID(id)
    item = db.query(BankingDepositoPlazo).filter(
        BankingDepositoPlazo.id == d_uuid,
        BankingDepositoPlazo.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Depósito a plazo no encontrado")
        
    fecha_venc = item.fecha_vencimiento
    if isinstance(fecha_venc, str):
        fecha_venc = datetime.fromisoformat(fecha_venc.replace('Z', '+00:00')).replace(tzinfo=None)
    elif fecha_venc.tzinfo is not None:
        fecha_venc = fecha_venc.replace(tzinfo=None)

    penalidad = 0.0
    if datetime.utcnow() < fecha_venc:
        penalidad = float(item.interes_estimado) * 0.5
        
    monto_retiro = float(item.monto_final) - penalidad
    item.estado = "RETIRADO"
    item.fecha_retiro = datetime.utcnow()
    item.penalidad = Decimal(str(round(penalidad, 2)))
    item.monto_retiro = Decimal(str(round(monto_retiro, 2)))
    
    db.commit()
    db.refresh(item)
    return serialize_deposito_plazo(item)


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 21, 22 — Metas de ahorro
# ═══════════════════════════════════════════════════════════

class MetaAhorroCreate(BaseModel):
    nombre: str
    categoria: str    # Viaje | Educación | Emergencia | Otro
    monto_objetivo: float
    fecha_limite: str

@router.post("/metas-ahorro")
def crear_meta(req: MetaAhorroCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    try:
        f_lim = date.fromisoformat(req.fecha_limite)
    except Exception:
        raise HTTPException(status_code=400, detail="Fecha límite inválida, debe ser YYYY-MM-DD")
        
    m = BankingMetaAhorro(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        nombre=req.nombre,
        categoria=req.categoria,
        monto_objetivo=Decimal(str(req.monto_objetivo)),
        monto_actual=Decimal("0.00"),
        fecha_limite=f_lim,
        estado="ACTIVA",
        created_at=datetime.utcnow()
    )
    db.add(m)
    db.commit()
    db.refresh(m)
    return serialize_meta_ahorro(m)

@router.get("/metas-ahorro")
def get_metas(estado: Optional[str] = None, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    q = db.query(BankingMetaAhorro).filter(BankingMetaAhorro.id_usuario == current_user.id_usuario)
    if estado:
        q = q.filter(BankingMetaAhorro.estado == estado)
    metas = q.order_by(BankingMetaAhorro.created_at.desc()).all()
    return [serialize_meta_ahorro(m) for m in metas]

@router.post("/aportes-meta")
def aportar_meta(meta_id: str, monto: float, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    m_uuid = uuid.UUID(meta_id)
    meta = db.query(BankingMetaAhorro).filter(
        BankingMetaAhorro.id == m_uuid,
        BankingMetaAhorro.id_usuario == current_user.id_usuario
    ).first()
    if not meta:
        raise HTTPException(status_code=404, detail="Meta de ahorro no encontrada")
        
    meta.monto_actual = (meta.monto_actual or 0) + Decimal(str(monto))
    if meta.monto_actual >= meta.monto_objetivo:
        meta.estado = "COMPLETADA"
        
    aporte = BankingAporteMeta(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        meta_id=m_uuid,
        monto=Decimal(str(monto)),
        created_at=datetime.utcnow()
    )
    db.add(aporte)
    db.commit()
    db.refresh(meta)
    db.refresh(aporte)
    
    res = serialize_aporte_meta(aporte)
    res["meta_completada"] = (meta.estado == "COMPLETADA")
    return res

@router.get("/aportes-meta")
def get_aportes_meta(meta_id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    m_uuid = uuid.UUID(meta_id)
    aportes = db.query(BankingAporteMeta).filter(
        BankingAporteMeta.meta_id == m_uuid,
        BankingAporteMeta.id_usuario == current_user.id_usuario
    ).order_by(BankingAporteMeta.created_at.desc()).all()
    return [serialize_aporte_meta(a) for a in aportes]


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 23 & 31 — Comparadores de simulaciones
# ═══════════════════════════════════════════════════════════

class ComparacionSimCreate(BaseModel):
    sim1_json: Any
    sim2_json: Optional[Any] = None
    sim3_json: Optional[Any] = None

@router.post("/comparaciones-sim")
def crear_comparacion(req: ComparacionSimCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    c = BankingComparacionSim(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        sim1_json=req.sim1_json,
        sim2_json=req.sim2_json,
        sim3_json=req.sim3_json,
        created_at=datetime.utcnow()
    )
    db.add(c)
    db.commit()
    db.refresh(c)
    return serialize_comparacion_sim(c)

@router.get("/comparaciones-sim")
def get_comparaciones(limit: int = 3, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    comps = db.query(BankingComparacionSim).filter(
        BankingComparacionSim.id_usuario == current_user.id_usuario
    ).order_by(BankingComparacionSim.created_at.desc()).limit(limit).all()
    return [serialize_comparacion_sim(c) for c in comps]

class SimTasasCreate(BaseModel):
    monto: float
    plazo: int
    cuota_tem2: float
    cuota_tem3: float
    cuota_tem4: float
    ahorro_vs_max: float

@router.post("/sim-tasas")
def crear_sim_tasas(req: SimTasasCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    s = BankingSimTasa(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        monto=Decimal(str(req.monto)),
        plazo=req.plazo,
        cuota_tem2=Decimal(str(req.cuota_tem2)),
        cuota_tem3=Decimal(str(req.cuota_tem3)),
        cuota_tem4=Decimal(str(req.cuota_tem4)),
        ahorro_vs_max=Decimal(str(req.ahorro_vs_max)),
        created_at=datetime.utcnow()
    )
    db.add(s)
    db.commit()
    db.refresh(s)
    return serialize_sim_tasa(s)

@router.get("/sim-tasas")
def get_sim_tasas(limit: int = 3, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    sims = db.query(BankingSimTasa).filter(
        BankingSimTasa.id_usuario == current_user.id_usuario
    ).order_by(BankingSimTasa.created_at.desc()).limit(limit).all()
    return [serialize_sim_tasa(s) for s in sims]


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 24, 25 — Recargas de celular
# ═══════════════════════════════════════════════════════════

class RecargaCreate(BaseModel):
    celular_destino: str
    operadora: str    # Claro | Movistar | Entel | Bitel
    monto: float
    cuenta_origen: str

@router.post("/recargas")
def crear_recarga(req: RecargaCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    import re
    if not re.match(r'^\d{9}$', req.celular_destino):
        raise HTTPException(status_code=400, detail="El número debe tener 9 dígitos")
    if req.monto <= 0:
        raise HTTPException(status_code=400, detail="El monto debe ser mayor a 0")
        
    r = BankingRecarga(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        celular_destino=req.celular_destino,
        celular_enmascarado="****" + req.celular_destino[-4:],
        operadora=req.operadora,
        monto=Decimal(str(req.monto)),
        cuenta_origen=req.cuenta_origen,
        estado="PROCESADA",
        numero_operacion=str(uuid.uuid4())[:8].upper(),
        created_at=datetime.utcnow()
    )
    db.add(r)
    db.commit()
    db.refresh(r)
    return serialize_recarga(r)

@router.get("/recargas")
def get_recargas(operadora: Optional[str] = None, limit: int = 20, offset: int = 0, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    q = db.query(BankingRecarga).filter(BankingRecarga.id_usuario == current_user.id_usuario)
    if operadora:
        q = q.filter(BankingRecarga.operadora == operadora)
    recs = q.order_by(BankingRecarga.created_at.desc()).offset(offset).limit(limit).all()
    return [serialize_recarga(r) for r in recs]

@router.delete("/recargas/{id}")
def delete_recarga(id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    r_uuid = uuid.UUID(id)
    item = db.query(BankingRecarga).filter(
        BankingRecarga.id == r_uuid,
        BankingRecarga.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Recarga no encontrada")
    db.delete(item)
    db.commit()
    return {"message": "Recarga eliminada"}


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 26, 27 — Gastos personales y Presupuesto
# ═══════════════════════════════════════════════════════════

class GastoCreate(BaseModel):
    descripcion: str
    monto: float
    categoria: str    # Comida | Transporte | Salud | Entretenimiento | Otros

@router.post("/gastos")
def crear_gasto(req: GastoCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    g = BankingGasto(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        descripcion=req.descripcion,
        monto=Decimal(str(req.monto)),
        categoria=req.categoria,
        created_at=datetime.utcnow()
    )
    db.add(g)
    db.commit()
    db.refresh(g)
    return serialize_gasto(g)

@router.get("/gastos")
def get_gastos(mes: Optional[str] = None, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    q = db.query(BankingGasto).filter(BankingGasto.id_usuario == current_user.id_usuario)
    gastos = q.order_by(BankingGasto.created_at.desc()).all()
    
    # Filter by month if provided (format YYYY-MM)
    if mes:
        res = []
        for g in gastos:
            fecha_str = g.created_at.isoformat() if isinstance(g.created_at, datetime) else str(g.created_at)
            if fecha_str.startswith(mes):
                res.append(g)
        return [serialize_gasto(g) for g in res]
        
    return [serialize_gasto(g) for g in gastos]

@router.delete("/gastos/{id}")
def delete_gasto(id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    g_uuid = uuid.UUID(id)
    item = db.query(BankingGasto).filter(
        BankingGasto.id == g_uuid,
        BankingGasto.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Gasto no encontrado")
    db.delete(item)
    db.commit()
    return {"message": "Gasto eliminado"}

class PresupuestoCreate(BaseModel):
    categoria: str
    limite: float
    mes: int
    anio: int

@router.post("/presupuestos")
def crear_presupuesto(req: PresupuestoCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    existing = db.query(BankingPresupuesto).filter(
        BankingPresupuesto.id_usuario == current_user.id_usuario,
        BankingPresupuesto.categoria == req.categoria,
        BankingPresupuesto.mes == req.mes,
        BankingPresupuesto.anio == req.anio
    ).first()
    
    if existing:
        existing.limite = Decimal(str(req.limite))
        db.commit()
        db.refresh(existing)
        return serialize_presupuesto(existing)
        
    p = BankingPresupuesto(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        categoria=req.categoria,
        limite=Decimal(str(req.limite)),
        mes=req.mes,
        anio=req.anio,
        created_at=datetime.utcnow()
    )
    db.add(p)
    db.commit()
    db.refresh(p)
    return serialize_presupuesto(p)

@router.get("/presupuestos")
def get_presupuestos(current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    pres = db.query(BankingPresupuesto).filter(
        BankingPresupuesto.id_usuario == current_user.id_usuario
    ).order_by(BankingPresupuesto.categoria.asc()).all()
    return [serialize_presupuesto(p) for p in pres]


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 28 — Comprobantes
# ═══════════════════════════════════════════════════════════

@router.get("/comprobantes")
def get_comprobantes(
    tipo: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
    current_user: Usuario = Depends(get_user),
    db: Session = Depends(get_db)
):
    q = db.query(BankingComprobante).filter(BankingComprobante.id_usuario == current_user.id_usuario)
    if tipo and tipo != "TODOS":
        q = q.filter(BankingComprobante.tipo == tipo)
    cmp = q.order_by(BankingComprobante.created_at.desc()).offset(offset).limit(limit).all()
    return [serialize_comprobante(c) for c in cmp]


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 30 — Retiros programados
# ═══════════════════════════════════════════════════════════

class RetiroProgramadoCreate(BaseModel):
    cuenta_id: str
    monto: float
    fecha_programada: str
    motivo: str

@router.post("/retiros-programados")
def crear_retiro_programado(req: RetiroProgramadoCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    try:
        f_prog = date.fromisoformat(req.fecha_programada)
    except Exception:
        raise HTTPException(status_code=400, detail="Fecha programada inválida, debe ser YYYY-MM-DD")
        
    r = BankingRetiroProgramado(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        cuenta_id=req.cuenta_id,
        monto=Decimal(str(req.monto)),
        fecha_programada=f_prog,
        estado="PENDIENTE",
        created_at=datetime.utcnow()
    )
    db.add(r)
    db.commit()
    db.refresh(r)
    return serialize_retiro_programado(r)

@router.get("/retiros-programados")
def get_retiros_programados(current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    ret = db.query(BankingRetiroProgramado).filter(
        BankingRetiroProgramado.id_usuario == current_user.id_usuario
    ).order_by(BankingRetiroProgramado.created_at.desc()).all()
    return [serialize_retiro_programado(r) for r in ret]

@router.patch("/retiros-programados/{id}/cancelar")
def cancelar_retiro_programado(id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    r_uuid = uuid.UUID(id)
    item = db.query(BankingRetiroProgramado).filter(
        BankingRetiroProgramado.id == r_uuid,
        BankingRetiroProgramado.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Retiro programado no encontrado")
    item.estado = "CANCELADO"
    db.commit()
    db.refresh(item)
    return serialize_retiro_programado(item)


# ═══════════════════════════════════════════════════════════
# CASUÍSTICA 34 — Ahorro automático por porcentaje
# ═══════════════════════════════════════════════════════════

class ReglaAhorroCreate(BaseModel):
    cuenta_origen: str
    cuenta_destino: str
    porcentaje: float   # 1-30

@router.post("/reglas-ahorro")
def crear_regla_ahorro(req: ReglaAhorroCreate, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    if req.porcentaje < 1 or req.porcentaje > 30:
        raise HTTPException(status_code=400, detail="El porcentaje debe estar entre 1% y 30%")
        
    r = BankingReglaAhorro(
        id=uuid.uuid4(),
        id_usuario=current_user.id_usuario,
        cuenta_origen=req.cuenta_origen,
        cuenta_destino=req.cuenta_destino,
        porcentaje=Decimal(str(req.porcentaje)),
        activa=True,
        fecha_creacion=datetime.utcnow()
    )
    db.add(r)
    db.commit()
    db.refresh(r)
    return serialize_regla_ahorro(r)

@router.get("/reglas-ahorro")
def get_reglas_ahorro(current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    reglas = db.query(BankingReglaAhorro).filter(
        BankingReglaAhorro.id_usuario == current_user.id_usuario
    ).order_by(BankingReglaAhorro.fecha_creacion.desc()).all()
    return [serialize_regla_ahorro(r) for r in reglas]

@router.patch("/reglas-ahorro/{id}")
def toggle_regla_ahorro(id: str, activa: bool, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    r_uuid = uuid.UUID(id)
    item = db.query(BankingReglaAhorro).filter(
        BankingReglaAhorro.id == r_uuid,
        BankingReglaAhorro.id_usuario == current_user.id_usuario
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Regla de ahorro no encontrada")
    item.activa = activa
    db.commit()
    db.refresh(item)
    return serialize_regla_ahorro(item)

@router.get("/ahorro-automatico-log")
def get_ahorro_log(regla_id: str, current_user: Usuario = Depends(get_user), db: Session = Depends(get_db)):
    r_uuid = uuid.UUID(regla_id)
    logs = db.query(BankingAhorroAutomaticoLog).filter(
        BankingAhorroAutomaticoLog.regla_id == r_uuid,
        BankingAhorroAutomaticoLog.id_usuario == current_user.id_usuario
    ).order_by(BankingAhorroAutomaticoLog.fecha.desc()).all()
    return [serialize_ahorro_automatico_log(l) for l in logs]
