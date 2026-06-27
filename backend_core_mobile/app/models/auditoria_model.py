# auditoria_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.database.session import Base

class AuditoriaEvento(Base):
    __tablename__ = "auditoria_eventos"

    id_auditoria = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario"), nullable=True)
    accion = Column(String(100), nullable=False)
    entidad = Column(String(100), nullable=False)
    entidad_id = Column(UUID(as_uuid=True))
    ip = Column(String(80))
    user_agent = Column(String)
    detalle = Column(JSONB)
    created_at = Column(DateTime(timezone=True))

    usuario = relationship("Usuario", foreign_keys=[id_usuario])
