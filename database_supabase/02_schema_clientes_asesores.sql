-- 02_schema_clientes_asesores.sql

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
