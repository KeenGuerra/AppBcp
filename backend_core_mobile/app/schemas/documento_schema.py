# documento_schema.py
from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime

class SolicitudDocumentoResponse(BaseModel):
    id_documento: UUID
    id_solicitud: UUID
    tipo_documento: str
    nombre_archivo: str
    storage_path: str
    url_publica: Optional[str] = None
    estado_validacion: str
    created_at: datetime

    class Config:
        from_attributes = True
class SolicitudFirmaRequest(BaseModel):
    firma_base64: str
