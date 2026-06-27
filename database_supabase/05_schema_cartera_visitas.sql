-- 05_schema_cartera_visitas.sql

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
    prioridad VARCHAR(20) NOT NULL, -- ALTA, MEDIA, BAJA
    score_prioridad INTEGER DEFAULT 0,
    estado_visita VARCHAR(30) DEFAULT 'PENDIENTE', -- PENDIENTE, REALIZADA, REPROGRAMADA
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
    calificacion VARCHAR(30) NOT NULL, -- NORMAL, CPP, DEFICIENTE, DUDOSO, PERDIDA
    entidades_deuda INTEGER DEFAULT 0,
    deuda_total NUMERIC(12,2) DEFAULT 0.00,
    mayor_mora_dias INTEGER DEFAULT 0,
    esta_inhabilitado BOOLEAN DEFAULT FALSE,
    resultado VARCHAR(30) NOT NULL, -- APROBADO, RECHAZADO
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
