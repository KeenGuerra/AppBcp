-- 04_schema_solicitudes_credito.sql

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
