# campana_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Date, Numeric, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class CampanaActiva(Base):
    __tablename__ = "campanas_activas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor", ondelete="CASCADE"), nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    tipo = Column(String(30))
    monto_oferta = Column(Numeric(12, 2))
    activa = Column(Boolean, default=True)
    fecha_vencimiento = Column(Date)
    created_at = Column(DateTime(timezone=True), default=DateTime)

    asesor = relationship("Asesor", foreign_keys=[id_asesor])
    cliente = relationship("Cliente", foreign_keys=[id_cliente])
