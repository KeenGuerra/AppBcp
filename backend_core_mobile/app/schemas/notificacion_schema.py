# notificacion_schema.py
from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime

class NotificacionResponse(BaseModel):
    id_notificacion: UUID
    titulo: str
    mensaje: str
    tipo: str
    leida: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class NotificacionMarcarLeidaRequest(BaseModel):
    id_notificacion: UUID
