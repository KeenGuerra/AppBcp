# credito_model.py
import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Numeric, Date
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class Credito(Base):
    __tablename__ = "cr_creditos"

    id_credito = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_solicitud = Column(UUID(as_uuid=True), ForeignKey("solicitudes_credito.id_solicitud"), nullable=True)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    numero_credito = Column(String(30), unique=True, nullable=False)
    producto = Column(String(120), nullable=False)
    monto_desembolsado = Column(Numeric(12, 2), nullable=False)
    saldo_capital = Column(Numeric(12, 2), nullable=False)
    plazo_meses = Column(Integer, nullable=False)
    tea = Column(Numeric(5, 2), nullable=False)
    tem = Column(Numeric(8, 6), nullable=False)
    cuota_mensual = Column(Numeric(12, 2), nullable=False)
    fecha_desembolso = Column(Date, nullable=False)
    dia_pago = Column(Integer, nullable=False)
    estado = Column(String(30), nullable=False) # VIGENTE, CANCELADO, VENCIDO
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    cliente = relationship("Cliente", foreign_keys=[id_cliente])
    solicitud = relationship("SolicitudCredito", foreign_keys=[id_solicitud])
