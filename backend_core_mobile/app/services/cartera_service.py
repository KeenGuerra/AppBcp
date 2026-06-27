# cartera_service.py
from sqlalchemy.orm import Session
from app.repositories import cartera_repository
import uuid

def get_cartera_hoy_by_asesor_id(db: Session, id_asesor: uuid.UUID):
    return cartera_repository.get_cartera_hoy_by_asesor_id(db, id_asesor)

def get_cartera_by_id(db: Session, id_cartera: uuid.UUID):
    return cartera_repository.get_cartera_by_id(db, id_cartera)
