# asesor_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class Asesor(Base):
    __tablename__ = "asesores"

    id_asesor = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario"), nullable=True)
    id_agencia = Column(UUID(as_uuid=True), ForeignKey("agencias.id_agencia"), nullable=True)
    codigo_empleado = Column(String(20), unique=True, nullable=False)
    nombres = Column(String(100), nullable=False)
    apellidos = Column(String(100), nullable=False)
    telefono = Column(String(20))
    cargo = Column(String(80))
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    usuario = relationship("Usuario", foreign_keys=[id_usuario])
    agencia = relationship("Agencia", foreign_keys=[id_agencia])
