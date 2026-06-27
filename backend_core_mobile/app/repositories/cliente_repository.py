# cliente_repository.py
from sqlalchemy.orm import Session
from app.models.cliente_model import Cliente, NegocioCliente
from typing import List, Optional
import uuid

def get_cliente_by_id(db: Session, id_cliente: uuid.UUID) -> Optional[Cliente]:
    return db.query(Cliente).filter(Cliente.id_cliente == id_cliente).first()

def get_cliente_by_documento(db: Session, documento: str) -> Optional[Cliente]:
    return db.query(Cliente).filter(Cliente.documento == documento).first()

def get_cliente_by_usuario_id(db: Session, id_usuario: uuid.UUID) -> Optional[Cliente]:
    return db.query(Cliente).filter(Cliente.id_usuario == id_usuario).first()

def get_clientes(db: Session, skip: int = 0, limit: int = 100) -> List[Cliente]:
    return db.query(Cliente).offset(skip).limit(limit).all()

def create_cliente(db: Session, cliente: Cliente) -> Cliente:
    db.add(cliente)
    db.commit()
    db.refresh(cliente)
    return cliente

def get_negocio_by_id(db: Session, id_negocio: uuid.UUID) -> Optional[NegocioCliente]:
    return db.query(NegocioCliente).filter(NegocioCliente.id_negocio == id_negocio).first()

def get_negocios_by_cliente_id(db: Session, id_cliente: uuid.UUID) -> List[NegocioCliente]:
    return db.query(NegocioCliente).filter(NegocioCliente.id_cliente == id_cliente).all()

def create_negocio(db: Session, negocio: NegocioCliente) -> NegocioCliente:
    db.add(negocio)
    db.commit()
    db.refresh(negocio)
    return negocio
