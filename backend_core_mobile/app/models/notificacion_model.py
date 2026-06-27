# notificacion_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class Notificacion(Base):
    __tablename__ = "notificaciones"

    id_notificacion = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario"), nullable=False)
    titulo = Column(String(150), nullable=False)
    mensaje = Column(String, nullable=False)
    tipo = Column(String(50), nullable=False)
    leida = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True))

    usuario = relationship("Usuario", foreign_keys=[id_usuario])
