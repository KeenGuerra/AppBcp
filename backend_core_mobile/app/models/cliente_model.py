# cliente_model.py
import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Date, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class Cliente(Base):
    __tablename__ = "clientes"

    id_cliente = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario"), nullable=True)
    id_agencia = Column(UUID(as_uuid=True), ForeignKey("agencias.id_agencia"), nullable=True)
    documento = Column(String(15), unique=True, nullable=False)
    nombres = Column(String(100), nullable=False)
    apellidos = Column(String(100), nullable=False)
    telefono = Column(String(20))
    correo = Column(String(120))
    direccion = Column(String)
    distrito = Column(String(100))
    provincia = Column(String(100))
    departamento = Column(String(100))
    fecha_nacimiento = Column(Date)
    estado_civil = Column(String(30))
    ocupacion = Column(String(100))
    tipo_cliente = Column(String(30))
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    usuario = relationship("Usuario", foreign_keys=[id_usuario])
    agencia = relationship("Agencia", foreign_keys=[id_agencia])
    negocios = relationship("NegocioCliente", back_populates="cliente", cascade="all, delete-orphan")

class NegocioCliente(Base):
    __tablename__ = "negocios_cliente"

    id_negocio = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    nombre_comercial = Column(String(150), nullable=False)
    giro_negocio = Column(String(100))
    antiguedad_meses = Column(Integer)
    ingreso_mensual = Column(Numeric(12, 2))
    gasto_mensual = Column(Numeric(12, 2))
    direccion_negocio = Column(String)
    lat_negocio = Column(Numeric(10, 7))
    lng_negocio = Column(Numeric(10, 7))
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    cliente = relationship("Cliente", back_populates="negocios")
