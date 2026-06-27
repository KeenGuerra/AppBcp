# dependencies.py
from fastapi import Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.exceptions import CredentialsException, PermissionDeniedException
from app.core.security import verify_token

security = HTTPBearer()

def get_db():
    """Dependency que provee una sesion de base de datos (SupabaseSession o SQLAlchemy)"""
    from app.database.session import SessionLocal
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
    db = Depends(get_db)
):
    token = credentials.credentials
    sub = verify_token(token)
    if not sub:
        raise CredentialsException
    
    from app.models.usuario_model import Usuario
    user = db.query(Usuario).filter(Usuario.id_usuario == sub).first()
    if not user:
        raise CredentialsException
    if user.estado != "ACTIVO":
        from app.core.exceptions import InactiveUserException
        raise InactiveUserException
        
    return user

class RoleChecker:
    def __init__(self, allowed_roles: list[str]):
        self.allowed_roles = allowed_roles
        
    def __call__(self, current_user = Depends(get_current_user)):
        if current_user.rol not in self.allowed_roles:
            raise PermissionDeniedException
        return current_user

def require_roles(allowed_roles: list[str]):
    return RoleChecker(allowed_roles)
