# comite_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories import solicitud_repository
from app.models.solicitud_model import SolicitudCredito
from typing import Optional
from decimal import Decimal
import uuid

def recibir_solicitud(db: Session, id_solicitud: uuid.UUID) -> SolicitudCredito:
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    if sol.estado not in ["ENVIADO", "BORRADOR"]: # wait, usually from ENVIADO
        raise HTTPException(status_code=400, detail="La solicitud debe estar en estado ENVIADO")
    sol.estado = "RECIBIDO_COMITE"
    db.commit()
    db.refresh(sol)
    return sol

def evaluar_solicitud(db: Session, id_solicitud: uuid.UUID) -> SolicitudCredito:
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    if sol.estado != "RECIBIDO_COMITE":
        raise HTTPException(status_code=400, detail="La solicitud debe estar en estado RECIBIDO_COMITE")
    sol.estado = "EN_EVALUACION"
    db.commit()
    db.refresh(sol)
    return sol

def aprobar_solicitud(db: Session, id_solicitud: uuid.UUID, monto_aprobado: Optional[Decimal] = None, condicion: Optional[str] = None) -> SolicitudCredito:
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    # Auto-receive and evaluate if needed
    if sol.estado in ["ENVIADO", "BORRADOR"]:
        sol.estado = "RECIBIDO_COMITE"
        db.commit()
        db.refresh(sol)
    if sol.estado == "RECIBIDO_COMITE":
        sol.estado = "EN_EVALUACION"
        db.commit()
        db.refresh(sol)
    if sol.estado not in ["EN_EVALUACION", "CONDICIONADO"]:
        raise HTTPException(status_code=400, detail="La solicitud debe estar en evaluación del comité")
    sol.estado = "APROBADO"
    sol.monto_aprobado = monto_aprobado or sol.monto_solicitado
    sol.condicion_adicional = condicion
    db.commit()
    db.refresh(sol)
    return sol

def condicionar_solicitud(db: Session, id_solicitud: uuid.UUID, condicion: str) -> SolicitudCredito:
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    if sol.estado in ["ENVIADO", "BORRADOR"]:
        sol.estado = "RECIBIDO_COMITE"
        db.commit()
        db.refresh(sol)
    if sol.estado == "RECIBIDO_COMITE":
        sol.estado = "EN_EVALUACION"
        db.commit()
        db.refresh(sol)
    if sol.estado not in ["EN_EVALUACION"]:
        raise HTTPException(status_code=400, detail="La solicitud debe estar en evaluación del comité")
    sol.estado = "CONDICIONADO"
    sol.condicion_adicional = condicion
    db.commit()
    db.refresh(sol)
    return sol

def rechazar_solicitud(db: Session, id_solicitud: uuid.UUID, motivo: str) -> SolicitudCredito:
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    if sol.estado in ["ENVIADO", "BORRADOR"]:
        sol.estado = "RECIBIDO_COMITE"
        db.commit()
        db.refresh(sol)
    if sol.estado == "RECIBIDO_COMITE":
        sol.estado = "EN_EVALUACION"
        db.commit()
        db.refresh(sol)
    if sol.estado not in ["EN_EVALUACION", "CONDICIONADO"]:
        raise HTTPException(status_code=400, detail="La solicitud debe estar en evaluación del comité")
    sol.estado = "RECHAZADO"
    sol.motivo_rechazo = motivo
    db.commit()
    db.refresh(sol)
    return sol
