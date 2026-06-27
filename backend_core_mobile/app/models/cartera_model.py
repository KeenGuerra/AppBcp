# cartera_model.py
import uuid
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Date, Numeric, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class CarteraDiaria(Base):
    __tablename__ = "cartera_diaria"

    id_cartera = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor"), nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    id_solicitud = Column(UUID(as_uuid=True), ForeignKey("solicitudes_credito.id_solicitud"), nullable=True)
    fecha_asignacion = Column(Date, nullable=False)
    tipo_gestion = Column(String(50), nullable=False)
    prioridad = Column(String(20), nullable=False)
    score_prioridad = Column(Integer, default=0)
    estado_visita = Column(String(30), default="PENDIENTE")
    resultado_visita = Column(String(50))
    observacion_visita = Column(String)
    lat_visita = Column(Numeric(10, 7))
    lng_visita = Column(Numeric(10, 7))
    timestamp_visita = Column(DateTime(timezone=True))
    pendiente_sync = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    asesor = relationship("Asesor", foreign_keys=[id_asesor])
    cliente = relationship("Cliente", foreign_keys=[id_cliente])
    solicitud = relationship("SolicitudCredito", foreign_keys=[id_solicitud])
