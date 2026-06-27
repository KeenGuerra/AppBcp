-- 01_schema_auth_roles.sql

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
