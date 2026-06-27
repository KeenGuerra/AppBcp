-- ============================================================
-- BANKING TABLES — BCP Mobile Core 360
-- Persistencia real para operaciones bancarias del cliente
-- Ejecutar en Supabase SQL Editor
-- ============================================================

-- Transacciones (depósitos y retiros simples)
CREATE TABLE IF NOT EXISTS banking_transacciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    cuenta_id VARCHAR(50) NOT NULL,
    tipo VARCHAR(30) NOT NULL CHECK (tipo IN ('DEPOSITO','RETIRO','RETIRO_PLAZO')),
    monto NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    descripcion TEXT,
    estado VARCHAR(20) DEFAULT 'COMPLETADA',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_btx_usuario ON banking_transacciones(id_usuario);
CREATE INDEX IF NOT EXISTS idx_btx_created ON banking_transacciones(created_at DESC);

-- Transferencias
CREATE TABLE IF NOT EXISTS banking_transferencias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    cuenta_origen VARCHAR(50) NOT NULL,
    cuenta_destino VARCHAR(50) NOT NULL,
    monto NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    tipo VARCHAR(20) DEFAULT 'PROPIA' CHECK (tipo IN ('PROPIA','TERCERO')),
    numero_operacion VARCHAR(20),
    estado VARCHAR(20) DEFAULT 'COMPLETADA',
    fecha_programada TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_btf_usuario ON banking_transferencias(id_usuario);

-- Transferencias programadas
CREATE TABLE IF NOT EXISTS banking_transferencias_programadas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    cuenta_origen VARCHAR(50) NOT NULL,
    cuenta_destino VARCHAR(50) NOT NULL,
    monto NUMERIC(12,2) NOT NULL,
    fecha_programada DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE','EJECUTADA','CANCELADA')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Pagos de servicios
CREATE TABLE IF NOT EXISTS banking_pagos_servicios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    servicio VARCHAR(30) NOT NULL,
    referencia VARCHAR(100) NOT NULL,
    monto NUMERIC(12,2) NOT NULL,
    proveedor VARCHAR(80),
    operadora VARCHAR(80),
    empresa VARCHAR(80),
    numero_operacion VARCHAR(20),
    estado VARCHAR(20) DEFAULT 'PAGADO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_bps_usuario ON banking_pagos_servicios(id_usuario);

-- Simulaciones de crédito
CREATE TABLE IF NOT EXISTS banking_simulaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    monto NUMERIC(12,2) NOT NULL,
    plazo INTEGER NOT NULL,
    cuota_calculada NUMERIC(10,2) NOT NULL,
    tea NUMERIC(5,2) DEFAULT 38.4,
    tabla_json JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Solicitudes de préstamo (cliente digital)
CREATE TABLE IF NOT EXISTS banking_solicitudes_prestamo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    monto NUMERIC(12,2) NOT NULL,
    plazo INTEGER NOT NULL,
    cuota_calculada NUMERIC(10,2) NOT NULL,
    tea NUMERIC(5,2) DEFAULT 38.4,
    estado VARCHAR(20) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE','APROBADO','RECHAZADO','DESEMBOLSADO')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_bsp_usuario ON banking_solicitudes_prestamo(id_usuario);
CREATE INDEX IF NOT EXISTS idx_bsp_estado ON banking_solicitudes_prestamo(estado);

-- Préstamos activos (cliente digital)
CREATE TABLE IF NOT EXISTS banking_prestamos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    monto_original NUMERIC(12,2) NOT NULL,
    saldo_pendiente NUMERIC(12,2) NOT NULL,
    cuota_mensual NUMERIC(10,2) NOT NULL,
    cuotas_pagadas INTEGER DEFAULT 0,
    cuotas_restantes INTEGER NOT NULL,
    tea NUMERIC(5,2) DEFAULT 38.4,
    estado VARCHAR(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO','CANCELADO','VENCIDO')),
    fecha_cancelacion TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_bpr_usuario ON banking_prestamos(id_usuario);

-- Pagos de préstamo
CREATE TABLE IF NOT EXISTS banking_pagos_prestamo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    prestamo_id UUID NOT NULL REFERENCES banking_prestamos(id) ON DELETE CASCADE,
    monto NUMERIC(12,2) NOT NULL,
    tipo VARCHAR(30) DEFAULT 'CUOTA' CHECK (tipo IN ('CUOTA','ADELANTO','CANCELACION_ANTICIPADA')),
    descuento_aplicado NUMERIC(10,2) DEFAULT 0,
    cuotas_restantes_post INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Ahorros programados
CREATE TABLE IF NOT EXISTS banking_ahorros (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    monto_meta NUMERIC(12,2) NOT NULL,
    monto_actual NUMERIC(12,2) DEFAULT 0,
    frecuencia VARCHAR(20) NOT NULL CHECK (frecuencia IN ('Diario','Semanal','Mensual')),
    activo BOOLEAN DEFAULT TRUE,
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_bah_usuario ON banking_ahorros(id_usuario);

-- Abonos a ahorro
CREATE TABLE IF NOT EXISTS banking_abonos_ahorro (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    ahorro_id UUID NOT NULL REFERENCES banking_ahorros(id) ON DELETE CASCADE,
    monto NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Metas de ahorro
CREATE TABLE IF NOT EXISTS banking_metas_ahorro (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    monto_objetivo NUMERIC(12,2) NOT NULL,
    monto_actual NUMERIC(12,2) DEFAULT 0,
    fecha_limite DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'ACTIVA' CHECK (estado IN ('ACTIVA','COMPLETADA','CANCELADA')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Aportes a metas
CREATE TABLE IF NOT EXISTS banking_aportes_meta (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    meta_id UUID NOT NULL REFERENCES banking_metas_ahorro(id) ON DELETE CASCADE,
    monto NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Depósitos a plazo fijo
CREATE TABLE IF NOT EXISTS banking_depositos_plazo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    cuenta_origen VARCHAR(50) NOT NULL,
    monto NUMERIC(12,2) NOT NULL,
    plazo_dias INTEGER NOT NULL,
    tasa NUMERIC(5,2) NOT NULL,
    interes_estimado NUMERIC(10,2) NOT NULL,
    monto_final NUMERIC(12,2) NOT NULL,
    fecha_inicio TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento TIMESTAMPTZ NOT NULL,
    estado VARCHAR(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO','RETIRADO','VENCIDO')),
    penalidad NUMERIC(10,2) DEFAULT 0,
    monto_retiro NUMERIC(12,2),
    fecha_retiro TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Recargas de celular
CREATE TABLE IF NOT EXISTS banking_recargas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    celular_destino VARCHAR(12) NOT NULL,
    celular_enmascarado VARCHAR(12),
    operadora VARCHAR(30) NOT NULL,
    monto NUMERIC(8,2) NOT NULL,
    cuenta_origen VARCHAR(50),
    numero_operacion VARCHAR(20),
    estado VARCHAR(20) DEFAULT 'PROCESADA',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Gastos personales
CREATE TABLE IF NOT EXISTS banking_gastos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    descripcion TEXT NOT NULL,
    monto NUMERIC(10,2) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_bg_usuario_mes ON banking_gastos(id_usuario, created_at);

-- Presupuestos
CREATE TABLE IF NOT EXISTS banking_presupuestos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    categoria VARCHAR(50) NOT NULL,
    limite NUMERIC(10,2) NOT NULL,
    mes INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
    anio INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_usuario, categoria, mes, anio)
);

-- Comparaciones de simulaciones
CREATE TABLE IF NOT EXISTS banking_comparaciones_sim (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    sim1_json JSONB,
    sim2_json JSONB,
    sim3_json JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Simulaciones de tasas
CREATE TABLE IF NOT EXISTS banking_sim_tasas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    monto NUMERIC(12,2) NOT NULL,
    plazo INTEGER NOT NULL,
    cuota_tem2 NUMERIC(10,2),
    cuota_tem3 NUMERIC(10,2),
    cuota_tem4 NUMERIC(10,2),
    ahorro_vs_max NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Comprobantes (unificados)
CREATE TABLE IF NOT EXISTS banking_comprobantes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    monto NUMERIC(12,2) NOT NULL,
    referencia_uuid UUID,
    datos_json JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_bcmp_usuario ON banking_comprobantes(id_usuario);

-- Retiros programados
CREATE TABLE IF NOT EXISTS banking_retiros_programados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    cuenta_id VARCHAR(50) NOT NULL,
    monto NUMERIC(12,2) NOT NULL,
    fecha_programada DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'PENDIENTE',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- VISTA: Dashboard admin banking en tiempo real
-- ============================================================
CREATE OR REPLACE VIEW v_banking_dashboard_stats AS
SELECT
    (SELECT COUNT(*) FROM banking_transacciones) AS total_transacciones,
    (SELECT COALESCE(SUM(monto),0) FROM banking_transacciones WHERE tipo='DEPOSITO') AS monto_depositos,
    (SELECT COALESCE(SUM(monto),0) FROM banking_transacciones WHERE tipo='RETIRO') AS monto_retiros,
    (SELECT COUNT(*) FROM banking_transferencias) AS total_transferencias,
    (SELECT COALESCE(SUM(monto),0) FROM banking_transferencias) AS monto_transferencias,
    (SELECT COUNT(*) FROM banking_pagos_servicios) AS total_pagos_servicios,
    (SELECT COALESCE(SUM(monto),0) FROM banking_pagos_servicios) AS monto_pagos_servicios,
    (SELECT COUNT(*) FROM banking_solicitudes_prestamo WHERE estado='PENDIENTE') AS solicitudes_pendientes,
    (SELECT COUNT(*) FROM banking_solicitudes_prestamo WHERE estado='APROBADO') AS solicitudes_aprobadas,
    (SELECT COUNT(*) FROM banking_ahorros WHERE activo=TRUE) AS ahorros_activos,
    (SELECT COUNT(*) FROM banking_recargas) AS total_recargas,
    (SELECT COALESCE(SUM(monto),0) FROM banking_comprobantes) AS monto_total_operado;

-- ============================================================
-- TABLAS ADICIONALES: Reglas de Ahorro
-- ============================================================
CREATE TABLE IF NOT EXISTS banking_reglas_ahorro (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    cuenta_origen VARCHAR(50) NOT NULL,
    cuenta_destino VARCHAR(50) NOT NULL,
    porcentaje NUMERIC(5,2) NOT NULL CHECK (porcentaje BETWEEN 1 AND 30),
    activa BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS banking_ahorro_automatico_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    regla_id UUID NOT NULL REFERENCES banking_reglas_ahorro(id) ON DELETE CASCADE,
    monto NUMERIC(10,2) NOT NULL,
    fecha TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- RLS básico (permitir al usuario ver solo sus propios datos)
-- ============================================================
ALTER TABLE banking_transacciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_transferencias ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_pagos_servicios ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_ahorros ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_metas_ahorro ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_depositos_plazo ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_gastos ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_presupuestos ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_recargas ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_comprobantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_solicitudes_prestamo ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_prestamos ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_reglas_ahorro ENABLE ROW LEVEL SECURITY;
ALTER TABLE banking_ahorro_automatico_log ENABLE ROW LEVEL SECURITY;

-- Service role bypasses RLS, so backend can read/write freely
-- (Already configured via SUPABASE_SERVICE_ROLE_KEY in .env)

