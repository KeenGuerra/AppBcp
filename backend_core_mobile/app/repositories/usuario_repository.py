# usuario_repository.py
from sqlalchemy.orm import Session
from app.models.usuario_model import Usuario, Agencia
from typing import List, Optional
import uuid

def get_usuario_by_id(db: Session, id_usuario: uuid.UUID) -> Optional[Usuario]:
    return db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()

def get_usuario_by_documento(db: Session, documento: str) -> Optional[Usuario]:
    return db.query(Usuario).filter(Usuario.documento == documento).first()

def get_usuario_by_codigo_empleado(db: Session, codigo_empleado: str) -> Optional[Usuario]:
    return db.query(Usuario).filter(Usuario.codigo_empleado == codigo_empleado).first()

def get_usuario_by_correo(db: Session, correo: str) -> Optional[Usuario]:
    return db.query(Usuario).filter(Usuario.correo == correo).first()


def get_usuarios(db: Session, skip: int = 0, limit: int = 100) -> List[Usuario]:
    return db.query(Usuario).offset(skip).limit(limit).all()

def create_usuario(db: Session, usuario: Usuario) -> Usuario:
    db.add(usuario)
    db.commit()
    db.refresh(usuario)
    return usuario

def update_usuario(db: Session, db_usuario: Usuario) -> Usuario:
    db.commit()
    db.refresh(db_usuario)
    return db_usuario

def delete_usuario(db: Session, db_usuario: Usuario) -> None:
    db.delete(db_usuario)
    db.commit()

def get_agencia_by_id(db: Session, id_agencia: uuid.UUID) -> Optional[Agencia]:
    return db.query(Agencia).filter(Agencia.id_agencia == id_agencia).first()
