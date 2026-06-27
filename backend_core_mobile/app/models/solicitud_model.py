# solicitud_model.py
import uuid
import datetime
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Numeric, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database.session import Base

class ProductoCredito(Base):
    __tablename__ = "productos_credito"

    id_producto_credito = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    codigo = Column(String(30), unique=True, nullable=False)
    nombre = Column(String(120), nullable=False)
    tipo = Column(String(50))
    tea_con_seguro = Column(Numeric(5, 2), nullable=False)
    tea_sin_seguro = Column(Numeric(5, 2), nullable=False)
    monto_minimo = Column(Numeric(12, 2), nullable=False)
    monto_maximo = Column(Numeric(12, 2), nullable=False)
    plazo_minimo = Column(Integer, nullable=False)
    plazo_maximo = Column(Integer, nullable=False)
    moneda = Column(String(3), default="PEN")
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True))

class SolicitudCredito(Base):
    __tablename__ = "solicitudes_credito"

    id_solicitud = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    numero_expediente = Column(String(30), unique=True, nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente"), nullable=False)
    id_negocio = Column(UUID(as_uuid=True), ForeignKey("negocios_cliente.id_negocio"), nullable=False)
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor"), nullable=True)
    id_producto_credito = Column(UUID(as_uuid=True), ForeignKey("productos_credito.id_producto_credito"), nullable=False)
    canal_origen = Column(String(30), nullable=False)
    monto_solicitado = Column(Numeric(12, 2), nullable=False)
    monto_aprobado = Column(Numeric(12, 2), nullable=True)
    plazo_meses = Column(Integer, nullable=False)
    moneda = Column(String(3), default="PEN")
    tea_referencial = Column(Numeric(5, 2), nullable=False)
    con_seguro_desgravamen = Column(Boolean, default=True)
    garantia = Column(String(50))
    destino_credito = Column(String)
    cuota_estimada = Column(Numeric(12, 2))
    estado = Column(String(30), nullable=False)
    resultado_preevaluacion = Column(String(30))
    puntaje_preevaluacion = Column(Integer)
    resultado_buro = Column(String(30))
    motivo_rechazo = Column(String)
    condicion_adicional = Column(String)
    firma_cliente_base64 = Column(String)
    lat_captura = Column(Numeric(10, 7))
    lng_captura = Column(Numeric(10, 7))
    pendiente_sync = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    cliente = relationship("Cliente", foreign_keys=[id_cliente])
    negocio = relationship("NegocioCliente", foreign_keys=[id_negocio])
    asesor = relationship("Asesor", foreign_keys=[id_asesor])
    producto = relationship("ProductoCredito", foreign_keys=[id_producto_credito])

class SolicitudNotaInterna(Base):
    __tablename__ = "solicitudes_notas_internas"

    id_nota = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_solicitud = Column(UUID(as_uuid=True), ForeignKey("solicitudes_credito.id_solicitud"), nullable=False)
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor"), nullable=True)
    contenido = Column(String(500), nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.datetime.now)

    solicitud = relationship("SolicitudCredito", foreign_keys=[id_solicitud])
    asesor = relationship("Asesor", foreign_keys=[id_asesor])

