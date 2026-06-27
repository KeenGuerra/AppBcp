# documento_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class SolicitudDocumento(Base):
    __tablename__ = "solicitudes_documentos"

    id_documento = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_solicitud = Column(UUID(as_uuid=True), ForeignKey("solicitudes_credito.id_solicitud"), nullable=False)
    tipo_documento = Column(String(50), nullable=False) # DNI_FRENTE, DNI_REVERSO, SUSTENTO_NEGOCIO, FOTO_NEGOCIO, FOTO_VISITA, FIRMA_CLIENTE
    nombre_archivo = Column(String(200), nullable=False)
    storage_path = Column(String, nullable=False)
    url_publica = Column(String)
    estado_validacion = Column(String(30), default="PENDIENTE")
    created_at = Column(DateTime(timezone=True))

    solicitud = relationship("SolicitudCredito", foreign_keys=[id_solicitud])
