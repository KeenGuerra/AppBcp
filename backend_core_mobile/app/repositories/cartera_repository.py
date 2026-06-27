# cartera_repository.py
from sqlalchemy.orm import Session
from app.models.cartera_model import CarteraDiaria
from datetime import date
from typing import List, Optional
import uuid

def get_cartera_by_id(db: Session, id_cartera: uuid.UUID) -> Optional[CarteraDiaria]:
    return db.query(CarteraDiaria).filter(CarteraDiaria.id_cartera == id_cartera).first()

def get_cartera_hoy_by_asesor_id(db: Session, id_asesor: uuid.UUID) -> List[CarteraDiaria]:
    # We can query all portfolio items assigned for today or in the future/past that are pending, or simply filter by date.
    # To make it robust, we'll query fecha_asignacion = today
    today = date.today()
    return db.query(CarteraDiaria).filter(
        CarteraDiaria.id_asesor == id_asesor,
        CarteraDiaria.fecha_asignacion == today
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
