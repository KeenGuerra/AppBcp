# auth_schema.py
from pydantic import BaseModel, EmailStr
from typing import Optional
from uuid import UUID

class LoginRequest(BaseModel):
    documento: Optional[str] = None
    codigo_empleado: Optional[str] = None
    password: str

class UsuarioResponse(BaseModel):
    id_usuario: UUID
    rol: str
    nombre: str
    documento: str

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    usuario: UsuarioResponse
