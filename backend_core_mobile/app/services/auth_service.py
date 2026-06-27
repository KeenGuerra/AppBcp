# auth_service.py
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.repositories import usuario_repository
from app.core import security
from app.schemas.auth_schema import LoginRequest, TokenResponse, UsuarioResponse
from app.models.usuario_model import Usuario
from app.repositories import cliente_repository, asesor_repository

def authenticate_user(db: Session, req: LoginRequest) -> Usuario:
    db_user = None
    search_term = req.documento or req.codigo_empleado
    if search_term:
        if "@" in search_term:
            db_user = usuario_repository.get_usuario_by_correo(db, search_term)
        else:
            db_user = usuario_repository.get_usuario_by_documento(db, search_term)
            if not db_user:
                db_user = usuario_repository.get_usuario_by_codigo_empleado(db, search_term)
        
    if not db_user:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")
        
    # 2. Check lock status
    if db_user.estado == "BLOQUEADO":
        if db_user.bloqueado_hasta and datetime.utcnow() > db_user.bloqueado_hasta.replace(tzinfo=None):
            # Unlock
            db_user.estado = "ACTIVO"
            db_user.intentos_fallidos = 0
            db_user.bloqueado_hasta = None
            db.commit()
        else:
            lock_remaining = ""
            if db_user.bloqueado_hasta:
                rem = db_user.bloqueado_hasta.replace(tzinfo=None) - datetime.utcnow()
                lock_remaining = f" por {int(rem.total_seconds() / 60)} minutos más"
            raise HTTPException(status_code=403, detail=f"Usuario bloqueado por excesivos intentos fallidos{lock_remaining}")

    if db_user.estado != "ACTIVO":
        raise HTTPException(status_code=403, detail="Usuario inactivo")

    # 3. Verify password
    is_valid = security.verify_password(req.password, db_user.password_hash)
    if not is_valid:
        # Increment failed attempts
        db_user.intentos_fallidos += 1
        if db_user.intentos_fallidos >= 5:
            db_user.estado = "BLOQUEADO"
            db_user.bloqueado_hasta = datetime.utcnow() + timedelta(minutes=30)
            db.commit()
            raise HTTPException(status_code=403, detail="Usuario bloqueado por 5 intentos fallidos")
        db.commit()
        raise HTTPException(status_code=401, detail="Clave incorrecta")

    # 4. Successful login
    db_user.intentos_fallidos = 0
    db_user.bloqueado_hasta = None
    db_user.ultimo_login = datetime.utcnow()
    db.commit()
    return db_user

def login(db: Session, req: LoginRequest) -> TokenResponse:
    user = authenticate_user(db, req)
    
    # Generate token
    access_token = security.create_access_token(user.id_usuario)
    
    # Get user name
    nombre = "Colaborador BCP"
    if user.rol == "CLIENTE":
        cli = cliente_repository.get_cliente_by_usuario_id(db, user.id_usuario)
        if cli:
            nombre = f"{cli.nombres} {cli.apellidos}"
    else:
        ase = asesor_repository.get_asesor_by_usuario_id(db, user.id_usuario)
        if ase:
            nombre = f"{ase.nombres} {ase.apellidos}"
            
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        usuario=UsuarioResponse(
            id_usuario=user.id_usuario,
            rol=user.rol,
            nombre=nombre,
            documento=user.documento
        )
    )
