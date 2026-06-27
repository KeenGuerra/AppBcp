-- 08_schema_notificaciones_documentos.sql

CREATE TABLE IF NOT EXISTS notificaciones (
    id_notificacion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(50) NOT NULL, -- CREDITO_DESEMBOLSADO, RECORDATORIO_PAGO, INFORMATIVA
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
    estado_validacion VARCHAR(30) DEFAULT 'PENDIENTE', -- PENDIENTE, ACEPTADO, RECHAZADO
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
