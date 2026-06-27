# documento_repository.py
from sqlalchemy.orm import Session
from app.models.documento_model import SolicitudDocumento
from typing import List, Optional
import uuid

def get_documento_by_id(db: Session, id_documento: uuid.UUID) -> Optional[SolicitudDocumento]:
    return db.query(SolicitudDocumento).filter(SolicitudDocumento.id_documento == id_documento).first()

def get_documentos_by_solicitud_id(db: Session, id_solicitud: uuid.UUID) -> List[SolicitudDocumento]:
    return db.query(SolicitudDocumento).filter(SolicitudDocumento.id_solicitud == id_solicitud).all()

def create_documento(db: Session, documento: SolicitudDocumento) -> SolicitudDocumento:
    db.add(documento)
    db.commit()
    db.refresh(documento)
    return documento

def update_documento(db: Session, db_documento: SolicitudDocumento) -> SolicitudDocumento:
    db.commit()
    db.refresh(db_documento)
    return db_documento
