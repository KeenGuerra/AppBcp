# cliente_schema.py
from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID
from datetime import date, datetime
from decimal import Decimal

class NegocioBase(BaseModel):
    nombre_comercial: str
    giro_negocio: Optional[str] = None
    antiguedad_meses: Optional[int] = None
    ingreso_mensual: Optional[Decimal] = None
    gasto_mensual: Optional[Decimal] = None
    direccion_negocio: Optional[str] = None
    lat_negocio: Optional[Decimal] = None
    lng_negocio: Optional[Decimal] = None

class NegocioCreate(NegocioBase):
    pass

class NegocioResponse(NegocioBase):
    id_negocio: UUID
    id_cliente: UUID
    estado: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ClienteBase(BaseModel):
    documento: str
    nombres: str
    apellidos: str
    telefono: Optional[str] = None
    correo: Optional[str] = None
    direccion: Optional[str] = None
    distrito: Optional[str] = None
    provincia: Optional[str] = None
    departamento: Optional[str] = None
    fecha_nacimiento: Optional[date] = None
    estado_civil: Optional[str] = None
    ocupacion: Optional[str] = None
    tipo_cliente: Optional[str] = None

class ClienteCreate(ClienteBase):
    id_agencia: Optional[UUID] = None

class ClienteResponse(ClienteBase):
    id_cliente: UUID
    id_usuario: Optional[UUID] = None
    id_agencia: Optional[UUID] = None
    estado: str
    created_at: datetime
    updated_at: datetime
    negocios: List[NegocioResponse] = []

    class Config:
        from_attributes = True

class FichaClienteResponse(BaseModel):
    cliente: ClienteResponse
    resumen_cuentas: List[dict] = []
    resumen_creditos: List[dict] = []

    class Config:
        from_attributes = True
