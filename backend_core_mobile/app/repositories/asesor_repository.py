# asesor_repository.py
from sqlalchemy.orm import Session
from app.models.asesor_model import Asesor
from typing import List, Optional
import uuid

def get_asesor_by_id(db: Session, id_asesor: uuid.UUID) -> Optional[Asesor]:
    return db.query(Asesor).filter(Asesor.id_asesor == id_asesor).first()

def get_asesor_by_codigo_empleado(db: Session, codigo_empleado: str) -> Optional[Asesor]:
    return db.query(Asesor).filter(Asesor.codigo_empleado == codigo_empleado).first()

def get_asesor_by_usuario_id(db: Session, id_usuario: uuid.UUID) -> Optional[Asesor]:
    return db.query(Asesor).filter(Asesor.id_usuario == id_usuario).first()

def get_asesores(db: Session, skip: int = 0, limit: int = 100) -> List[Asesor]:
    return db.query(Asesor).offset(skip).limit(limit).all()

def create_asesor(db: Session, asesor: Asesor) -> Asesor:
    db.add(asesor)
    db.commit()
    db.refresh(asesor)
    return asesor
