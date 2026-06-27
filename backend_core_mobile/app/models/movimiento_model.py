# movimiento_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class Movimiento(Base):
    __tablename__ = "cr_movimientos"

    id_movimiento = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    id_cuenta = Column(UUID(as_uuid=True), ForeignKey("cuentas_ahorro.id_cuenta"), nullable=True)
    id_credito = Column(UUID(as_uuid=True), ForeignKey("cr_creditos.id_credito"), nullable=True)
    tipo_movimiento = Column(String(50), nullable=False) # DESEMBOLSO_CREDITO, TRANSFERENCIA, PAGO_CUOTA, DEPOSITO, RETIRO, AJUSTE
    descripcion = Column(String)
    monto = Column(Numeric(12, 2), nullable=False)
    moneda = Column(String(3), default="PEN")
    fecha_movimiento = Column(DateTime(timezone=True))
    canal = Column(String(30), nullable=False)
    created_at = Column(DateTime(timezone=True))

    cliente = relationship("Cliente", foreign_keys=[id_cliente])
    cuenta = relationship("CuentaAhorro", foreign_keys=[id_cuenta])
    credito = relationship("Credito", foreign_keys=[id_credito])

class OperacionCliente(Base):
    __tablename__ = "operaciones_cliente"

    id_operacion = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    tipo_operacion = Column(String(50), nullable=False) # TRANSFERENCIA, PAGO_CREDITO, PAGO_SERVICIO
    cuenta_origen = Column(UUID(as_uuid=True), ForeignKey("cuentas_ahorro.id_cuenta"), nullable=True)
    cuenta_destino = Column(String(30))
    id_credito = Column(UUID(as_uuid=True), ForeignKey("cr_creditos.id_credito"), nullable=True)
    monto = Column(Numeric(12, 2), nullable=False)
    moneda = Column(String(3), default="PEN")
    descripcion = Column(String)
    estado = Column(String(30), default="PENDIENTE")
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    cliente = relationship("Cliente", foreign_keys=[id_cliente])
    origen_cuenta = relationship("CuentaAhorro", foreign_keys=[cuenta_origen])
    credito = relationship("Credito", foreign_keys=[id_credito])
