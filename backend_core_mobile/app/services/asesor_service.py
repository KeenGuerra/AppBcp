# asesor_service.py
from sqlalchemy.orm import Session
from app.repositories import asesor_repository
from app.core.exceptions import NotFoundException
import uuid

def get_asesor_by_usuario_id(db: Session, id_usuario: uuid.UUID):
    ase = asesor_repository.get_asesor_by_usuario_id(db, id_usuario)
    if not ase:
        raise NotFoundException("Asesor")
    return ase
