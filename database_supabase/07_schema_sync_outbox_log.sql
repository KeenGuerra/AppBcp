-- 07_schema_sync_outbox_log.sql

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
    resultado VARCHAR(30) NOT NULL, -- COMPLETO, FALLIDO, etc.
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
