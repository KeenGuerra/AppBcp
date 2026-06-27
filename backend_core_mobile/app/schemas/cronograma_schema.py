# cronograma_schema.py
from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import date, datetime
from decimal import Decimal

class CronogramaPagoResponse(BaseModel):
    id_cuota: UUID
    id_credito: UUID
    numero_cuota: int
    fecha_pago: date
    monto_cuota: Decimal
    capital: Decimal
    interes: Decimal
    saldo: Decimal
    estado: str
    fecha_pago_real: Optional[date] = None
    monto_pagado: Decimal
    created_at: datetime

    class Config:
        from_attributes = True
