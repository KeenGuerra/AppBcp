# visita_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException
from app.repositories import visita_repository, cartera_repository, solicitud_repository
from app.models.visita_model import VisitaCliente
from app.schemas.visita_schema import VisitaClienteCreate
from datetime import datetime
import uuid

def registrar_visita(db: Session, id_usuario_asesor: uuid.UUID, req: VisitaClienteCreate) -> VisitaCliente:
    # 1. Verify daily portfolio item
    cart = cartera_repository.get_cartera_by_id(db, req.id_cartera)
    if not cart:
        raise HTTPException(status_code=404, detail="Item de cartera no encontrado")

    # Verify advisor owns portfolio item
    from app.repositories import asesor_repository
    ase = asesor_repository.get_asesor_by_usuario_id(db, id_usuario_asesor)
    if not ase or cart.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=403, detail="No autorizado para registrar visitas en este item de cartera")

    # 2. Create visit
    visita = VisitaCliente(
        id_visita=uuid.uuid4(),
        id_cartera=req.id_cartera,
        id_asesor=ase.id_asesor,
        id_cliente=cart.id_cliente,
        resultado=req.resultado,
        observacion=req.observacion,
        lat=req.lat,
        lng=req.lng,
        fecha_hora=datetime.utcnow(),
        created_at=datetime.utcnow()
    )
    visita_repository.create_visita(db, visita)

    # 3. Update Daily Portfolio
    cart.estado_visita = "REALIZADA"
    cart.resultado_visita = req.resultado
    cart.observacion_visita = req.observacion
    cart.lat_visita = req.lat
    cart.lng_visita = req.lng
    cart.timestamp_visita = datetime.utcnow()

    # 4. Update request status to EN_EVALUACION
    if cart.id_solicitud:
        sol = solicitud_repository.get_solicitud_by_id(db, cart.id_solicitud)
        if sol and sol.estado == "ENVIADO":
            sol.estado = "EN_EVALUACION"

    db.commit()
    db.refresh(visita)
    return visita
