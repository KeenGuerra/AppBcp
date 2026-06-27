-- 12_schema_missing_tables.sql

-- creditos_preaprobados (HU-13, RF-33)
CREATE TABLE IF NOT EXISTS creditos_preaprobados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    monto_maximo NUMERIC(12,2),
    plazo_sugerido INTEGER,
    tea_referencial NUMERIC(5,2),
    score_confianza INTEGER,  -- 0-100
    nivel_confianza VARCHAR(20), -- ALTO/MEDIO/BAJO
    vigente BOOLEAN DEFAULT TRUE,
    fecha_vencimiento DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- campanas_activas (HU-16, RF-40)
CREATE TABLE IF NOT EXISTS campanas_activas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    tipo VARCHAR(30), -- RENOVACION/AMPLIACION/PRODUCTO_PARALELO
    monto_oferta NUMERIC(12,2),
    activa BOOLEAN DEFAULT TRUE,
    fecha_vencimiento DATE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- alertas_cartera (HU-14, RF-35)
CREATE TABLE IF NOT EXISTS alertas_cartera (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    tipo VARCHAR(50), -- PRIMER_DIA_MORA/MORA_30D/MORA_60D/PAGO_PARCIAL/PAGO_TOTAL
    mensaje TEXT,
    leida BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);
