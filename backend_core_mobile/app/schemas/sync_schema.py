# sync_schema.py
from pydantic import BaseModel
from typing import Optional, Any
from uuid import UUID
from datetime import datetime

class SyncOutboxResponse(BaseModel):
    id_evento: UUID
    tipo_evento: str
    entidad: str
    entidad_id: UUID
    payload: Any
    estado: str
    intentos: int
    error: Optional[str] = None
    created_at: datetime
    procesado_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class SyncLogResponse(BaseModel):
    id_log: UUID
    id_evento: Optional[UUID] = None
    accion: str
    resultado: str
    detalle: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
