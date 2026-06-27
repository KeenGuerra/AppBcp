# credito_repository.py
from sqlalchemy.orm import Session
from app.models.credito_model import Credito
from typing import List, Optional
import uuid

def get_creditos_by_cliente_id(db: Session, id_cliente: uuid.UUID) -> List[Credito]:
    return db.query(Credito).filter(Credito.id_cliente == id_cliente).all()

def get_credito_by_id(db: Session, id_credito: uuid.UUID) -> Optional[Credito]:
    return db.query(Credito).filter(Credito.id_credito == id_credito).first()

def create_credito(db: Session, credito: Credito) -> Credito:
    db.add(credito)
    db.commit()
    db.refresh(credito)
    return credito

def update_credito(db: Session, db_credito: Credito) -> Credito:
    db.commit()
    db.refresh(db_credito)
    return db_credito
