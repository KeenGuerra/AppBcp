# sync_service.py
from sqlalchemy.orm import Session
from app.models.sync_model import SyncOutbox, SyncLog
from app.repositories import sync_repository
from datetime import datetime
from typing import List
import uuid

def encolar_evento_sync(db: Session, tipo_evento: str, entidad: str, entidad_id: uuid.UUID, payload: dict) -> SyncOutbox:
    evento = SyncOutbox(
        id_evento=uuid.uuid4(),
        tipo_evento=tipo_evento,
        entidad=entidad,
        entidad_id=entidad_id,
        payload=payload,
        estado="PENDIENTE",
        intentos=0,
        created_at=datetime.utcnow()
    )
    return sync_repository.create_outbox_event(db, evento)

def procesar_outbox(db: Session) -> dict:
    pendientes = sync_repository.get_outbox_pending(db)
    procesados_count = 0
    errores_count = 0

    for ev in pendientes:
        ev.intentos += 1
        try:
            # Simulate sending payload to external nucleo financiero API
            # For our simulation, we succeed 100% of the time, or simulate occasional error if needed
            # We will mark it as PROCESADO
            ev.estado = "PROCESADO"
            ev.procesado_at = datetime.utcnow()
            ev.error = None
            
            # Create success log
            log = SyncLog(
                id_log=uuid.uuid4(),
                id_evento=ev.id_evento,
                accion=ev.tipo_evento,
                resultado="COMPLETO",
                detalle=f"Sincronizado exitosamente: {ev.entidad} ID {ev.entidad_id}",
                created_at=datetime.utcnow()
            )
            sync_repository.create_sync_log(db, log)
            procesados_count += 1
            
        except Exception as e:
            ev.estado = "ERROR"
            ev.error = str(e)
            
            # Create failure log
            log = SyncLog(
                id_log=uuid.uuid4(),
                id_evento=ev.id_evento,
                accion=ev.tipo_evento,
                resultado="FALLIDO",
                detalle=f"Error al sincronizar: {str(e)}",
                created_at=datetime.utcnow()
            )
            sync_repository.create_sync_log(db, log)
            errores_count += 1
            
        db.commit()

    return {
        "procesados": procesados_count,
        "errores": errores_count,
        "total_evaluado": len(pendientes)
    }

def registrar_auditoria(db: Session, id_usuario: uuid.UUID, accion: str, entidad: str, entidad_id: uuid.UUID, ip: str, user_agent: str, detalle: dict):
    from app.models.auditoria_model import AuditoriaEvento
    aud = AuditoriaEvento(
        id_auditoria=uuid.uuid4(),
        id_usuario=id_usuario,
        accion=accion,
        entidad=entidad,
        entidad_id=entidad_id,
        ip=ip,
        user_agent=user_agent,
        detalle=detalle,
        created_at=datetime.utcnow()
    )
    sync_repository.create_auditoria_evento(db, aud)
