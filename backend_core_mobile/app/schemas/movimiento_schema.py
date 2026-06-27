# movimiento_schema.py
from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime
from decimal import Decimal

class MovimientoResponse(BaseModel):
    id_movimiento: UUID
    id_cliente: UUID
    id_cuenta: Optional[UUID] = None
    id_credito: Optional[UUID] = None
    tipo_movimiento: str
    descripcion: Optional[str] = None
    monto: Decimal
    moneda: str
    fecha_movimiento: datetime
    canal: str
    created_at: datetime

    class Config:
        from_attributes = True
