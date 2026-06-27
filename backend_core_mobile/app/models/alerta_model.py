# alerta_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class AlertaCartera(Base):
    __tablename__ = "alertas_cartera"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor", ondelete="CASCADE"), nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    tipo = Column(String(50))
    mensaje = Column(String)
    leida = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=DateTime)

    asesor = relationship("Asesor", foreign_keys=[id_asesor])
    cliente = relationship("Cliente", foreign_keys=[id_cliente])
