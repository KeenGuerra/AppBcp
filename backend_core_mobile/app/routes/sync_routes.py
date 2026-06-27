# sync_routes.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, require_roles
from app.models.usuario_model import Usuario
from app.schemas.sync_schema import SyncOutboxResponse, SyncLogResponse
from app.services import sync_service
from app.repositories import sync_repository
from typing import List

router = APIRouter(prefix="/sync", tags=["Sync"])

# Requires Admin or Supervisor role
def get_sync_user(current_user: Usuario = Depends(require_roles(["SUPERVISOR", "ADMIN"]))):
    return current_user

@router.get("/outbox", response_model=List[SyncOutboxResponse])
def get_outbox(current_user: Usuario = Depends(get_sync_user), db: Session = Depends(get_db)):
    # Fetch all outbox events
    return db.query(sync_repository.SyncOutbox).order_by(sync_repository.SyncOutbox.created_at.desc()).all()

@router.post("/procesar")
def procesar_outbox(current_user: Usuario = Depends(get_sync_user), db: Session = Depends(get_db)):
    return sync_service.procesar_outbox(db)

@router.get("/log", response_model=List[SyncLogResponse])
def get_sync_logs(current_user: Usuario = Depends(get_sync_user), db: Session = Depends(get_db)):
    return sync_repository.get_sync_logs(db)
