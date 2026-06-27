# credito_service.py
from sqlalchemy.orm import Session
from app.repositories import credito_repository
import uuid

def get_creditos_by_cliente_id(db: Session, id_cliente: uuid.UUID):
    return credito_repository.get_creditos_by_cliente_id(db, id_cliente)

def get_credito_by_id(db: Session, id_credito: uuid.UUID):
    return credito_repository.get_credito_by_id(db, id_credito)
