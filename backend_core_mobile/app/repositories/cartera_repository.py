# cartera_repository.py
from sqlalchemy.orm import Session
from app.models.cartera_model import CarteraDiaria
from datetime import date
from typing import List, Optional
import uuid

def get_cartera_by_id(db: Session, id_cartera: uuid.UUID) -> Optional[CarteraDiaria]:
    return db.query(CarteraDiaria).filter(CarteraDiaria.id_cartera == id_cartera).first()

def get_cartera_hoy_by_asesor_id(db: Session, id_asesor: uuid.UUID) -> List[CarteraDiaria]:
    return db.query(CarteraDiaria).filter(
        CarteraDiaria.id_asesor == id_asesor
    ).order_by(CarteraDiaria.score_prioridad.desc()).all()

def create_cartera(db: Session, cartera: CarteraDiaria) -> CarteraDiaria:
    db.add(cartera)
    db.commit()
    db.refresh(cartera)
    return cartera

def update_cartera(db: Session, db_cartera: CarteraDiaria) -> CarteraDiaria:
    db.commit()
    db.refresh(db_cartera)
    return db_cartera
