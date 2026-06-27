# asesor_schema.py
from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime

class AgenciaResponse(BaseModel):
    id_agencia: UUID
    codigo: str
    nombre: str
    direccion: Optional[str] = None
    distrito: Optional[Optional[str]] = None
    provincia: Optional[Optional[str]] = None
    departamento: Optional[Optional[str]] = None
    estado: str
    created_at: datetime

    class Config:
        from_attributes = True

class AsesorResponse(BaseModel):
    id_asesor: UUID
    id_usuario: Optional[UUID] = None
    id_agencia: Optional[UUID] = None
    codigo_empleado: str
    nombres: str
    apellidos: str
    telefono: Optional[str] = None
    cargo: Optional[str] = None
    estado: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
