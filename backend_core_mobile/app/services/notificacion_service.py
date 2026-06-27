# notificacion_service.py
from sqlalchemy.orm import Session
from app.models.notificacion_model import Notificacion
from datetime import datetime
from typing import List
import uuid

def crear_notificacion_automatica(db: Session, id_usuario: uuid.UUID, titulo: str, mensaje: str, tipo: str) -> Notificacion:
    notif = Notificacion(
        id_notificacion=uuid.uuid4(),
        id_usuario=id_usuario,
        titulo=titulo,
        mensaje=mensaje,
        tipo=tipo,
        leida=False,
        created_at=datetime.utcnow()
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return notif

def get_notificaciones_by_usuario_id(db: Session, id_usuario: uuid.UUID) -> List[Notificacion]:
    return db.query(Notificacion).filter(Notificacion.id_usuario == id_usuario).order_by(Notificacion.created_at.desc()).all()

def marcar_leida(db: Session, id_notificacion: uuid.UUID, id_usuario: uuid.UUID) -> Notificacion:
    notif = db.query(Notificacion).filter(
        Notificacion.id_notificacion == id_notificacion,
        Notificacion.id_usuario == id_usuario
    ).first()
    if notif:
        notif.leida = True
        db.commit()
        db.refresh(notif)
    return notif
