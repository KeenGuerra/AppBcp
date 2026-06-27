# banking_model.py
import uuid
from sqlalchemy import Column, String, Integer, Numeric, DateTime, Date, Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.database.session import Base

class BankingTransaccion(Base):
    __tablename__ = "banking_transacciones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    cuenta_id = Column(String(50), nullable=False)
    tipo = Column(String(30), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    descripcion = Column(Text)
    estado = Column(String(20), default="COMPLETADA")
    created_at = Column(DateTime(timezone=True), default=uuid.uuid4)  # Will be managed by DB or app

class BankingTransferencia(Base):
    __tablename__ = "banking_transferencias"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    cuenta_origen = Column(String(50), nullable=False)
    cuenta_destino = Column(String(50), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    tipo = Column(String(20), default="PROPIA")
    numero_operacion = Column(String(20))
    estado = Column(String(20), default="COMPLETADA")
    fecha_programada = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True))

class BankingTransferenciaProgramada(Base):
    __tablename__ = "banking_transferencias_programadas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    cuenta_origen = Column(String(50), nullable=False)
    cuenta_destino = Column(String(50), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    fecha_programada = Column(Date, nullable=False)
    estado = Column(String(20), default="PENDIENTE")
    created_at = Column(DateTime(timezone=True))

class BankingPagoServicio(Base):
    __tablename__ = "banking_pagos_servicios"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    servicio = Column(String(30), nullable=False)
    referencia = Column(String(100), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    proveedor = Column(String(80))
    operadora = Column(String(80))
    empresa = Column(String(80))
    numero_operacion = Column(String(20))
    estado = Column(String(20), default="PAGADO")
    created_at = Column(DateTime(timezone=True))

class BankingSimulacion(Base):
    __tablename__ = "banking_simulaciones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    plazo = Column(Integer, nullable=False)
    cuota_calculada = Column(Numeric(10, 2), nullable=False)
    tea = Column(Numeric(5, 2), default=38.4)
    tabla_json = Column(JSONB)
    created_at = Column(DateTime(timezone=True))

class BankingSolicitudPrestamo(Base):
    __tablename__ = "banking_solicitudes_prestamo"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    plazo = Column(Integer, nullable=False)
    cuota_calculada = Column(Numeric(10, 2), nullable=False)
    tea = Column(Numeric(5, 2), default=38.4)
    estado = Column(String(20), default="PENDIENTE")
    created_at = Column(DateTime(timezone=True))
    updated_at = Column(DateTime(timezone=True))

    usuario = relationship("Usuario", foreign_keys=[id_usuario])

class BankingPrestamo(Base):
    __tablename__ = "banking_prestamos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    monto_original = Column(Numeric(12, 2), nullable=False)
    saldo_pendiente = Column(Numeric(12, 2), nullable=False)
    cuota_mensual = Column(Numeric(10, 2), nullable=False)
    cuotas_pagadas = Column(Integer, default=0)
    cuotas_restantes = Column(Integer, nullable=False)
    tea = Column(Numeric(5, 2), default=38.4)
    estado = Column(String(20), default="ACTIVO")
    fecha_cancelacion = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True))

    usuario = relationship("Usuario", foreign_keys=[id_usuario])

class BankingPagoPrestamo(Base):
    __tablename__ = "banking_pagos_prestamo"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    prestamo_id = Column(UUID(as_uuid=True), ForeignKey("banking_prestamos.id", ondelete="CASCADE"), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    tipo = Column(String(30), default="CUOTA")
    descuento_aplicado = Column(Numeric(10, 2), default=0.0)
    cuotas_restantes_post = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True))

class BankingAhorro(Base):
    __tablename__ = "banking_ahorros"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    nombre = Column(String(100), nullable=False)
    monto_meta = Column(Numeric(12, 2), nullable=False)
    monto_actual = Column(Numeric(12, 2), default=0.0)
    frecuencia = Column(String(20), nullable=False)
    activo = Column(Boolean, default=True)
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True))

class BankingAbonoAhorro(Base):
    __tablename__ = "banking_abonos_ahorro"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    ahorro_id = Column(UUID(as_uuid=True), ForeignKey("banking_ahorros.id", ondelete="CASCADE"), nullable=False)
    monto = Column(Numeric(10, 2), nullable=False)
    created_at = Column(DateTime(timezone=True))

class BankingMetaAhorro(Base):
    __tablename__ = "banking_metas_ahorro"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    nombre = Column(String(100), nullable=False)
    categoria = Column(String(50), nullable=False)
    monto_objetivo = Column(Numeric(12, 2), nullable=False)
    monto_actual = Column(Numeric(12, 2), default=0.0)
    fecha_limite = Column(Date, nullable=False)
    estado = Column(String(20), default="ACTIVA")
    created_at = Column(DateTime(timezone=True))

class BankingAporteMeta(Base):
    __tablename__ = "banking_aportes_meta"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    meta_id = Column(UUID(as_uuid=True), ForeignKey("banking_metas_ahorro.id", ondelete="CASCADE"), nullable=False)
    monto = Column(Numeric(10, 2), nullable=False)
    created_at = Column(DateTime(timezone=True))

class BankingDepositoPlazo(Base):
    __tablename__ = "banking_depositos_plazo"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    cuenta_origen = Column(String(50), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    plazo_dias = Column(Integer, nullable=False)
    tasa = Column(Numeric(5, 2), nullable=False)
    interes_estimado = Column(Numeric(10, 2), nullable=False)
    monto_final = Column(Numeric(12, 2), nullable=False)
    fecha_inicio = Column(DateTime(timezone=True))
    fecha_vencimiento = Column(DateTime(timezone=True), nullable=False)
    estado = Column(String(20), default="ACTIVO")
    penalidad = Column(Numeric(10, 2), default=0.0)
    monto_retiro = Column(Numeric(12, 2), nullable=True)
    fecha_retiro = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True))

class BankingRecarga(Base):
    __tablename__ = "banking_recargas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    celular_destino = Column(String(12), nullable=False)
    celular_enmascarado = Column(String(12))
    operadora = Column(String(30), nullable=False)
    monto = Column(Numeric(8, 2), nullable=False)
    cuenta_origen = Column(String(50))
    numero_operacion = Column(String(20))
    estado = Column(String(20), default="PROCESADA")
    created_at = Column(DateTime(timezone=True))

class BankingGasto(Base):
    __tablename__ = "banking_gastos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    descripcion = Column(Text, nullable=False)
    monto = Column(Numeric(10, 2), nullable=False)
    categoria = Column(String(50), nullable=False)
    created_at = Column(DateTime(timezone=True))

class BankingPresupuesto(Base):
    __tablename__ = "banking_presupuestos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    categoria = Column(String(50), nullable=False)
    limite = Column(Numeric(10, 2), nullable=False)
    mes = Column(Integer, nullable=False)
    anio = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True))

class BankingComparacionSim(Base):
    __tablename__ = "banking_comparaciones_sim"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    sim1_json = Column(JSONB)
    sim2_json = Column(JSONB)
    sim3_json = Column(JSONB)
    created_at = Column(DateTime(timezone=True))

class BankingSimTasa(Base):
    __tablename__ = "banking_sim_tasas"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    plazo = Column(Integer, nullable=False)
    cuota_tem2 = Column(Numeric(10, 2))
    cuota_tem3 = Column(Numeric(10, 2))
    cuota_tem4 = Column(Numeric(10, 2))
    ahorro_vs_max = Column(Numeric(10, 2))
    created_at = Column(DateTime(timezone=True))

class BankingComprobante(Base):
    __tablename__ = "banking_comprobantes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    tipo = Column(String(50), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    referencia_uuid = Column(UUID(as_uuid=True))
    datos_json = Column(JSONB)
    created_at = Column(DateTime(timezone=True))

class BankingRetiroProgramado(Base):
    __tablename__ = "banking_retiros_programados"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    cuenta_id = Column(String(50), nullable=False)
    monto = Column(Numeric(12, 2), nullable=False)
    fecha_programada = Column(Date, nullable=False)
    estado = Column(String(20), default="PENDIENTE")
    created_at = Column(DateTime(timezone=True))

class BankingReglaAhorro(Base):
    __tablename__ = "banking_reglas_ahorro"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    cuenta_origen = Column(String(50), nullable=False)
    cuenta_destino = Column(String(50), nullable=False)
    porcentaje = Column(Numeric(5, 2), nullable=False)
    activa = Column(Boolean, default=True)
    fecha_creacion = Column(DateTime(timezone=True))

class BankingAhorroAutomaticoLog(Base):
    __tablename__ = "banking_ahorro_automatico_log"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    regla_id = Column(UUID(as_uuid=True), ForeignKey("banking_reglas_ahorro.id", ondelete="CASCADE"), nullable=False)
    monto = Column(Numeric(10, 2), nullable=False)
    fecha = Column(DateTime(timezone=True))
