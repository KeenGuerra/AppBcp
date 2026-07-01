# cliente_routes.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.dependencies import get_db, require_roles
from app.models.usuario_model import Usuario
from app.schemas.cliente_schema import ClienteResponse
from app.schemas.cuenta_schema import CuentaAhorroResponse, TarjetaResponse, TransferenciaRequest, PagoCreditoRequest
from app.schemas.credito_schema import CreditoResponse
from app.schemas.cronograma_schema import CronogramaPagoResponse
from app.schemas.movimiento_schema import MovimientoResponse
from app.schemas.solicitud_schema import SolicitudCreditoResponse, SolicitudCreditoCreate
from app.services import cliente_service, cuenta_service, credito_service, cronograma_service, movimiento_service, solicitud_service, notificacion_service
from typing import List
import uuid

router = APIRouter(prefix="/cliente", tags=["Cliente"])

# Dependency shortcut for Client Role
def get_client(current_user: Usuario = Depends(require_roles(["CLIENTE"]))):
    return current_user

@router.get("/perfil", response_model=ClienteResponse)
def get_perfil(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    return cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)

@router.get("/posicion")
def get_posicion(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    return cliente_service.get_posicion_cliente(db, cli.id_cliente)


@router.get("/cuentas", response_model=List[CuentaAhorroResponse])
def get_cuentas(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    return cuenta_service.get_cuentas_by_cliente_id(db, cli.id_cliente)

@router.get("/tarjetas", response_model=List[TarjetaResponse])
def get_tarjetas(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    return cuenta_service.get_tarjetas_by_cliente_id(db, cli.id_cliente)

@router.get("/movimientos", response_model=List[MovimientoResponse])
def get_movimientos(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    return movimiento_service.get_movimientos_by_cliente_id(db, cli.id_cliente)

@router.get("/creditos", response_model=List[CreditoResponse])
def get_creditos(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    return credito_service.get_creditos_by_cliente_id(db, cli.id_cliente)

@router.get("/creditos/{id_credito}", response_model=CreditoResponse)
def get_credito(id_credito: uuid.UUID, current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    credito = credito_service.get_credito_by_id(db, id_credito)
    if not credito or credito.id_cliente != cli.id_cliente:
        raise HTTPException(status_code=404, detail="Crédito no encontrado")
    return credito

@router.get("/creditos/{id_credito}/cronograma", response_model=List[CronogramaPagoResponse])
def get_cronograma(id_credito: uuid.UUID, current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    credito = credito_service.get_credito_by_id(db, id_credito)
    if not credito or credito.id_cliente != cli.id_cliente:
        raise HTTPException(status_code=404, detail="Crédito no encontrado")
    return cronograma_service.get_cronograma_by_credito_id(db, id_credito)

@router.get("/notificaciones")
def get_notificaciones(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    notifs = notificacion_service.get_notificaciones_by_usuario_id(db, current_user.id_usuario)
    return [
        {
            "id_notificacion": str(n.id_notificacion),
            "id_usuario": str(n.id_usuario),
            "titulo": n.titulo,
            "mensaje": n.mensaje,
            "tipo": n.tipo,
            "leida": n.leida,
            "created_at": n.created_at.isoformat() if hasattr(n.created_at, 'isoformat') else n.created_at
        }
        for n in notifs
    ]

@router.get("/negocios")
def get_negocios(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    from app.models.cliente_model import NegocioCliente
    negocios = db.query(NegocioCliente).filter(NegocioCliente.id_cliente == cli.id_cliente).all()
    return [
        {
            "id_negocio": str(n.id_negocio),
            "nombre_comercial": n.nombre_comercial,
            "giro_negocio": n.giro_negocio,
            "ingreso_mensual": float(n.ingreso_mensual) if n.ingreso_mensual else 0.0,
            "gasto_mensual": float(n.gasto_mensual) if n.gasto_mensual else 0.0,
        }
        for n in negocios
    ]

@router.get("/productos-credito")
def get_productos_credito(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    from app.repositories import solicitud_repository
    productos = solicitud_repository.get_productos(db)
    return [
        {
            "id_producto_credito": str(p.id_producto_credito),
            "codigo": p.codigo,
            "nombre": p.nombre,
            "monto_minimo": float(p.monto_minimo),
            "monto_maximo": float(p.monto_maximo),
        }
        for p in productos
    ]

@router.post("/solicitudes", response_model=SolicitudCreditoResponse)
def crear_solicitud(req: SolicitudCreditoCreate, current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    return solicitud_service.crear_solicitud_cliente(db, current_user.id_usuario, req)

@router.get("/solicitudes", response_model=List[SolicitudCreditoResponse])
def get_solicitudes(current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    from app.repositories import solicitud_repository
    return solicitud_repository.get_solicitudes_by_cliente_id(db, cli.id_cliente)

@router.get("/solicitudes/{id_solicitud}", response_model=SolicitudCreditoResponse)
def get_solicitud(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    from app.repositories import solicitud_repository
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_cliente != cli.id_cliente:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    return sol

@router.post("/operaciones/transferencia")
def transferir(req: TransferenciaRequest, current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    cuenta_service.transferir(db, cli.id_cliente, req)
    return {"message": "Transferencia procesada correctamente"}

@router.post("/operaciones/pago-credito")
def pagar_credito(req: PagoCreditoRequest, current_user: Usuario = Depends(get_client), db: Session = Depends(get_db)):
    cli = cliente_service.get_cliente_by_usuario_id(db, current_user.id_usuario)
    cuenta_service.pagar_cuota_credito(db, cli.id_cliente, req)
    return {"message": "Pago de cuota de crédito procesado correctamente"}
