# usuario_model.py
import uuid
from sqlalchemy import Column, String, Integer, DateTime
from sqlalchemy.dialects.postgresql import UUID
from app.database.session import Base

class Agencia(Base):
    __tablename__ = "agencias"

    id_agencia = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    codigo = Column(String(20), unique=True, nullable=False)
    nombre = Column(String(100), nullable=False)
    direccion = Column(String)
    distrito = Column(String(100))
    provincia = Column(String(100))
    departamento = Column(String(100))
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True))

class Usuario(Base):
    __tablename__ = "usuarios"

    id_usuario = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    documento = Column(String(15), unique=True, nullable=False)
    codigo_empleado = Column(String(20), unique=True, nullable=True)
    correo = Column(String(120), unique=True, nullable=True)
    password_hash = Column(String, nullable=False)
    rol = Column(String(20), nullable=False)
    estado = Column(String(20), default="ACTIVO")
    intentos_fallidos = Column(Integer, default=0)
    bloqueado_hasta = Column(DateTime(timezone=True), nullable=True)
    ultimo_login = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))
