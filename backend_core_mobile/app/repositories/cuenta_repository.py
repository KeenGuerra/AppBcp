# cuenta_repository.py
from sqlalchemy.orm import Session
from app.models.cuenta_model import CuentaAhorro, Tarjeta
from typing import List, Optional
import uuid

def get_cuentas_by_cliente_id(db: Session, id_cliente: uuid.UUID) -> List[CuentaAhorro]:
    return db.query(CuentaAhorro).filter(CuentaAhorro.id_cliente == id_cliente).all()

def get_cuenta_by_id(db: Session, id_cuenta: uuid.UUID) -> Optional[CuentaAhorro]:
    return db.query(CuentaAhorro).filter(CuentaAhorro.id_cuenta == id_cuenta).first()

def get_cuenta_by_numero(db: Session, numero_cuenta: str) -> Optional[CuentaAhorro]:
    return db.query(CuentaAhorro).filter(CuentaAhorro.numero_cuenta == numero_cuenta).first()

def create_cuenta(db: Session, cuenta: CuentaAhorro) -> CuentaAhorro:
    db.add(cuenta)
    db.commit()
    db.refresh(cuenta)
    return cuenta

def update_cuenta(db: Session, db_cuenta: CuentaAhorro) -> CuentaAhorro:
    db.commit()
    db.refresh(db_cuenta)
    return db_cuenta

def get_tarjetas_by_cliente_id(db: Session, id_cliente: uuid.UUID) -> List[Tarjeta]:
    return db.query(Tarjeta).filter(Tarjeta.id_cliente == id_cliente).all()

def create_tarjeta(db: Session, tarjeta: Tarjeta) -> Tarjeta:
    db.add(tarjeta)
    db.commit()
    db.refresh(tarjeta)
    return tarjeta
