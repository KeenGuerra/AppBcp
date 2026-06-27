# solicitud_schema.py
from pydantic import BaseModel, Field
from typing import Optional, List
from uuid import UUID
from datetime import datetime
from decimal import Decimal
from app.schemas.cliente_schema import ClienteResponse, NegocioResponse

class ProductoCreditoResponse(BaseModel):
    id_producto_credito: UUID
    codigo: str
    nombre: str
    tipo: Optional[str] = None
    tea_con_seguro: Decimal
    tea_sin_seguro: Decimal
    monto_minimo: Decimal
    monto_maximo: Decimal
    plazo_minimo: int
    plazo_maximo: int
    moneda: str
    estado: str
    created_at: datetime

    class Config:
        from_attributes = True

class SolicitudCreditoCreate(BaseModel):
    id_cliente: UUID
    id_negocio: UUID
    id_producto_credito: UUID
    monto_solicitado: Decimal = Field(..., gt=0)
    plazo_meses: int = Field(..., gt=0)
    con_seguro_desgravamen: bool = True
    garantia: Optional[str] = "Sola Firma"
    destino_credito: Optional[str] = None
    lat_captura: Optional[Decimal] = None
    lng_captura: Optional[Decimal] = None
    cliente_nombres: Optional[str] = None
    cliente_apellidos: Optional[str] = None
    cliente_documento: Optional[str] = None

class SolicitudCreditoUpdate(BaseModel):
    monto_solicitado: Optional[Decimal] = None
    plazo_meses: Optional[int] = None
    con_seguro_desgravamen: Optional[bool] = None
    garantia: Optional[str] = None
    destino_credito: Optional[str] = None
    lat_captura: Optional[Decimal] = None
    lng_captura: Optional[Decimal] = None

class SolicitudCreditoResponse(BaseModel):
    id_solicitud: UUID
    numero_expediente: str
    id_cliente: UUID
    id_negocio: UUID
    id_asesor: Optional[UUID] = None
    id_producto_credito: UUID
    canal_origen: str
    monto_solicitado: Decimal
    monto_aprobado: Optional[Decimal] = None
    plazo_meses: int
    moneda: str
    tea_referencial: Decimal
    con_seguro_desgravamen: bool
    garantia: Optional[str] = None
    destino_credito: Optional[str] = None
    cuota_estimada: Optional[Decimal] = None
    estado: str
    resultado_preevaluacion: Optional[str] = None
    puntaje_preevaluacion: Optional[int] = None
    resultado_buro: Optional[str] = None
    motivo_rechazo: Optional[str] = None
    condicion_adicional: Optional[str] = None
    firma_cliente_base64: Optional[str] = None
    lat_captura: Optional[Decimal] = None
    lng_captura: Optional[Decimal] = None
    pendiente_sync: bool
    created_at: datetime
    updated_at: datetime
    cliente: Optional[ClienteResponse] = None
    negocio: Optional[NegocioResponse] = None
    producto: Optional[ProductoCreditoResponse] = None

    class Config:
        from_attributes = True

class PreevaluacionResponse(BaseModel):
    resultado: str # APTO, REVISAR, NO_APTO
    puntaje: int
    capacidad_pago: Decimal
    ratio_cuota: Decimal
    cuota_estimada: Decimal

class BuroResponse(BaseModel):
    documento: str
    calificacion: str # NORMAL, CPP, DEFICIENTE, DUDOSO, PERDIDA
    entidades_deuda: int
    deuda_total: Decimal
    mayor_mora_dias: int
    esta_inhabilitado: bool
    resultado: str # APROBADO, RECHAZADO

class ComiteDecisionRequest(BaseModel):
    comentario: Optional[str] = None
    monto_aprobado: Optional[Decimal] = None
    condicion_adicional: Optional[str] = None
    motivo_rechazo: Optional[str] = None
