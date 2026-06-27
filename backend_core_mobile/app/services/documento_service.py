# documento_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException, UploadFile
from app.repositories import documento_repository, solicitud_repository
from app.models.documento_model import SolicitudDocumento
from datetime import datetime
import uuid
import os

# Create temporary upload path
UPLOAD_DIR = "d:/appbcp/backend_core_mobile/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def guardar_documento_solicitud(db: Session, id_solicitud: uuid.UUID, tipo_documento: str, file: UploadFile) -> SolicitudDocumento:
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    # Save file locally for simulation
    file_ext = os.path.splitext(file.filename)[1] if file.filename else ".jpg"
    safe_filename = f"{id_solicitud}_{tipo_documento}_{uuid.uuid4().hex[:6]}{file_ext}"
    local_path = os.path.join(UPLOAD_DIR, safe_filename)

    try:
        with open(local_path, "wb") as f:
            f.write(file.file.read())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"No se pudo guardar el archivo físicamente: {str(e)}")

    # Create record
    doc = SolicitudDocumento(
        id_documento=uuid.uuid4(),
        id_solicitud=id_solicitud,
        tipo_documento=tipo_documento,
        nombre_archivo=file.filename or safe_filename,
        storage_path=local_path,
        url_publica=f"/uploads/{safe_filename}",
        estado_validacion="ACEPTADO",
        created_at=datetime.utcnow()
    )
    
    return documento_repository.create_documento(db, doc)

def registrar_firma_cliente(db: Session, id_solicitud: uuid.UUID, firma_base64: str):
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    
    sol.firma_cliente_base64 = firma_base64
    db.commit()
    return {"message": "Firma registrada exitosamente"}
