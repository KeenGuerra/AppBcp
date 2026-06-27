# cronograma_repository.py
from sqlalchemy.orm import Session
from app.models.cronograma_model import CronogramaPago
from typing import List, Optional
import uuid

def get_cronograma_by_credito_id(db: Session, id_credito: uuid.UUID) -> List[CronogramaPago]:
    return db.query(CronogramaPago).filter(CronogramaPago.id_credito == id_credito).order_by(CronogramaPago.numero_cuota).all()

def get_cuota_by_id(db: Session, id_cuota: uuid.UUID) -> Optional[CronogramaPago]:
    return db.query(CronogramaPago).filter(CronogramaPago.id_cuota == id_cuota).first()

def get_cuota_by_numero(db: Session, id_credito: uuid.UUID, numero_cuota: int) -> Optional[CronogramaPago]:
    return db.query(CronogramaPago).filter(CronogramaPago.id_credito == id_credito, CronogramaPago.numero_cuota == numero_cuota).first()

def create_cuotas(db: Session, cuotas: List[CronogramaPago]) -> List[CronogramaPago]:
    db.add_all(cuotas)
    db.commit()
    return cuotas

def update_cuota(db: Session, db_cuota: CronogramaPago) -> CronogramaPago:
    db.commit()
    db.refresh(db_cuota)
    return db_cuota
