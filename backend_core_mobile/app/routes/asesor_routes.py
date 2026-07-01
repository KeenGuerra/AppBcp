# asesor_routes.py
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.dependencies import get_db, require_roles
from app.models.usuario_model import Usuario
from app.schemas.cartera_schema import CarteraDiariaResponse
from app.schemas.cliente_schema import FichaClienteResponse
from app.schemas.visita_schema import VisitaClienteResponse, VisitaClienteCreate
from app.schemas.solicitud_schema import SolicitudCreditoResponse, SolicitudCreditoCreate, PreevaluacionResponse, BuroResponse, SolicitudCreditoUpdate
from app.schemas.documento_schema import SolicitudDocumentoResponse, SolicitudFirmaRequest
from app.services import asesor_service, cartera_service, cliente_service, visita_service, solicitud_service, buro_service, documento_service
from app.repositories import solicitud_repository
from typing import List
import uuid

router = APIRouter(prefix="/fventas", tags=["Fuerza de Ventas"])

def get_asesor_user(current_user: Usuario = Depends(require_roles(["ASESOR"]))):
    return current_user

@router.get("/cartera/hoy", response_model=List[CarteraDiariaResponse])
def get_cartera_hoy(current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    return cartera_service.get_cartera_hoy_by_asesor_id(db, ase.id_asesor)

@router.get("/cartera/{id_cartera}", response_model=CarteraDiariaResponse)
def get_cartera_item(id_cartera: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    cart = cartera_service.get_cartera_by_id(db, id_cartera)
    if not cart or cart.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=404, detail="Item de cartera no encontrado")
    return cart

@router.get("/clientes/{id_cliente}/ficha", response_model=FichaClienteResponse)
def get_ficha_cliente(id_cliente: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    # Verify client is assigned or check access
    # For now, return standard ficha
    return cliente_service.get_ficha_cliente(db, id_cliente)

@router.post("/visitas", response_model=VisitaClienteResponse)
def registrar_visita(req: VisitaClienteCreate, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    return visita_service.registrar_visita(db, current_user.id_usuario, req)

@router.post("/solicitudes", response_model=SolicitudCreditoResponse)
def crear_solicitud(req: SolicitudCreditoCreate, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    return solicitud_service.crear_solicitud_asesor(db, current_user.id_usuario, req)

@router.put("/solicitudes/{id_solicitud}", response_model=SolicitudCreditoResponse)
def actualizar_solicitud(id_solicitud: uuid.UUID, req: SolicitudCreditoUpdate, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    
    if req.monto_solicitado is not None:
        sol.monto_solicitado = req.monto_solicitado
    if req.plazo_meses is not None:
        sol.plazo_meses = req.plazo_meses
    if req.con_seguro_desgravamen is not None:
        sol.con_seguro_desgravamen = req.con_seguro_desgravamen
    if req.garantia is not None:
        sol.garantia = req.garantia
    if req.destino_credito is not None:
        sol.destino_credito = req.destino_credito
        
    db.commit()
    db.refresh(sol)
    return sol

@router.post("/solicitudes/{id_solicitud}/preevaluar", response_model=PreevaluacionResponse)
def preevaluar_solicitud(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    # Verify ownership
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    return solicitud_service.preevaluar_solicitud_asesor(db, id_solicitud)

@router.post("/solicitudes/{id_solicitud}/buro", response_model=BuroResponse)
def consultar_buro(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    # Verify ownership
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    return buro_service.consultar_buro(db, id_solicitud)

@router.post("/solicitudes/{id_solicitud}/documentos", response_model=SolicitudDocumentoResponse)
def subir_documento(
    id_solicitud: uuid.UUID,
    tipo_documento: str = Form(...),
    file: UploadFile = File(...),
    current_user: Usuario = Depends(get_asesor_user),
    db: Session = Depends(get_db)
):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    return documento_service.guardar_documento_solicitud(db, id_solicitud, tipo_documento, file)

@router.post("/solicitudes/{id_solicitud}/firma")
def registrar_firma(id_solicitud: uuid.UUID, req: SolicitudFirmaRequest, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    return documento_service.registrar_firma_cliente(db, id_solicitud, req.firma_base64)

@router.post("/solicitudes/{id_solicitud}/enviar-comite", response_model=SolicitudCreditoResponse)
def enviar_comite(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
        
    if sol.estado not in ["BORRADOR", "EN_EVALUACION", "ENVIADO"]:
        raise HTTPException(status_code=400, detail="La solicitud debe estar en estado borrador, en evaluación o enviada para enviarse a comité")

    # Auto preevaluate if not done yet
    if not sol.resultado_preevaluacion:
        try:
            from app.services.solicitud_service import preevaluar_solicitud_asesor
            preevaluar_solicitud_asesor(db, id_solicitud)
        except Exception:
            sol.resultado_preevaluacion = "REVISAR"
            sol.puntaje_preevaluacion = 50

    sol.estado = "ENVIADO"
    db.commit()
    db.refresh(sol)
    return sol

@router.get("/solicitudes", response_model=List[SolicitudCreditoResponse])
def get_solicitudes(current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    return db.query(solicitud_repository.SolicitudCredito).filter(
        solicitud_repository.SolicitudCredito.id_asesor == ase.id_asesor
    ).all()

@router.get("/solicitudes/{id_solicitud}", response_model=SolicitudCreditoResponse)
def get_solicitud(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")
    return sol

from pydantic import BaseModel
from typing import Optional

class CobranzaCreateRequest(BaseModel):
    id_cartera: uuid.UUID
    tipo_gestion: str
    resultado: str
    monto_pagado: Optional[float] = 0.0
    fecha_compromiso: Optional[str] = None
    monto_comprometido: Optional[float] = 0.0
    observaciones: Optional[str] = ""
    lat: float
    lng: float

class NotaInternaCreateRequest(BaseModel):
    contenido: str

@router.get("/clientes/{id_cliente}/posicion")
def get_ficha_posicion_cliente(id_cliente: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    return cliente_service.get_posicion_cliente(db, id_cliente)

@router.get("/mora")
def get_mora_list(current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    from app.models.cartera_model import CarteraDiaria
    from app.models.cliente_model import Cliente
    from app.models.credito_model import Credito
    from app.models.cronograma_model import CronogramaPago
    import datetime

    items = db.query(CarteraDiaria).filter(
        CarteraDiaria.id_asesor == ase.id_asesor,
        CarteraDiaria.tipo_gestion == "RECUPERACION_MORA"
    ).all()

    today = datetime.date.today()
    result = []
    monto_total_vencido = 0.0

    for item in items:
        cliente = item.cliente
        if not cliente:
            continue

        creditos = db.query(Credito).filter(Credito.id_cliente == cliente.id_cliente).all()
        credito_ids = [c.id_credito for c in creditos]
        
        monto_vencido = 0.0
        dias_mora = 0
        
        if credito_ids:
            overdue_cuotas = db.query(CronogramaPago).filter(
                CronogramaPago.id_credito.in_(credito_ids),
                CronogramaPago.estado.in_(["VENCIDA", "PENDIENTE"]),
                CronogramaPago.fecha_pago < today
            ).all()
            
            monto_vencido = sum(float(q.monto_cuota - q.monto_pagado) for q in overdue_cuotas)
            if overdue_cuotas:
                def get_days_diff(q):
                    fp = q.fecha_pago
                    if isinstance(fp, str):
                        try:
                            parts = [int(x) for x in fp.split('T')[0].split('-')]
                            fp_date = datetime.date(parts[0], parts[1], parts[2])
                        except Exception:
                            fp_date = today
                    elif isinstance(fp, datetime.datetime):
                        fp_date = fp.date()
                    elif isinstance(fp, datetime.date):
                        fp_date = fp
                    else:
                        fp_date = today
                    return (today - fp_date).days if fp_date else 0
                dias_mora = max(get_days_diff(q) for q in overdue_cuotas)

        from app.models.visita_model import VisitaCliente
        last_visit = db.query(VisitaCliente).filter(
            VisitaCliente.id_cliente == cliente.id_cliente
        ).order_by(VisitaCliente.fecha_hora.desc()).first()
        fecha_ultimo_contacto = None
        if last_visit and last_visit.fecha_hora:
            fecha_ultimo_contacto = last_visit.fecha_hora.isoformat() if hasattr(last_visit.fecha_hora, 'isoformat') else last_visit.fecha_hora

        result.append({
            "id_cartera": str(item.id_cartera),
            "id_cliente": str(cliente.id_cliente),
            "cliente_nombre": f"{cliente.nombres} {cliente.apellidos}",
            "documento": cliente.documento,
            "dias_mora": dias_mora,
            "monto_vencido": round(monto_vencido, 2),
            "fecha_ultimo_contacto": fecha_ultimo_contacto,
            "prioridad": item.prioridad
        })
        monto_total_vencido += monto_vencido

    result.sort(key=lambda x: x["dias_mora"], reverse=True)

    return {
        "mora_list": result,
        "monto_total_vencido": round(monto_total_vencido, 2)
    }

@router.post("/cobranzas")
def registrar_cobranza(req: CobranzaCreateRequest, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    from app.models.cartera_model import CarteraDiaria
    from app.models.visita_model import VisitaCliente
    import datetime

    cart = db.query(CarteraDiaria).filter(
        CarteraDiaria.id_cartera == req.id_cartera,
        CarteraDiaria.id_asesor == ase.id_asesor
    ).first()
    
    if not cart:
        raise HTTPException(status_code=404, detail="Item de cartera no encontrado o no asignado a este asesor")

    formatted_obs = f"Tipo: {req.tipo_gestion} | Monto Pagado: {req.monto_pagado} | Fecha Compromiso: {req.fecha_compromiso} | Monto Comprometido: {req.monto_comprometido} | Notas: {req.observaciones}"
    
    nueva_visita = VisitaCliente(
        id_visita=uuid.uuid4(),
        id_cartera=req.id_cartera,
        id_asesor=ase.id_asesor,
        id_cliente=cart.id_cliente,
        resultado=req.resultado,
        observacion=formatted_obs,
        lat=req.lat,
        lng=req.lng,
        fecha_hora=datetime.datetime.now(),
        created_at=datetime.datetime.now()
    )
    
    db.add(nueva_visita)
    
    cart.estado_visita = "REALIZADA"
    cart.resultado_visita = req.resultado
    cart.observacion_visita = formatted_obs
    cart.lat_visita = req.lat
    cart.lng_visita = req.lng
    cart.timestamp_visita = datetime.datetime.now()
    
    db.commit()
    
    return {
        "message": "Cobranza registrada correctamente",
        "id_visita": str(nueva_visita.id_visita),
        "resultado": req.resultado,
        "observacion": formatted_obs
    }

@router.get("/solicitudes/{id_solicitud}/notas")
def listar_notas_internas(id_solicitud: uuid.UUID, current_user: Usuario = Depends(require_roles(["ASESOR", "SUPERVISOR", "ADMIN"])), db: Session = Depends(get_db)):
    from app.models.solicitud_model import SolicitudNotaInterna
    notas = db.query(SolicitudNotaInterna).filter(
        SolicitudNotaInterna.id_solicitud == id_solicitud
    ).order_by(SolicitudNotaInterna.created_at.desc()).all()
    
    return [
        {
            "id_nota": str(n.id_nota),
            "id_solicitud": str(n.id_solicitud),
            "id_asesor": str(n.id_asesor) if n.id_asesor else None,
            "asesor_nombre": f"{n.asesor.nombres} {n.asesor.apellidos}" if n.asesor else "Sistema",
            "contenido": n.contenido,
            "created_at": n.created_at.isoformat() if hasattr(n.created_at, 'isoformat') else n.created_at
        }
        for n in notas
    ]

@router.post("/solicitudes/{id_solicitud}/notas")
def agregar_nota_interna(id_solicitud: uuid.UUID, req: NotaInternaCreateRequest, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    from app.models.solicitud_model import SolicitudNotaInterna
    import datetime

    nueva_nota = SolicitudNotaInterna(
        id_nota=uuid.uuid4(),
        id_solicitud=id_solicitud,
        id_asesor=ase.id_asesor,
        contenido=req.contenido,
        created_at=datetime.datetime.now()
    )
    
    db.add(nueva_nota)
    db.commit()
    db.refresh(nueva_nota)
    
    return {
        "id_nota": str(nueva_nota.id_nota),
        "contenido": nueva_nota.contenido,
        "created_at": nueva_nota.created_at.isoformat() if hasattr(nueva_nota.created_at, 'isoformat') else nueva_nota.created_at
    }

class UbicacionRequest(BaseModel):
    lat: float
    lng: float

class ProspectoPreevaluarRequest(BaseModel):
    documento: str
    nombre: str
    monto: float

@router.get("/campanas")
def get_campanas(current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    from app.models.campana_model import CampanaActiva
    import datetime
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    campanas = db.query(CampanaActiva).filter(
        CampanaActiva.id_asesor == ase.id_asesor,
        CampanaActiva.activa == True
    ).all()
    
    today = datetime.date.today()
    res = []
    for c in campanas:
        cli = c.cliente
        vencimiento = c.fecha_vencimiento
        if vencimiento:
            if isinstance(vencimiento, str):
                try:
                    date_str = vencimiento.split('T')[0]
                    parts = [int(x) for x in date_str.split('-')]
                    vencimiento_date = datetime.date(parts[0], parts[1], parts[2])
                except Exception:
                    vencimiento_date = today + datetime.timedelta(days=30)
            elif isinstance(vencimiento, datetime.datetime):
                vencimiento_date = vencimiento.date()
            elif isinstance(vencimiento, datetime.date):
                vencimiento_date = vencimiento
            else:
                vencimiento_date = today + datetime.timedelta(days=30)
            dias_restantes = (vencimiento_date - today).days
        else:
            dias_restantes = 30
        res.append({
            "id_campana": str(c.id),
            "tipo": c.tipo,
            "nombre_cliente": f"{cli.nombres} {cli.apellidos}" if cli else "Cliente desconocido",
            "documento": cli.documento if cli else "",
            "id_cliente": str(c.id_cliente),
            "monto_oferta": float(c.monto_oferta) if c.monto_oferta else 0.0,
            "dias_restantes": max(0, dias_restantes),
            "tea": 25.5
        })
    return res

@router.get("/alertas")
def get_alertas(current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    from app.models.alerta_model import AlertaCartera
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    alertas = db.query(AlertaCartera).filter(
        AlertaCartera.id_asesor == ase.id_asesor,
        AlertaCartera.leida == False
    ).order_by(AlertaCartera.created_at.desc()).all()
    
    return [
        {
            "id": str(a.id),
            "id_asesor": str(a.id_asesor),
            "id_cliente": str(a.id_cliente),
            "cliente_nombre": f"{a.cliente.nombres} {a.cliente.apellidos}" if a.cliente else "Cliente desconocido",
            "tipo": a.tipo,
            "mensaje": a.mensaje,
            "leida": a.leida,
            "created_at": a.created_at.isoformat() if hasattr(a.created_at, 'isoformat') else a.created_at
        }
        for a in alertas
    ]

@router.patch("/alertas/{id}/leida")
def marcar_alerta_leida(id: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    from app.models.alerta_model import AlertaCartera
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    alerta = db.query(AlertaCartera).filter(AlertaCartera.id == id, AlertaCartera.id_asesor == ase.id_asesor).first()
    if not alerta:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")
    alerta.leida = True
    db.commit()
    return {"message": "Alerta marcada como leída"}

@router.get("/clientes/{id_cliente}/preaprobado")
def get_cliente_preaprobado(id_cliente: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    from app.models.preaprobado_model import CreditoPreaprobado
    pre = db.query(CreditoPreaprobado).filter(
        CreditoPreaprobado.id_cliente == id_cliente,
        CreditoPreaprobado.vigente == True
    ).first()
    if not pre:
        raise HTTPException(status_code=404, detail="No cuenta con oferta preaprobada")
    return {
        "id": str(pre.id),
        "id_cliente": str(pre.id_cliente),
        "monto_maximo": float(pre.monto_maximo) if pre.monto_maximo else 0.0,
        "plazo_sugerido": pre.plazo_sugerido,
        "tea_referencial": float(pre.tea_referencial) if pre.tea_referencial else 0.0,
        "score_confianza": pre.score_confianza,
        "nivel_confianza": pre.nivel_confianza,
        "vigente": pre.vigente,
        "fecha_vencimiento": pre.fecha_vencimiento.isoformat() if hasattr(pre.fecha_vencimiento, 'isoformat') else pre.fecha_vencimiento if pre.fecha_vencimiento else None
    }

@router.patch("/cartera/{id_cartera}/ubicacion")
def actualizar_ubicacion_negocio(id_cartera: uuid.UUID, req: UbicacionRequest, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    from app.models.cartera_model import CarteraDiaria
    from app.models.cliente_model import NegocioCliente
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    cart = db.query(CarteraDiaria).filter(CarteraDiaria.id_cartera == id_cartera, CarteraDiaria.id_asesor == ase.id_asesor).first()
    if not cart:
        raise HTTPException(status_code=404, detail="Item de cartera no encontrado")
        
    negocio = db.query(NegocioCliente).filter(NegocioCliente.id_cliente == cart.id_cliente).first()
    if not negocio:
        raise HTTPException(status_code=404, detail="Negocio del cliente no encontrado")
        
    negocio.lat_negocio = req.lat
    negocio.lng_negocio = req.lng
    db.commit()
    return {"message": "Ubicación del negocio actualizada correctamente", "lat": req.lat, "lng": req.lng}

@router.get("/solicitudes/{id_solicitud}/documentos")
def listar_documentos_solicitud(id_solicitud: uuid.UUID, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    from app.models.documento_model import SolicitudDocumento
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
         raise HTTPException(status_code=404, detail="Solicitud no encontrada")
         
    docs = db.query(SolicitudDocumento).filter(SolicitudDocumento.id_solicitud == id_solicitud).all()
    return [
        {
            "id_documento": str(d.id_documento),
            "id_solicitud": str(d.id_solicitud),
            "tipo_documento": d.tipo_documento,
            "nombre_archivo": d.nombre_archivo,
            "url_publica": d.url_publica,
            "estado_validacion": d.estado_validacion,
            "created_at": d.created_at.isoformat() if hasattr(d.created_at, 'isoformat') else d.created_at
        }
        for d in docs
    ]

@router.delete("/solicitudes/{id_solicitud}/documentos/{tipo}")
def eliminar_documento_solicitud(id_solicitud: uuid.UUID, tipo: str, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    from app.models.documento_model import SolicitudDocumento
    ase = asesor_service.get_asesor_by_usuario_id(db, current_user.id_usuario)
    sol = solicitud_repository.get_solicitud_by_id(db, id_solicitud)
    if not sol or sol.id_asesor != ase.id_asesor:
         raise HTTPException(status_code=404, detail="Solicitud no encontrada")
         
    doc = db.query(SolicitudDocumento).filter(
        SolicitudDocumento.id_solicitud == id_solicitud,
        SolicitudDocumento.tipo_documento == tipo
    ).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Documento no encontrado")
        
    db.delete(doc)
    db.commit()
    return {"message": "Documento eliminado correctamente"}

@router.post("/prospecto/preevaluar")
def preevaluar_prospecto(req: ProspectoPreevaluarRequest, current_user: Usuario = Depends(get_asesor_user), db: Session = Depends(get_db)):
    # Check blacklist first
    doc = req.documento
    last_char = doc[-1] if doc else "0"
    last_digit = int(last_char) if last_char.isdigit() else 0
    
    query_blacklisted = db.execute(
        text("SELECT motivo FROM listas_inhabilitados WHERE documento = :doc AND estado = 'ACTIVO'"),
        {"doc": doc}
    ).fetchone()
    
    if query_blacklisted:
        return {
            "resultado": "NO_PROCEDE",
            "puntaje": 20,
            "cuota_estimada": 0.0,
            "motivo": f"Prospecto inhabilitado: {query_blacklisted[0]}"
        }
        
    if last_digit in [8, 9]:
        resultado = "NO_PROCEDE"
        puntaje = 35
    else:
        resultado = "APTO"
        puntaje = 70 + (last_digit * 3)
        
    cuota = req.monto / 12 * 1.15
    return {
        "resultado": resultado,
        "puntaje": puntaje,
        "cuota_estimada": round(cuota, 2)
    }

