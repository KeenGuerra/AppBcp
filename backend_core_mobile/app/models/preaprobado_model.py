# preaprobado_model.py
import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Date, Numeric, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class CreditoPreaprobado(Base):
    __tablename__ = "creditos_preaprobados"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    monto_maximo = Column(Numeric(12, 2))
    plazo_sugerido = Column(Integer)
    tea_referencial = Column(Numeric(5, 2))
    score_confianza = Column(Integer)
    nivel_confianza = Column(String(20))
    vigente = Column(Boolean, default=True)
    fecha_vencimiento = Column(Date)
    created_at = Column(DateTime(timezone=True), default=DateTime)

    cliente = relationship("Cliente", foreign_keys=[id_cliente])
