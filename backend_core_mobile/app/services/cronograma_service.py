# cronograma_service.py
from sqlalchemy.orm import Session
from app.repositories import cronograma_repository
import uuid

def get_cronograma_by_credito_id(db: Session, id_credito: uuid.UUID):
    return cronograma_repository.get_cronograma_by_credito_id(db, id_credito)
