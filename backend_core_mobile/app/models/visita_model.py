# visita_model.py
import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class VisitaCliente(Base):
    __tablename__ = "visitas_cliente"

    id_visita = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_cartera = Column(UUID(as_uuid=True), ForeignKey("cartera_diaria.id_cartera"), nullable=False)
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor"), nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    resultado = Column(String(50), nullable=False)
    observacion = Column(String)
    lat = Column(Numeric(10, 7), nullable=False)
    lng = Column(Numeric(10, 7), nullable=False)
    fecha_hora = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True))

    cartera = relationship("CarteraDiaria", foreign_keys=[id_cartera])
    asesor = relationship("Asesor", foreign_keys=[id_asesor])
    cliente = relationship("Cliente", foreign_keys=[id_cliente])
