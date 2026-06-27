-- ============================================================
-- SCRIPT COMPLETO BCP MOBILE CORE 360 - PARA SUPABASE SQL EDITOR
-- Proyecto: kawalgwszhtclarijjqg
-- 
-- INSTRUCCIONES:
-- 1. Ir a https://supabase.com/dashboard/project/kawalgwszhtclarijjqg
-- 2. Clic en "SQL Editor" en el menú izquierdo
-- 3. Pegar TODO este script y clic en "Run"
-- ============================================================

-- ============================================================
-- PASO 0: LIMPIAR DATOS ANTERIORES (si ya ejecutaste antes)
-- ============================================================
DO $$
BEGIN
    -- Intentar truncar solo si las tablas existen
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'auditoria_eventos') THEN
        TRUNCATE auditoria_eventos, sync_log, sync_outbox, notificaciones, solicitudes_documentos, 
                 consultas_buro, listas_inhabilitados, visitas_cliente, cartera_diaria, 
                 cr_cronograma_pagos, cr_movimientos, cr_creditos, operaciones_cliente, 
                 tarjetas, cuentas_ahorro, negocios_cliente, clientes, asesores, 
                 productos_credito, usuarios, agencias, creditos_preaprobados, 
                 campanas_activas, alertas_cartera CASCADE;
    END IF;
END $$;

-- ============================================================
-- PASO 1: EXTENSIONES
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- PASO 2: TABLAS BASE - AGENCIAS Y USUARIOS
-- ============================================================
CREATE TABLE IF NOT EXISTS agencias (
    id_agencia UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT,
    distrito VARCHAR(100),
    provincia VARCHAR(100),
    departamento VARCHAR(100),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    documento VARCHAR(15) UNIQUE NOT NULL,
    codigo_empleado VARCHAR(20) UNIQUE NULL,
    correo VARCHAR(120) UNIQUE NULL,
    password_hash TEXT NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('CLIENTE', 'ASESOR', 'SUPERVISOR', 'ADMIN')),
    estado VARCHAR(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'BLOQUEADO', 'INACTIVO')),
    intentos_fallidos INTEGER DEFAULT 0,
    bloqueado_hasta TIMESTAMPTZ NULL,
    ultimo_login TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- PASO 3: CLIENTES, NEGOCIOS Y ASESORES
-- ============================================================
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    id_agencia UUID REFERENCES agencias(id_agencia) ON DELETE SET NULL,
    documento VARCHAR(15) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(120),
    direccion TEXT,
    distrito VARCHAR(100),
    provincia VARCHAR(100),
    departamento VARCHAR(100),
    fecha_nacimiento DATE,
    estado_civil VARCHAR(30),
    ocupacion VARCHAR(100),
    tipo_cliente VARCHAR(30),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS negocios_cliente (
    id_negocio UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    nombre_comercial VARCHAR(150) NOT NULL,
    giro_negocio VARCHAR(100),
    antiguedad_meses INTEGER,
    ingreso_mensual NUMERIC(12,2) DEFAULT 0.00,
    gasto_mensual NUMERIC(12,2) DEFAULT 0.00,
    direccion_negocio TEXT,
    lat_negocio NUMERIC(10,7),
    lng_negocio NUMERIC(10,7),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS asesores (
    id_asesor UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    id_agencia UUID REFERENCES agencias(id_agencia) ON DELETE SET NULL,
    codigo_empleado VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    cargo VARCHAR(80),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- PASO 4: PRODUCTOS Y CUENTAS
-- ============================================================
CREATE TABLE IF NOT EXISTS productos_credito (
    id_producto_credito UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(30) UNIQUE NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    tipo VARCHAR(50),
    tea_con_seguro NUMERIC(5,2) NOT NULL,
    tea_sin_seguro NUMERIC(5,2) NOT NULL,
    monto_minimo NUMERIC(12,2) NOT NULL,
    monto_maximo NUMERIC(12,2) NOT NULL,
    plazo_minimo INTEGER NOT NULL,
    plazo_maximo INTEGER NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cuentas_ahorro (
    id_cuenta UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    numero_cuenta VARCHAR(30) UNIQUE NOT NULL,
    cci VARCHAR(30) UNIQUE NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    saldo_disponible NUMERIC(12,2) DEFAULT 0.00,
    saldo_contable NUMERIC(12,2) DEFAULT 0.00,
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tarjetas (
    id_tarjeta UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    numero_enmascarado VARCHAR(30) NOT NULL,
    tipo_tarjeta VARCHAR(30),
    marca VARCHAR(30),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    fecha_vencimiento DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- PASO 5: SOLICITUDES DE CRÉDITO
-- ============================================================
CREATE TABLE IF NOT EXISTS solicitudes_credito (
    id_solicitud UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_expediente VARCHAR(30) UNIQUE NOT NULL,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    id_negocio UUID REFERENCES negocios_cliente(id_negocio) ON DELETE CASCADE,
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE SET NULL,
    id_producto_credito UUID REFERENCES productos_credito(id_producto_credito) ON DELETE CASCADE,
    canal_origen VARCHAR(30) NOT NULL CHECK (canal_origen IN ('CLIENTE', 'ASESOR')),
    monto_solicitado NUMERIC(12,2) NOT NULL,
    monto_aprobado NUMERIC(12,2),
    plazo_meses INTEGER NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    tea_referencial NUMERIC(5,2) NOT NULL,
    con_seguro_desgravamen BOOLEAN NOT NULL DEFAULT TRUE,
    garantia VARCHAR(50),
    destino_credito TEXT,
    cuota_estimada NUMERIC(12,2),
    estado VARCHAR(30) NOT NULL CHECK (estado IN (
        'BORRADOR', 'ENVIADO', 'RECIBIDO_COMITE', 'EN_EVALUACION', 
        'APROBADO', 'CONDICIONADO', 'RECHAZADO', 'DESEMBOLSADO'
    )),
    resultado_preevaluacion VARCHAR(30),
    puntaje_preevaluacion INTEGER,
    resultado_buro VARCHAR(30),
    motivo_rechazo TEXT,
    condicion_adicional TEXT,
    firma_cliente_base64 TEXT,
    lat_captura NUMERIC(10,7),
    lng_captura NUMERIC(10,7),
    pendiente_sync BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- PASO 6: CARTERA Y VISITAS
-- ============================================================
CREATE TABLE IF NOT EXISTS cartera_diaria (
    id_cartera UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    id_solicitud UUID REFERENCES solicitudes_credito(id_solicitud) ON DELETE SET NULL,
    fecha_asignacion DATE NOT NULL,
    tipo_gestion VARCHAR(50) NOT NULL CHECK (tipo_gestion IN (
        'NUEVA_SOLICITUD', 'RENOVACION', 'AMPLIACION', 
        'SEGUIMIENTO', 'RECUPERACION_MORA', 'DESERTOR'
    )),
    prioridad VARCHAR(20) NOT NULL,
    score_prioridad INTEGER DEFAULT 0,
    estado_visita VARCHAR(30) DEFAULT 'PENDIENTE',
    resultado_visita VARCHAR(50),
    observacion_visita TEXT,
    lat_visita NUMERIC(10,7),
    lng_visita NUMERIC(10,7),
    timestamp_visita TIMESTAMPTZ,
    pendiente_sync BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS visitas_cliente (
    id_visita UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cartera UUID REFERENCES cartera_diaria(id_cartera) ON DELETE CASCADE,
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    resultado VARCHAR(50) NOT NULL,
    observacion TEXT,
    lat NUMERIC(10,7) NOT NULL,
    lng NUMERIC(10,7) NOT NULL,
    fecha_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS listas_inhabilitados (
    id_lista UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    documento VARCHAR(15) UNIQUE NOT NULL,
    motivo TEXT NOT NULL,
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS consultas_buro (
    id_consulta UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_solicitud UUID REFERENCES solicitudes_credito(id_solicitud) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    documento VARCHAR(15) NOT NULL,
    calificacion VARCHAR(30) NOT NULL,
    entidades_deuda INTEGER DEFAULT 0,
    deuda_total NUMERIC(12,2) DEFAULT 0.00,
    mayor_mora_dias INTEGER DEFAULT 0,
    esta_inhabilitado BOOLEAN DEFAULT FALSE,
    resultado VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- PASO 7: CRÉDITOS, CRONOGRAMA Y MOVIMIENTOS
-- ============================================================
CREATE TABLE IF NOT EXISTS cr_creditos (
    id_credito UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_solicitud UUID REFERENCES solicitudes_credito(id_solicitud) ON DELETE SET NULL,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    numero_credito VARCHAR(30) UNIQUE NOT NULL,
    producto VARCHAR(120) NOT NULL,
    monto_desembolsado NUMERIC(12,2) NOT NULL,
    saldo_capital NUMERIC(12,2) NOT NULL,
    plazo_meses INTEGER NOT NULL,
    tea NUMERIC(5,2) NOT NULL,
    tem NUMERIC(8,6) NOT NULL,
    cuota_mensual NUMERIC(12,2) NOT NULL,
    fecha_desembolso DATE NOT NULL,
    dia_pago INTEGER NOT NULL,
    estado VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cr_cronograma_pagos (
    id_cuota UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_credito UUID REFERENCES cr_creditos(id_credito) ON DELETE CASCADE,
    numero_cuota INTEGER NOT NULL,
    fecha_pago DATE NOT NULL,
    monto_cuota NUMERIC(12,2) NOT NULL,
    capital NUMERIC(12,2) NOT NULL,
    interes NUMERIC(12,2) NOT NULL,
    saldo NUMERIC(12,2) NOT NULL,
    estado VARCHAR(30) NOT NULL CHECK (estado IN ('PENDIENTE', 'PAGADA', 'VENCIDA', 'PARCIAL')),
    fecha_pago_real DATE,
    monto_pagado NUMERIC(12,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cr_movimientos (
    id_movimiento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    id_cuenta UUID REFERENCES cuentas_ahorro(id_cuenta) ON DELETE SET NULL,
    id_credito UUID REFERENCES cr_creditos(id_credito) ON DELETE SET NULL,
    tipo_movimiento VARCHAR(50) NOT NULL CHECK (tipo_movimiento IN (
        'DESEMBOLSO_CREDITO', 'TRANSFERENCIA', 'PAGO_CUOTA', 
        'DEPOSITO', 'RETIRO', 'AJUSTE'
    )),
    descripcion TEXT,
    monto NUMERIC(12,2) NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    canal VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS operaciones_cliente (
    id_operacion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    tipo_operacion VARCHAR(50) NOT NULL CHECK (tipo_operacion IN (
        'TRANSFERENCIA', 'PAGO_CREDITO', 'PAGO_SERVICIO'
    )),
    cuenta_origen UUID REFERENCES cuentas_ahorro(id_cuenta) ON DELETE SET NULL,
    cuenta_destino VARCHAR(30),
    id_credito UUID REFERENCES cr_creditos(id_credito) ON DELETE SET NULL,
    monto NUMERIC(12,2) NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    descripcion TEXT,
    estado VARCHAR(30) NOT NULL CHECK (estado IN (
        'PENDIENTE', 'PROCESADA', 'RECHAZADA'
    )),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- PASO 8: SYNC, OUTBOX Y AUDITORÍA
-- ============================================================
CREATE TABLE IF NOT EXISTS sync_outbox (
    id_evento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_evento VARCHAR(80) NOT NULL,
    entidad VARCHAR(80) NOT NULL,
    entidad_id UUID NOT NULL,
    payload JSONB NOT NULL,
    estado VARCHAR(30) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'PROCESADO', 'ERROR')),
    intentos INTEGER DEFAULT 0,
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    procesado_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS sync_log (
    id_log UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_evento UUID REFERENCES sync_outbox(id_evento) ON DELETE SET NULL,
    accion VARCHAR(100) NOT NULL,
    resultado VARCHAR(30) NOT NULL,
    detalle TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS auditoria_eventos (
    id_auditoria UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    accion VARCHAR(100) NOT NULL,
    entidad VARCHAR(100) NOT NULL,
    entidad_id UUID,
    ip VARCHAR(80),
    user_agent TEXT,
    detalle JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- PASO 9: NOTIFICACIONES Y DOCUMENTOS
-- ============================================================
CREATE TABLE IF NOT EXISTS notificaciones (
    id_notificacion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    leida BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS solicitudes_documentos (
    id_documento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_solicitud UUID REFERENCES solicitudes_credito(id_solicitud) ON DELETE CASCADE,
    tipo_documento VARCHAR(50) NOT NULL CHECK (tipo_documento IN (
        'DNI_FRENTE', 'DNI_REVERSO', 'SUSTENTO_NEGOCIO', 
        'FOTO_NEGOCIO', 'FOTO_VISITA', 'FIRMA_CLIENTE'
    )),
    nombre_archivo VARCHAR(200) NOT NULL,
    storage_path TEXT NOT NULL,
    url_publica TEXT,
    estado_validacion VARCHAR(30) DEFAULT 'PENDIENTE',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- PASO 10: TABLAS ADICIONALES (HU-13, HU-14, HU-16)
-- ============================================================
CREATE TABLE IF NOT EXISTS creditos_preaprobados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    monto_maximo NUMERIC(12,2),
    plazo_sugerido INTEGER,
    tea_referencial NUMERIC(5,2),
    score_confianza INTEGER,
    nivel_confianza VARCHAR(20),
    vigente BOOLEAN DEFAULT TRUE,
    fecha_vencimiento DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS campanas_activas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    tipo VARCHAR(30),
    monto_oferta NUMERIC(12,2),
    activa BOOLEAN DEFAULT TRUE,
    fecha_vencimiento DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS alertas_cartera (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    tipo VARCHAR(50),
    mensaje TEXT,
    leida BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- PASO 11: TRIGGERS UPDATED_AT
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Crear triggers (ignorar error si ya existen)
DO $$ BEGIN
    CREATE TRIGGER update_usuarios_modtime BEFORE UPDATE ON usuarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_clientes_modtime BEFORE UPDATE ON clientes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_negocios_cliente_modtime BEFORE UPDATE ON negocios_cliente FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_asesores_modtime BEFORE UPDATE ON asesores FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_solicitudes_credito_modtime BEFORE UPDATE ON solicitudes_credito FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_cartera_diaria_modtime BEFORE UPDATE ON cartera_diaria FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_cr_creditos_modtime BEFORE UPDATE ON cr_creditos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TRIGGER update_operaciones_cliente_modtime BEFORE UPDATE ON operaciones_cliente FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================
-- PASO 12: VISTAS DEL DASHBOARD
-- ============================================================
CREATE OR REPLACE VIEW vista_resumen_solicitudes AS
SELECT 
    estado,
    COUNT(*) as total_solicitudes,
    SUM(monto_solicitado) as monto_total_solicitado,
    SUM(monto_aprobado) as monto_total_aprobado
FROM solicitudes_credito
GROUP BY estado;

CREATE OR REPLACE VIEW vista_desempeno_asesores AS
SELECT 
    a.id_asesor,
    a.codigo_empleado,
    a.nombres || ' ' || a.apellidos as nombre_asesor,
    COUNT(s.id_solicitud) as total_solicitudes,
    SUM(CASE WHEN s.estado = 'DESEMBOLSADO' THEN 1 ELSE 0 END) as total_desembolsados,
    SUM(s.monto_solicitado) as monto_solicitado_total,
    SUM(s.monto_aprobado) as monto_aprobado_total
FROM asesores a
LEFT JOIN solicitudes_credito s ON a.id_asesor = s.id_asesor
GROUP BY a.id_asesor, a.codigo_empleado, a.nombres, a.apellidos;

CREATE OR REPLACE VIEW vista_mora_cartera AS
SELECT 
    c.id_credito,
    c.numero_credito,
    cl.nombres || ' ' || cl.apellidos as cliente,
    c.monto_desembolsado,
    c.saldo_capital,
    COUNT(cp.id_cuota) as cuotas_vencidas,
    SUM(cp.monto_cuota) as monto_vencido
FROM cr_creditos c
JOIN clientes cl ON c.id_cliente = cl.id_cliente
LEFT JOIN cr_cronograma_pagos cp ON c.id_credito = cp.id_credito AND cp.estado = 'VENCIDA'
WHERE c.estado = 'VIGENTE'
GROUP BY c.id_credito, c.numero_credito, cl.nombres, cl.apellidos, c.monto_desembolsado, c.saldo_capital;

-- ============================================================
-- PASO 13: ROW LEVEL SECURITY (RLS)
-- Deshabilitado para permitir acceso con la API Key pública
-- ============================================================
ALTER TABLE agencias DISABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE clientes DISABLE ROW LEVEL SECURITY;
ALTER TABLE negocios_cliente DISABLE ROW LEVEL SECURITY;
ALTER TABLE asesores DISABLE ROW LEVEL SECURITY;
ALTER TABLE productos_credito DISABLE ROW LEVEL SECURITY;
ALTER TABLE cuentas_ahorro DISABLE ROW LEVEL SECURITY;
ALTER TABLE tarjetas DISABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_credito DISABLE ROW LEVEL SECURITY;
ALTER TABLE cartera_diaria DISABLE ROW LEVEL SECURITY;
ALTER TABLE visitas_cliente DISABLE ROW LEVEL SECURITY;
ALTER TABLE listas_inhabilitados DISABLE ROW LEVEL SECURITY;
ALTER TABLE consultas_buro DISABLE ROW LEVEL SECURITY;
ALTER TABLE cr_creditos DISABLE ROW LEVEL SECURITY;
ALTER TABLE cr_cronograma_pagos DISABLE ROW LEVEL SECURITY;
ALTER TABLE cr_movimientos DISABLE ROW LEVEL SECURITY;
ALTER TABLE operaciones_cliente DISABLE ROW LEVEL SECURITY;
ALTER TABLE sync_outbox DISABLE ROW LEVEL SECURITY;
ALTER TABLE sync_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE auditoria_eventos DISABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones DISABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_documentos DISABLE ROW LEVEL SECURITY;
ALTER TABLE creditos_preaprobados DISABLE ROW LEVEL SECURITY;
ALTER TABLE campanas_activas DISABLE ROW LEVEL SECURITY;
ALTER TABLE alertas_cartera DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- PASO 14: DATOS DEMO (Contraseña para todos: 123456)
-- ============================================================

-- Hash bcrypt de '123456'
-- $2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe

-- Agencias
INSERT INTO agencias (id_agencia, codigo, nombre, direccion, distrito, provincia, departamento, estado) VALUES
('d0000000-0000-0000-0000-000000000001', 'AG001', 'Lima Centro', 'Av. Tacna 456', 'Lima', 'Lima', 'Lima', 'ACTIVO'),
('d0000000-0000-0000-0000-000000000002', 'AG002', 'Miraflores', 'Av. Larco 789', 'Miraflores', 'Lima', 'Lima', 'ACTIVO');

-- Usuarios Staff (Admin, Supervisor, Asesores)
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES
('a0000000-0000-0000-0000-000000000001', '00000001', 'ADM001', 'admin@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'ADMIN', 'ACTIVO'),
('a0000000-0000-0000-0000-000000000002', '00000002', 'SUP001', 'supervisor@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'SUPERVISOR', 'ACTIVO'),
('a0000000-0000-0000-0000-000000000003', '00000003', 'A001', 'advisor1@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'ASESOR', 'ACTIVO'),
('a0000000-0000-0000-0000-000000000004', '00000004', 'A002', 'advisor2@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'ASESOR', 'ACTIVO'),
('a0000000-0000-0000-0000-000000000005', '00000005', 'A003', 'advisor3@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'ASESOR', 'ACTIVO');

-- Asesores
INSERT INTO asesores (id_asesor, id_usuario, id_agencia, codigo_empleado, nombres, apellidos, telefono, cargo, estado) VALUES
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000001', 'A001', 'Roberto', 'Gomez', '999888771', 'Asesor Microfinanzas I', 'ACTIVO'),
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000001', 'A002', 'Maria', 'Sanches', '999888772', 'Asesor Microfinanzas II', 'ACTIVO'),
('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000002', 'A003', 'Carlos', 'Torres', '999888773', 'Asesor de Negocios Senior', 'ACTIVO');

-- Productos de Crédito
INSERT INTO productos_credito (id_producto_credito, codigo, nombre, tipo, tea_con_seguro, tea_sin_seguro, monto_minimo, monto_maximo, plazo_minimo, plazo_maximo, moneda, estado) VALUES
('f0000000-0000-0000-0000-000000000001', 'PROD_MICRO_SOL', 'Crédito Negocio Soles', 'MICROEMPRESA', 25.50, 23.00, 500.00, 20000.00, 6, 24, 'PEN', 'ACTIVO'),
('f0000000-0000-0000-0000-000000000002', 'PROD_CONSUMO_SOL', 'Crédito Consumo Personal', 'CONSUMO', 45.00, 42.00, 1000.00, 50000.00, 12, 48, 'PEN', 'ACTIVO');

-- Listas de inhabilitados
INSERT INTO listas_inhabilitados (documento, motivo, estado) VALUES
('40118129', 'Registrado en central de riesgos penal', 'ACTIVO'),
('40118139', 'Historial de fraude financiero', 'ACTIVO');

-- ============================================================
-- 30 Clientes con sus perfiles, cuentas, tarjetas y solicitudes
-- ============================================================
DO $$
DECLARE
    i INT;
    u_id UUID;
    c_id UUID;
    n_id UUID;
    doc_val VARCHAR(15);
    as_id UUID;
    ag_id UUID;
    prod_id UUID := 'f0000000-0000-0000-0000-000000000001';
    sol_id UUID;

    nombres_arr TEXT[] := ARRAY['Juan Carlos', 'María Rosa', 'Luis Alberto', 'Ana Beatriz', 'José Antonio', 'Carmen Julia', 'Jorge Luis', 'Laura Elena', 'David Alejandro', 'Silvia Patricia', 'Carlos Eduardo', 'Patricia Inés', 'Manuel Enrique', 'Gloria Mercedes', 'Fernando José', 'Teresa de Jesús', 'Miguel Ángel', 'Juana María', 'Roberto Carlos', 'Elizabeth Sarela', 'Ricardo Alfredo', 'Yolanda Beatriz', 'Julio César', 'Victoria Julia', 'Hugo Hernán', 'Rosa Luz', 'Walter Oswaldo', 'Clara Isabel', 'Oscar Eduardo', 'Sofía Raquel'];
    apellidos_arr TEXT[] := ARRAY['Quispe Mamani', 'Flores Huamán', 'Sánchez Rodríguez', 'García Rojas', 'Díaz Torres', 'Ramírez Condori', 'Espinoza Quispe', 'Vásquez Chávez', 'Alvarado Ramos', 'Torres Mendoza', 'Rojas Vargas', 'Castro Quispe', 'Morales Flores', 'Gutiérrez Cárdenas', 'Pérez Ortiz', 'Romero Huamán', 'Chávez Palomino', 'Silva Huamaní', 'Ramos Castillo', 'Herrera Rivera', 'Medina Poma', 'Vargas Machuca', 'Castro Mendoza', 'Mendoza Ramos', 'Fernández Quispe', 'Guzmán Torres', 'Salazar Arenas', 'Cruz Solano', 'Villanueva Vega', 'Reyes Maldonado'];
    negocios_arr TEXT[] := ARRAY['Bodega San José', 'Librería El Rápido', 'Restaurante Las Flores', 'Panadería La Unión', 'Farmacia Santa María', 'Taller Mecánico El Sol', 'Ferretería El Progreso', 'Bazar y Regalos Arcoíris', 'Peluquería Fashion', 'Zapatería El Paso', 'Minimarket Los Andes', 'Sastrería Elegante', 'Joyería El Brillo', 'Óptica Ver Bien', 'Pastelería Dulce Hogar', 'Bodega La Economista', 'Librería César Vallejo', 'Restaurante Sabor Peruano', 'Panadería Don Bosco', 'Botica Popular', 'Llantería El Veloz', 'Ferretería La Construcción', 'Bazar El Ofertón', 'Salón de Belleza Linda', 'Zapatería Calza Fino', 'Market El Caserito', 'Confecciones Unidas', 'Joyería Fina', 'Óptica Santa Lucía', 'Pastelería Gourmet'];
    giros_arr TEXT[] := ARRAY['Bodega Abarrotes', 'Librería y Papelería', 'Restaurante y Comidas', 'Panadería y Pastelería', 'Farmacia y Botica', 'Taller Mecánico', 'Ferretería', 'Bazar', 'Peluquería y Estética', 'Zapatería', 'Minimarket', 'Sastrería', 'Joyería', 'Óptica', 'Pastelería', 'Bodega Abarrotes', 'Librería y Papelería', 'Restaurante y Comidas', 'Panadería y Pastelería', 'Farmacia y Botica', 'Taller Mecánico', 'Ferretería', 'Bazar', 'Peluquería y Estética', 'Zapatería', 'Minimarket', 'Sastrería', 'Joyería', 'Óptica', 'Pastelería'];
BEGIN
    FOR i IN 1..30 LOOP
        -- Seleccionar asesor y agencia secuencialmente
        IF i <= 10 THEN
            as_id := 'b0000000-0000-0000-0000-000000000001';
            ag_id := 'd0000000-0000-0000-0000-000000000001';
        ELSIF i <= 20 THEN
            as_id := 'b0000000-0000-0000-0000-000000000002';
            ag_id := 'd0000000-0000-0000-0000-000000000001';
        ELSE
            as_id := 'b0000000-0000-0000-0000-000000000003';
            ag_id := 'd0000000-0000-0000-0000-000000000002';
        END IF;

        doc_val := '401181' || LPAD(i::text, 2, '0');

        -- Insertar Usuario
        u_id := gen_random_uuid();
        INSERT INTO usuarios (id_usuario, documento, correo, password_hash, rol, estado)
        VALUES (u_id, doc_val, 'cliente' || i || '@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'CLIENTE', 'ACTIVO');

        -- Insertar Cliente
        c_id := gen_random_uuid();
        INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado)
        VALUES (c_id, u_id, ag_id, doc_val, nombres_arr[i], apellidos_arr[i], '9876543' || LPAD(i::text, 2, '0'), 'cliente' || i || '@bcp.com.pe', 'Calle Los Jazmines ' || i || '0', 'San Isidro', 'Lima', 'Lima', '1985-05-15'::DATE - (i * 100), 'SOLTERO', 'Comerciante', 'PN', 'ACTIVO');

        -- Insertar Negocio
        n_id := gen_random_uuid();
        INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado)
        VALUES (n_id, c_id, negocios_arr[i], giros_arr[i], 12 + i, 3500.00 + (i * 100), 1500.00 + (i * 20), 'Av. Central ' || i || '45', -12.046374 + (i * 0.001), -77.042793 + (i * 0.001), 'ACTIVO');

        -- Insertar Cuenta de Ahorro
        INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado)
        VALUES (gen_random_uuid(), c_id, '191-' || LPAD((i*12345)::text, 8, '0') || '-0-' || LPAD(i::text, 2, '0'), '002-191' || LPAD((i*12345)::text, 12, '0') || '00', 'PEN', 100.00 * i, 100.00 * i, 'ACTIVO');

        -- Insertar Tarjeta
        INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento)
        VALUES (gen_random_uuid(), c_id, '4557 **** **** ' || LPAD(i::text, 4, '0'), 'DEBITO', 'VISA', 'ACTIVO', '2030-12-31'::DATE);

        -- Insertar Solicitud de Crédito
        sol_id := gen_random_uuid();
        INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, plazo_meses, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at)
        VALUES (
            sol_id,
            'EXP-' || (20260000 + i),
            c_id,
            n_id,
            as_id,
            prod_id,
            CASE WHEN i % 2 = 0 THEN 'CLIENTE'::VARCHAR ELSE 'ASESOR'::VARCHAR END,
            1000.00 + (i * 500),
            12,
            25.50,
            TRUE,
            'Sola Firma',
            'Compra de mercaderías',
            100.00 + (i * 45),
            CASE 
                WHEN i = 1 THEN 'ENVIADO' 
                WHEN i = 2 THEN 'APROBADO'
                WHEN i = 3 THEN 'RECHAZADO'
                ELSE 'EN_EVALUACION'
            END,
            CASE WHEN i % 3 = 0 THEN 'APTO' ELSE 'REVISAR' END,
            CASE WHEN i % 3 = 0 THEN 85 ELSE 60 END,
            CASE WHEN i % 5 = 0 THEN 'CPP' ELSE 'NORMAL' END,
            CURRENT_TIMESTAMP - (i * INTERVAL '1 hour')
        );

        -- Asignar a Cartera Diaria
        INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita, created_at)
        VALUES (
            gen_random_uuid(),
            as_id,
            c_id,
            sol_id,
            CURRENT_DATE,
            CASE 
                WHEN i % 5 = 0 THEN 'RECUPERACION_MORA'::VARCHAR
                WHEN i % 2 = 0 THEN 'NUEVA_SOLICITUD'::VARCHAR 
                ELSE 'SEGUIMIENTO'::VARCHAR 
            END,
            CASE WHEN i % 3 = 0 THEN 'ALTA'::VARCHAR ELSE 'MEDIA'::VARCHAR END,
            90 - i,
            'PENDIENTE',
            CURRENT_TIMESTAMP
        );

        -- Créditos Preaprobados (HU-13)
        IF i % 3 = 0 THEN
            INSERT INTO creditos_preaprobados (id, id_cliente, monto_maximo, plazo_sugerido, tea_referencial, score_confianza, nivel_confianza, vigente, fecha_vencimiento)
            VALUES (
                gen_random_uuid(),
                c_id,
                15000.00 + (i * 1000),
                18,
                24.50,
                75 + (i % 20),
                CASE WHEN i % 2 = 0 THEN 'ALTO'::VARCHAR ELSE 'MEDIO'::VARCHAR END,
                TRUE,
                CURRENT_DATE + INTERVAL '90 days'
            );
        END IF;

        -- Campañas Activas (HU-16)
        IF i % 6 = 0 THEN
            INSERT INTO campanas_activas (id, id_asesor, id_cliente, tipo, monto_oferta, activa, fecha_vencimiento)
            VALUES (
                gen_random_uuid(),
                as_id,
                c_id,
                CASE WHEN i % 12 = 0 THEN 'RENOVACION'::VARCHAR ELSE 'AMPLIACION'::VARCHAR END,
                25000.00 + (i * 2000),
                TRUE,
                CURRENT_DATE + INTERVAL '60 days'
            );
        END IF;

        -- Alertas de Cartera (HU-14)
        IF i % 5 = 0 THEN
            INSERT INTO alertas_cartera (id, id_asesor, id_cliente, tipo, mensaje, leida)
            VALUES (
                gen_random_uuid(),
                as_id,
                c_id,
                CASE WHEN i % 10 = 0 THEN 'MORA_30D'::VARCHAR ELSE 'PRIMER_DIA_MORA'::VARCHAR END,
                'El cliente ClienteNombre' || i || ' presenta atraso en sus pagos de crédito.',
                FALSE
            );
        END IF;
    END LOOP;
END $$;

-- Notificaciones demo
INSERT INTO notificaciones (id_usuario, titulo, mensaje, tipo, leida) VALUES
('a0000000-0000-0000-0000-000000000001', 'Bienvenido al Sistema', 'Hola Admin, bienvenido al BCP Mobile Core 360.', 'INFORMATIVA', false),
((SELECT id_usuario FROM usuarios WHERE documento='40118120'), 'Bienvenido Cliente BCP', 'Has iniciado sesión con éxito en tu Banca Móvil.', 'INFORMATIVA', false);

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================
SELECT 
    'agencias' as tabla, COUNT(*) as registros FROM agencias
UNION ALL SELECT 'usuarios', COUNT(*) FROM usuarios
UNION ALL SELECT 'asesores', COUNT(*) FROM asesores
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'productos_credito', COUNT(*) FROM productos_credito
UNION ALL SELECT 'cuentas_ahorro', COUNT(*) FROM cuentas_ahorro
UNION ALL SELECT 'tarjetas', COUNT(*) FROM tarjetas
UNION ALL SELECT 'solicitudes_credito', COUNT(*) FROM solicitudes_credito
UNION ALL SELECT 'cartera_diaria', COUNT(*) FROM cartera_diaria
UNION ALL SELECT 'creditos_preaprobados', COUNT(*) FROM creditos_preaprobados
UNION ALL SELECT 'campanas_activas', COUNT(*) FROM campanas_activas
UNION ALL SELECT 'alertas_cartera', COUNT(*) FROM alertas_cartera
UNION ALL SELECT 'notificaciones', COUNT(*) FROM notificaciones
ORDER BY tabla;

-- ============================================================
-- FIN DEL SCRIPT
-- Si todo salió bien, deberías ver los conteos de registros arriba
-- ============================================================
