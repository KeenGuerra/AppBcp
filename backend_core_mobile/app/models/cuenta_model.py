# cuenta_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Numeric, Date
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class CuentaAhorro(Base):
    __tablename__ = "cuentas_ahorro"

    id_cuenta = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    numero_cuenta = Column(String(30), unique=True, nullable=False)
    cci = Column(String(30), unique=True, nullable=False)
    moneda = Column(String(3), default="PEN")
    saldo_disponible = Column(Numeric(12, 2), default=0.00)
    saldo_contable = Column(Numeric(12, 2), default=0.00)
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    cliente = relationship("Cliente", foreign_keys=[id_cliente])

class Tarjeta(Base):
    __tablename__ = "tarjetas"

    id_tarjeta = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    numero_enmascarado = Column(String(30), nullable=False)
    tipo_tarjeta = Column(String(30))
    marca = Column(String(30))
    estado = Column(String(20), default="ACTIVO")
    fecha_vencimiento = Column(Date, nullable=False)
    created_at = Column(DateTime(timezone=True))

    cliente = relationship("Cliente", foreign_keys=[id_cliente])
