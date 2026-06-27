# credito_schema.py
from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import date, datetime
from decimal import Decimal

class CreditoResponse(BaseModel):
    id_credito: UUID
    id_solicitud: Optional[UUID] = None
    id_cliente: UUID
    numero_credito: str
    producto: str
    monto_desembolsado: Decimal
    saldo_capital: Decimal
    plazo_meses: int
    tea: Decimal
    tem: Decimal
    cuota_mensual: Decimal
    fecha_desembolso: date
    dia_pago: int
    estado: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
