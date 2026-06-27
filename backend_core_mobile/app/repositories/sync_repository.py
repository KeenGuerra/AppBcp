# sync_repository.py
from sqlalchemy.orm import Session
from app.models.sync_model import SyncOutbox, SyncLog
from app.models.auditoria_model import AuditoriaEvento
from sqlalchemy import desc
from typing import List, Optional
import uuid

def get_outbox_pending(db: Session) -> List[SyncOutbox]:
    return db.query(SyncOutbox).filter(SyncOutbox.estado == "PENDIENTE").order_by(SyncOutbox.created_at).all()

def get_outbox_by_id(db: Session, id_evento: uuid.UUID) -> Optional[SyncOutbox]:
    return db.query(SyncOutbox).filter(SyncOutbox.id_evento == id_evento).first()

def create_outbox_event(db: Session, evento: SyncOutbox) -> SyncOutbox:
    db.add(evento)
    db.commit()
    db.refresh(evento)
    return evento

def update_outbox_event(db: Session, db_evento: SyncOutbox) -> SyncOutbox:
    db.commit()
    db.refresh(db_evento)
    return db_evento

def create_sync_log(db: Session, log: SyncLog) -> SyncLog:
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

def get_sync_logs(db: Session, limit: int = 100) -> List[SyncLog]:
    return db.query(SyncLog).order_by(desc(SyncLog.created_at)).limit(limit).all()

# Auditoria
def create_auditoria_evento(db: Session, aud: AuditoriaEvento) -> AuditoriaEvento:
    db.add(aud)
    db.commit()
    db.refresh(aud)
    return aud

def get_auditoria_eventos(db: Session, limit: int = 100) -> List[AuditoriaEvento]:
    return db.query(AuditoriaEvento).order_by(desc(AuditoriaEvento.created_at)).limit(limit).all()
