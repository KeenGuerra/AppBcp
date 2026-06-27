-- 06_schema_creditos_cronograma_movimientos.sql

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
    estado VARCHAR(30) NOT NULL, -- VIGENTE, CANCELADO, VENCIDO
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
    canal VARCHAR(30) NOT NULL, -- BANCA_MOVIL, WEB, VENTANILLA, AGENTE
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
