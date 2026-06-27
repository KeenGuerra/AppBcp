-- 03_schema_productos_cuentas.sql

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
    tipo_tarjeta VARCHAR(30), -- DEBITO, CREDITO
    marca VARCHAR(30), -- VISA, MASTERCARD
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    fecha_vencimiento DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
