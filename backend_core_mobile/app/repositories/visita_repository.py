# visita_repository.py
from sqlalchemy.orm import Session
from app.models.visita_model import VisitaCliente
from typing import List, Optional
import uuid

def get_visita_by_id(db: Session, id_visita: uuid.UUID) -> Optional[VisitaCliente]:
    return db.query(VisitaCliente).filter(VisitaCliente.id_visita == id_visita).first()

def get_visitas_by_asesor_id(db: Session, id_asesor: uuid.UUID) -> List[VisitaCliente]:
    return db.query(VisitaCliente).filter(VisitaCliente.id_asesor == id_asesor).order_by(VisitaCliente.fecha_hora.desc()).all()

def get_visitas_by_cliente_id(db: Session, id_cliente: uuid.UUID) -> List[VisitaCliente]:
    return db.query(VisitaCliente).filter(VisitaCliente.id_cliente == id_cliente).order_by(VisitaCliente.fecha_hora.desc()).all()

def create_visita(db: Session, visita: VisitaCliente) -> VisitaCliente:
    db.add(visita)
    db.commit()
    db.refresh(visita)
    return visita
