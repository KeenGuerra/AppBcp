# solicitud_repository.py
from sqlalchemy.orm import Session
from app.models.solicitud_model import SolicitudCredito, ProductoCredito
from typing import List, Optional
import uuid

def get_solicitud_by_id(db: Session, id_solicitud: uuid.UUID) -> Optional[SolicitudCredito]:
    return db.query(SolicitudCredito).filter(SolicitudCredito.id_solicitud == id_solicitud).first()

def get_solicitud_by_id_with_relations(db: Session, id_solicitud: uuid.UUID) -> Optional[SolicitudCredito]:
    """Get solicitud with eagerly loaded producto and cliente relationships"""
    result = db.query(SolicitudCredito).filter(SolicitudCredito.id_solicitud == id_solicitud).first()
    if result:
        _ = result.producto
        _ = result.cliente
    return result

def get_solicitudes_by_cliente_id(db: Session, id_cliente: uuid.UUID) -> List[SolicitudCredito]:
    return db.query(SolicitudCredito).filter(SolicitudCredito.id_cliente == id_cliente).all()

def get_solicitudes(db: Session, skip: int = 0, limit: int = 100) -> List[SolicitudCredito]:
    return db.query(SolicitudCredito).offset(skip).limit(limit).all()

def create_solicitud(db: Session, solicitud: SolicitudCredito) -> SolicitudCredito:
    db.add(solicitud)
    db.commit()
    db.refresh(solicitud)
    return solicitud

def update_solicitud(db: Session, db_solicitud: SolicitudCredito) -> SolicitudCredito:
    db.commit()
    db.refresh(db_solicitud)
    return db_solicitud

def get_producto_by_id(db: Session, id_producto: uuid.UUID) -> Optional[ProductoCredito]:
    return db.query(ProductoCredito).filter(ProductoCredito.id_producto_credito == id_producto).first()

def get_producto_by_codigo(db: Session, codigo: str) -> Optional[ProductoCredito]:
    return db.query(ProductoCredito).filter(ProductoCredito.codigo == codigo).first()

def get_productos(db: Session, skip: int = 0, limit: int = 100) -> List[ProductoCredito]:
    return db.query(ProductoCredito).offset(skip).limit(limit).all()

def create_producto(db: Session, producto: ProductoCredito) -> ProductoCredito:
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return producto

def update_producto(db: Session, db_producto: ProductoCredito) -> ProductoCredito:
    db.commit()
    db.refresh(db_producto)
    return db_producto
