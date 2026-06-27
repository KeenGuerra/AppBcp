# supervisor_routes.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, require_roles
from app.models.usuario_model import Usuario
from app.models.cartera_model import CarteraDiaria
from app.models.solicitud_model import SolicitudCredito
from app.models.asesor_model import Asesor
from app.services import comite_service, desembolso_service
from pydantic import BaseModel
from typing import List, Optional
import uuid
import datetime

router = APIRouter(prefix="/supervisor", tags=["Supervisor"])

def get_supervisor_user(current_user: Usuario = Depends(require_roles(["SUPERVISOR", "ADMIN"]))):
    return current_user

class SolicitudEstadoUpdateRequest(BaseModel):
    estado: str # APROBADO, RECHAZADO, CONDICIONADO, DESEMBOLSADO
    monto_aprobado: Optional[float] = None
    condicion_adicional: Optional[str] = None
    motivo_rechazo: Optional[str] = None

@router.get("/cartera/hoy")
def get_cartera_hoy_supervisor(current_user: Usuario = Depends(get_supervisor_user), db: Session = Depends(get_db)):
    today = datetime.date.today()
    items = db.query(CarteraDiaria).all() # Return all assigned items for monitoring
    res = []
    for item in items:
        ase = item.asesor
        cli = item.cliente
        res.append({
            "id_cartera": str(item.id_cartera),
            "asesor_nombre": f"{ase.nombres} {ase.apellidos}" if ase else "Asesor Desconocido",
            "cliente_nombre": f"{cli.nombres} {cli.apellidos}" if cli else "Cliente Desconocido",
            "cliente_documento": cli.documento if cli else "",
            "tipo_gestion": item.tipo_gestion,
            "prioridad": item.prioridad,
            "estado_visita": item.estado_visita,
            "resultado_visita": item.resultado_visita,
            "observacion_visita": item.observacion_visita,
            "lat_visita": float(item.lat_visita) if item.lat_visita else None,
            "lng_visita": float(item.lng_visita) if item.lng_visita else None,
            "timestamp_visita": item.timestamp_visita.isoformat() if hasattr(item.timestamp_visita, 'isoformat') else item.timestamp_visita,
            "fecha_asignacion": item.fecha_asignacion.isoformat() if hasattr(item.fecha_asignacion, 'isoformat') else item.fecha_asignacion
        })
    return res

@router.get("/reporte/productividad")
def get_productividad_supervisor(current_user: Usuario = Depends(get_supervisor_user), db: Session = Depends(get_db)):
    # We will reuse the productivity logic
    today = datetime.date.today()
    start_date = datetime.date(today.year, today.month, 1)
    if today.month == 12:
        end_date = datetime.date(today.year + 1, 1, 1)
    else:
        end_date = datetime.date(today.year, today.month + 1, 1)

    asesores = db.query(Asesor).filter(Asesor.estado == "ACTIVO").all()
    result = []

    for ase in asesores:
        sols = db.query(SolicitudCredito).filter(
            SolicitudCredito.id_asesor == ase.id_asesor,
            SolicitudCredito.created_at >= start_date,
            SolicitudCredito.created_at < end_date
        ).all()

        enviadas = len([s for s in sols if s.estado in ["ENVIADO", "RECIBIDO_COMITE", "EN_EVALUACION"]])
        aprobadas = len([s for s in sols if s.estado in ["APROBADO", "CONDICIONADO"]])
        desembolsadas = len([s for s in sols if s.estado == "DESEMBOLSADO"])
        rechazadas = len([s for s in sols if s.estado == "RECHAZADO"])
        total = len(sols)

        monto_total_aprobado = sum(float(s.monto_aprobado or 0) for s in sols if s.estado in ["APROBADO", "CONDICIONADO", "DESEMBOLSADO"])
        
        den = (aprobadas + rechazadas + desembolsadas)
        tasa_aprobacion = (aprobadas + desembolsadas) / den * 100.0 if den > 0 else 0.0

        result.append({
            "id_asesor": str(ase.id_asesor),
            "codigo_empleado": ase.codigo_empleado,
            "asesor_nombre": f"{ase.nombres} {ase.apellidos}",
            "solicitudes_enviadas": enviadas,
            "solicitudes_aprobadas": aprobadas,
            "solicitudes_desembolsadas": desembolsadas,
            "solicitudes_rechazadas": rechazadas,
            "solicitudes_totales": total,
            "monto_total_aprobado": round(monto_total_aprobado, 2),
            "tasa_aprobacion": round(tasa_aprobacion, 2)
        })
    return result

@router.get("/solicitudes")
def get_solicitudes_supervisor(current_user: Usuario = Depends(get_supervisor_user), db: Session = Depends(get_db)):
    solicitudes = db.query(SolicitudCredito).order_by(SolicitudCredito.created_at.desc()).all()
    res = []
    for s in solicitudes:
        cli = s.cliente
        ase = s.asesor
        res.append({
            "id_solicitud": str(s.id_solicitud),
            "numero_expediente": s.numero_expediente,
            "id_cliente": str(s.id_cliente),
            "cliente_nombre": f"{cli.nombres} {cli.apellidos}" if cli else "Cliente Desconocido",
            "cliente_documento": cli.documento if cli else "",
            "asesor_nombre": f"{ase.nombres} {ase.apellidos}" if ase else "Asesor Desconocido",
            "monto_solicitado": float(s.monto_solicitado) if s.monto_solicitado else 0.0,
            "monto_aprobado": float(s.monto_aprobado) if s.monto_aprobado else None,
            "plazo_meses": s.plazo_meses,
            "destino_credito": s.destino_credito,
            "resultado_preevaluacion": s.resultado_preevaluacion,
            "puntaje_preevaluacion": s.puntaje_preevaluacion,
            "resultado_buro": s.resultado_buro,
            "estado": s.estado,
            "condicion_adicional": s.condicion_adicional,
            "motivo_rechazo": s.motivo_rechazo,
            "created_at": s.created_at.isoformat() if hasattr(s.created_at, 'isoformat') else s.created_at
        })
    return res

@router.patch("/solicitudes/{id_solicitud}/estado")
def actualizar_estado_solicitud(id_solicitud: uuid.UUID, req: SolicitudEstadoUpdateRequest, current_user: Usuario = Depends(get_supervisor_user), db: Session = Depends(get_db)):
    sol = db.query(SolicitudCredito).filter(SolicitudCredito.id_solicitud == id_solicitud).first()
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    est = req.estado.upper()
    if est == "APROBADO":
        monto = req.monto_aprobado or float(sol.monto_solicitado)
        return comite_service.aprobar_solicitud(db, id_solicitud, monto, req.condicion_adicional)
    elif est == "CONDICIONADO":
        if not req.condicion_adicional:
            raise HTTPException(status_code=400, detail="Debe especificar la condición adicional")
        return comite_service.condicionar_solicitud(db, id_solicitud, req.condicion_adicional)
    elif est == "RECHAZADO":
        if not req.motivo_rechazo:
            raise HTTPException(status_code=400, detail="Debe especificar el motivo de rechazo")
        return comite_service.rechazar_solicitud(db, id_solicitud, req.motivo_rechazo)
    elif est == "DESEMBOLSADO":
        # Desembolsar converts Solicitud to Credito
        res_cred = desembolso_service.desembolsar_solicitud(db, id_solicitud)
        return {
            "message": "Solicitud desembolsada correctamente",
            "id_credito": str(res_cred.id_credito),
            "numero_credito": res_cred.numero_credito,
            "estado": "DESEMBOLSADO"
        }
    else:
        raise HTTPException(status_code=400, detail=f"Estado {req.estado} no soportado para actualización directa")
