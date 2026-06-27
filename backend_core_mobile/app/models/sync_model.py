# sync_model.py
import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.database.session import Base

class SyncOutbox(Base):
    __tablename__ = "sync_outbox"

    id_evento = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tipo_evento = Column(String(80), nullable=False)
    entidad = Column(String(80), nullable=False)
    entidad_id = Column(UUID(as_uuid=True), nullable=False)
    payload = Column(JSONB, nullable=False)
    estado = Column(String(30), default="PENDIENTE")
    intentos = Column(Integer, default=0)
    error = Column(String)
    created_at = Column(DateTime(timezone=True))
    procesado_at = Column(DateTime(timezone=True))

class SyncLog(Base):
    __tablename__ = "sync_log"

    id_log = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_evento = Column(UUID(as_uuid=True), ForeignKey("sync_outbox.id_evento"), nullable=True)
    accion = Column(String(100), nullable=False)
    resultado = Column(String(30), nullable=False)
    detalle = Column(String)
    created_at = Column(DateTime(timezone=True))

    evento = relationship("SyncOutbox", foreign_keys=[id_evento])
