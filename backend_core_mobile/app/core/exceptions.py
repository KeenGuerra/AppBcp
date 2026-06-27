# exceptions.py
from fastapi import HTTPException, status

CredentialsException = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Credenciales incorrectas o expiradas",
    headers={"WWW-Authenticate": "Bearer"},
)

InactiveUserException = HTTPException(
    status_code=status.HTTP_403_FORBIDDEN,
    detail="Usuario inactivo o bloqueado",
)

PermissionDeniedException = HTTPException(
    status_code=status.HTTP_403_FORBIDDEN,
    detail="No tiene permisos para realizar esta acción",
)

def NotFoundException(entity: str = "Recurso"):
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=f"{entity} no encontrado/a",
    )
