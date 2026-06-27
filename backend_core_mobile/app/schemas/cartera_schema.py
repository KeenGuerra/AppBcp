# cartera_schema.py
from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import date, datetime
from decimal import Decimal
from app.schemas.cliente_schema import ClienteResponse
from app.schemas.solicitud_schema import SolicitudCreditoResponse

class CarteraDiariaResponse(BaseModel):
    id_cartera: UUID
    id_asesor: UUID
    id_cliente: UUID
    id_solicitud: Optional[UUID] = None
    fecha_asignacion: date
    tipo_gestion: str
    prioridad: str
    score_prioridad: int
    estado_visita: str
    resultado_visita: Optional[str] = None
    observacion_visita: Optional[str] = None
    lat_visita: Optional[Decimal] = None
    lng_visita: Optional[Decimal] = None
    timestamp_visita: Optional[datetime] = None
    pendiente_sync: bool
    created_at: datetime
    updated_at: datetime
    cliente: Optional[ClienteResponse] = None
    solicitud: Optional[SolicitudCreditoResponse] = None

    class Config:
        from_attributes = True
