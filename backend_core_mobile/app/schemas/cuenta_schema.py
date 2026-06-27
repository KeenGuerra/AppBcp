# cuenta_schema.py
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import date, datetime
from decimal import Decimal

class CuentaAhorroResponse(BaseModel):
    id_cuenta: UUID
    id_cliente: UUID
    numero_cuenta: str
    cci: str
    moneda: str
    saldo_disponible: Decimal
    saldo_contable: Decimal
    estado: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class TarjetaResponse(BaseModel):
    id_tarjeta: UUID
    id_cliente: UUID
    numero_enmascarado: str
    tipo_tarjeta: str
    marca: str
    estado: str
    fecha_vencimiento: date
    created_at: datetime

    class Config:
        from_attributes = True

class TransferenciaRequest(BaseModel):
    cuenta_origen_id: UUID
    cuenta_destino_numero: str
    monto: Decimal = Field(..., gt=0)
    descripcion: Optional[str] = None

class PagoCreditoRequest(BaseModel):
    cuenta_origen_id: UUID
    credito_id: UUID
    monto: Decimal = Field(..., gt=0)
    numero_cuota: int
