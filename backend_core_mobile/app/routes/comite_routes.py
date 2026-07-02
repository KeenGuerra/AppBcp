# comite_routes.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, require_roles
from app.models.usuario_model import Usuario
from app.schemas.solicitud_schema import SolicitudCreditoResponse, ComiteDecisionRequest
from app.schemas.credito_schema import CreditoResponse
from app.services import comite_service, desembolso_service
from app.repositories import solicitud_repository
from typing import List
import uuid

router = APIRouter(prefix="/comite", tags=["Comité / Supervisor"])

# Supervisor or Admin access
def get_comite_user(current_user: Usuario = Depends(require_roles(["SUPERVISOR", "ADMIN"]))):
    return current_user

@router.get("/solicitudes", response_model=List[SolicitudCreditoResponse])
def get_solicitudes(current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    # Supervisor sees all solicitudes in their agency or overall. We will return overall for simplicity.
    return db.query(solicitud_repository.SolicitudCredito).filter(
        solicitud_repository.SolicitudCredito.estado.in_(["ENVIADO", "RECIBIDO_COMITE", "EN_EVALUACION", "APROBADO", "CONDICIONADO", "RECHAZADO", "DESEMBOLSADO"])
    ).all()

@router.get("/solicitudes/{id_solicitud}", response_model=SolicitudCreditoResponse)
def get_solicitud(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    return sol

@router.post("/solicitudes/{id_solicitud}/recibir", response_model=SolicitudCreditoResponse)
def recibir_solicitud(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    return comite_service.recibir_solicitud(db, id_solicitud)

@router.post("/solicitudes/{id_solicitud}/evaluar", response_model=SolicitudCreditoResponse)
def evaluar_solicitud(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    return comite_service.evaluar_solicitud(db, id_solicitud)

@router.post("/solicitudes/{id_solicitud}/aprobar", response_model=SolicitudCreditoResponse)
def aprobar_solicitud(id_solicitud: uuid.UUID, req: ComiteDecisionRequest, current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    return comite_service.aprobar_solicitud(db, id_solicitud, req.monto_aprobado, req.condicion_adicional)

@router.post("/solicitudes/{id_solicitud}/condicionar", response_model=SolicitudCreditoResponse)
def condicionar_solicitud(id_solicitud: uuid.UUID, req: ComiteDecisionRequest, current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    if not req.condicion_adicional:
        raise HTTPException(status_code=400, detail="Debe especificar la condición adicional")
    return comite_service.condicionar_solicitud(db, id_solicitud, req.condicion_adicional)

@router.post("/solicitudes/{id_solicitud}/rechazar", response_model=SolicitudCreditoResponse)
def rechazar_solicitud(id_solicitud: uuid.UUID, req: ComiteDecisionRequest, current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    if not req.motivo_rechazo:
        raise HTTPException(status_code=400, detail="Debe especificar el motivo de rechazo")
    return comite_service.rechazar_solicitud(db, id_solicitud, req.motivo_rechazo)

@router.post("/solicitudes/{id_solicitud}/desembolsar", response_model=CreditoResponse)
def desembolsar_solicitud(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    try:
        return desembolso_service.desembolsar_solicitud(db, id_solicitud)
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error al desembolsar: {str(e)}")

@router.get("/productividad")
def get_productividad(current_user: Usuario = Depends(get_comite_user), db: Session = Depends(get_db)):
    from app.models.asesor_model import Asesor
    from app.models.solicitud_model import SolicitudCredito
    import datetime

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

