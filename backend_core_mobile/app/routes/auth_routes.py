# auth_routes.py
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, get_current_user
from app.schemas.auth_schema import LoginRequest, TokenResponse, UsuarioResponse
from app.services import auth_service
from app.models.usuario_model import Usuario

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    return auth_service.login(db, req)

@router.post("/logout")
def logout(current_user: Usuario = Depends(get_current_user)):
    return {"message": "Sesión cerrada correctamente"}

@router.get("/me", response_model=UsuarioResponse)
def me(current_user: Usuario = Depends(get_current_user), db: Session = Depends(get_db)):
    # Fetch user's name
    from app.repositories import cliente_repository, asesor_repository
    nombre = "Colaborador BCP"
    if current_user.rol == "CLIENTE":
        cli = cliente_repository.get_cliente_by_usuario_id(db, current_user.id_usuario)
        if cli:
            nombre = f"{cli.nombres} {cli.apellidos}"
    else:
        ase = asesor_repository.get_asesor_by_usuario_id(db, current_user.id_usuario)
        if ase:
            nombre = f"{ase.nombres} {ase.apellidos}"

    return UsuarioResponse(
        id_usuario=current_user.id_usuario,
        rol=current_user.rol,
        nombre=nombre,
        documento=current_user.documento
    )
