# movimiento_service.py
from sqlalchemy.orm import Session
from app.repositories import movimiento_repository
import uuid

def get_movimientos_by_cliente_id(db: Session, id_cliente: uuid.UUID, limit: int = 50):
    return movimiento_repository.get_movimientos_by_cliente_id(db, id_cliente, limit)
