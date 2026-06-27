# movimiento_repository.py
from sqlalchemy.orm import Session
from app.models.movimiento_model import Movimiento, OperacionCliente
from sqlalchemy import desc
from typing import List, Optional
import uuid

def get_movimientos_by_cliente_id(db: Session, id_cliente: uuid.UUID, limit: int = 50) -> List[Movimiento]:
    return db.query(Movimiento).filter(Movimiento.id_cliente == id_cliente).order_by(desc(Movimiento.fecha_movimiento)).limit(limit).all()

def get_movimientos_by_cuenta_id(db: Session, id_cuenta: uuid.UUID, limit: int = 50) -> List[Movimiento]:
    return db.query(Movimiento).filter(Movimiento.id_cuenta == id_cuenta).order_by(desc(Movimiento.fecha_movimiento)).limit(limit).all()

def create_movimiento(db: Session, movimiento: Movimiento) -> Movimiento:
    db.add(movimiento)
    db.commit()
    db.refresh(movimiento)
    return movimiento

def get_operacion_by_id(db: Session, id_operacion: uuid.UUID) -> Optional[OperacionCliente]:
    return db.query(OperacionCliente).filter(OperacionCliente.id_operacion == id_operacion).first()

def get_operaciones_by_cliente_id(db: Session, id_cliente: uuid.UUID, limit: int = 50) -> List[OperacionCliente]:
    return db.query(OperacionCliente).filter(OperacionCliente.id_cliente == id_cliente).order_by(desc(OperacionCliente.created_at)).limit(limit).all()

def create_operacion(db: Session, operacion: OperacionCliente) -> OperacionCliente:
    db.add(operacion)
    db.commit()
    db.refresh(operacion)
    return operacion

def update_operacion(db: Session, db_operacion: OperacionCliente) -> OperacionCliente:
    db.commit()
    db.refresh(db_operacion)
    return db_operacion
