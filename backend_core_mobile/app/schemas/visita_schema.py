# visita_schema.py
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime
from decimal import Decimal

class VisitaClienteCreate(BaseModel):
    id_cartera: UUID
    resultado: str # PENDIENTE, REALIZADA, NO_ENCONTRADO, etc.
    observacion: Optional[str] = None
    lat: Decimal
    lng: Decimal

class VisitaClienteResponse(BaseModel):
    id_visita: UUID
    id_cartera: UUID
    id_asesor: UUID
    id_cliente: UUID
    resultado: str
    observacion: Optional[str] = None
    lat: Decimal
    lng: Decimal
    fecha_hora: datetime
    created_at: datetime

    class Config:
        from_attributes = True
