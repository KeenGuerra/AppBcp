-- 16_seed_cronogramas_movimientos.sql
-- Genera cronogramas de pago y movimientos para créditos desembolsados
-- Ejecutar después de 10_seed_demo.sql

DO $$
DECLARE
    cred_rec RECORD;
    cuota_num INT;
    saldo_actual NUMERIC(12,2);
    cuota_mensual NUMERIC(12,2);
    interes_mes NUMERIC(12,2);
    capital_mes NUMERIC(12,2);
    fecha_cuota DATE;
    i INT;
BEGIN
    -- Para cada crédito desembolsado, generar cronograma francés
    FOR cred_rec IN
        SELECT c.id_credito, c.monto_desembolsado, c.plazo_meses, c.tem, c.cuota_mensual,
               c.fecha_desembolso, c.dia_pago, c.id_cliente, c.numero_credito
        FROM cr_creditos c
        WHERE c.estado = 'VIGENTE'
    LOOP
        saldo_actual := cred_rec.monto_desembolsado;
        cuota_mensual := cred_rec.cuota_mensual;
        
        FOR cuota_num IN 1..cred_rec.plazo_meses LOOP
            -- Calcular fecha de pago (mes a mes desde desembolso)
            fecha_cuota := (cred_rec.fecha_desembolso + (cuota_num || ' months')::INTERVAL)::DATE;
            
            -- Calcular interes y capital
            interes_mes := ROUND((saldo_actual * cred_rec.tem)::numeric, 2);
            capital_mes := ROUND((cuota_mensual - interes_mes)::numeric, 2);
            
            -- Ajuste en la última cuota
            IF cuota_num = cred_rec.plazo_meses THEN
                capital_mes := saldo_actual;
                cuota_mensual := capital_mes + interes_mes;
            END IF;
            
            -- Determinar estado de la cuota
            -- Si la fecha ya pasó y estamos en el mes actual, marcar como PAGADA o VENCIDA
            IF fecha_cuota < CURRENT_DATE THEN
                IF cuota_num <= 2 THEN
                    -- Simular que las primeras 2 cuotas ya fueron pagadas
                    INSERT INTO cr_cronograma_pagos (
                        id_cuota, id_credito, numero_cuota, fecha_pago,
                        monto_cuota, capital, interes, saldo,
                        estado, fecha_pago_real, monto_pagado
                    ) VALUES (
                        gen_random_uuid(), cred_rec.id_credito, cuota_num, fecha_cuota,
                        cuota_mensual, capital_mes, interes_mes,
                        ROUND((saldo_actual - capital_mes)::numeric, 2),
                        'PAGADA', fecha_cuota + (FLOOR(RANDOM() * 3)::INT || ' days')::INTERVAL,
                        cuota_mensual
                    );
                    saldo_actual := saldo_actual - capital_mes;
                ELSE
                    -- Cuotas vencidas (mora)
                    INSERT INTO cr_cronograma_pagos (
                        id_cuota, id_credito, numero_cuota, fecha_pago,
                        monto_cuota, capital, interes, saldo,
                        estado, fecha_pago_real, monto_pagado
                    ) VALUES (
                        gen_random_uuid(), cred_rec.id_credito, cuota_num, fecha_cuota,
                        cuota_mensual, capital_mes, interes_mes,
                        ROUND((saldo_actual - capital_mes)::numeric, 2),
                        'VENCIDA', NULL, 0
                    );
                    saldo_actual := saldo_actual - capital_mes;
                END IF;
            ELSE
                -- Cuotas futuras: PENDIENTE
                INSERT INTO cr_cronograma_pagos (
                    id_cuota, id_credito, numero_cuota, fecha_pago,
                    monto_cuota, capital, interes, saldo,
                    estado, fecha_pago_real, monto_pagado
                ) VALUES (
                    gen_random_uuid(), cred_rec.id_credito, cuota_num, fecha_cuota,
                    cuota_mensual, capital_mes, interes_mes,
                    ROUND((saldo_actual - capital_mes)::numeric, 2),
                    'PENDIENTE', NULL, 0
                );
                saldo_actual := saldo_actual - capital_mes;
            END IF;
        END LOOP;
    END LOOP;
END $$;

-- ============================================================
-- MOVIMIENTOS ADICIONALES (depósitos, pagos parciales)
-- ============================================================

-- Insertar movimientos de various types para clientes con créditos activos
DO $$
DECLARE
    cli_rec RECORD;
    mov_count INT;
BEGIN
    FOR cli_rec IN
        SELECT DISTINCT c.id_cliente, cr.numero_credito, cr.id_credito
        FROM cr_creditos cr
        JOIN clientes c ON cr.id_cliente = c.id_cliente
        WHERE cr.estado = 'VIGENTE'
    LOOP
        -- Depósito en cuenta de ahorro
        INSERT INTO cr_movimientos (
            id_movimiento, id_cliente, id_cuenta, tipo_movimiento,
            descripcion, monto, moneda, fecha_movimiento, canal
        ) VALUES (
            gen_random_uuid(), cli_rec.id_cliente, NULL,
            'DEPOSITO',
            'Depósito en efectivo en cuenta de ahorro',
            ROUND((500 + RANDOM() * 2000)::numeric, 2),
            'PEN', CURRENT_TIMESTAMP - INTERVAL '3 days', 'APP'
        );

        -- Pago de cuota de crédito
        INSERT INTO cr_movimientos (
            id_movimiento, id_cliente, id_credito, tipo_movimiento,
            descripcion, monto, moneda, fecha_movimiento, canal
        ) VALUES (
            gen_random_uuid(), cli_rec.id_cliente, cli_rec.id_credito,
            'PAGO_CUOTA',
            'Pago cuota mensual crédito ' || cli_rec.numero_credito,
            ROUND((800 + RANDOM() * 1500)::numeric, 2),
            'PEN', CURRENT_TIMESTAMP - INTERVAL '2 days', 'APP'
        );

        -- Transferencia
        INSERT INTO cr_movimientos (
            id_movimiento, id_cliente, tipo_movimiento,
            descripcion, monto, moneda, fecha_movimiento, canal
        ) VALUES (
            gen_random_uuid(), cli_rec.id_cliente,
            'TRANSFERENCIA',
            'Transferencia a tercero',
            ROUND((100 + RANDOM() * 800)::numeric, 2),
            'PEN', CURRENT_TIMESTAMP - INTERVAL '1 day', 'APP'
        );
    END LOOP;
END $$;

-- ============================================================
-- CONSULTAS BURÓ DEMO
-- ============================================================

INSERT INTO consultas_buro (id_consulta, id_solicitud, id_cliente, documento, calificacion, entidades_deuda, deuda_total, mayor_mora_dias, esta_inhabilitado, resultado)
SELECT
    gen_random_uuid(),
    s.id_solicitud,
    s.id_cliente,
    cl.documento,
    CASE
        WHEN cl.documento::text LIKE '%1' OR cl.documento::text LIKE '%3' OR cl.documento::text LIKE '%9' OR cl.documento::text LIKE '%0' THEN 'NORMAL'
        WHEN cl.documento::text LIKE '%2' OR cl.documento::text LIKE '%8' THEN 'CPP'
        WHEN cl.documento::text LIKE '%6' THEN 'NORMAL'
        WHEN cl.documento::text LIKE '%4' THEN 'DUDOSO'
        WHEN cl.documento::text LIKE '%5' THEN 'DEFICIENTE'
        ELSE 'NORMAL'
    END,
    FLOOR(RANDOM() * 5 + 1)::INT,
    ROUND((RANDOM() * 50000)::numeric, 2),
    CASE
        WHEN cl.documento::text LIKE '%7' THEN 210
        WHEN cl.documento::text LIKE '%5' THEN FLOOR(RANDOM() * 60 + 30)::INT
        WHEN cl.documento::text LIKE '%4' THEN FLOOR(RANDOM() * 30 + 15)::INT
        ELSE FLOOR(RANDOM() * 10)::INT
    END,
    cl.documento::text IN ('41884037', '41884047', '41884057'),
    CASE
        WHEN cl.documento::text IN ('41884037', '41884047', '41884057') THEN 'PERDIDA'
        WHEN s.estado = 'RECHAZADO' THEN 'RECHAZADO'
        ELSE 'APROBADO'
    END
FROM solicitudes_credito s
JOIN clientes cl ON s.id_cliente = cl.id_cliente
WHERE s.estado NOT IN ('BORRADOR');

-- ============================================================
-- DOCUMENTOS ADJUNTOS DEMO
-- ============================================================

INSERT INTO solicitudes_documentos (id_documento, id_solicitud, tipo_documento, nombre_archivo, storage_path, estado_validacion)
SELECT
    gen_random_uuid(),
    s.id_solicitud,
    'DNI_FRENTE',
    'dni_frente_' || cl.documento || '.jpg',
    'documentos/' || cl.documento || '/dni_frente.jpg',
    'VALIDADO'
FROM solicitudes_credito s
JOIN clientes cl ON s.id_cliente = cl.id_cliente
WHERE s.estado NOT IN ('BORRADOR');

INSERT INTO solicitudes_documentos (id_documento, id_solicitud, tipo_documento, nombre_archivo, storage_path, estado_validacion)
SELECT
    gen_random_uuid(),
    s.id_solicitud,
    'SUSTENTO_NEGOCIO',
    'sustento_negocio_' || cl.documento || '.pdf',
    'documentos/' || cl.documento || '/sustento_negocio.pdf',
    'PENDIENTE'
FROM solicitudes_credito s
JOIN clientes cl ON s.id_cliente = cl.id_cliente
WHERE s.estado IN ('EN_EVALUACION', 'APROBADO', 'DESEMBOLSADO');

-- ============================================================
-- VISITAS CLIENTE DEMO
-- ============================================================

INSERT INTO visitas_cliente (id_visita, id_cartera, id_asesor, id_cliente, resultado, observacion, lat, lng, fecha_hora)
SELECT
    gen_random_uuid(),
    cd.id_cartera,
    cd.id_asesor,
    cd.id_cliente,
    CASE WHEN cd.estado_visita = 'GESTIONADO' THEN 'VISITA_REALIZADA' ELSE 'PENDIENTE' END,
    'Visita de seguimiento al cliente. Negocio operativo.',
    -12.046374 + (RANDOM() * 0.05),
    -77.042793 + (RANDOM() * 0.05),
    CURRENT_TIMESTAMP - (FLOOR(RANDOM() * 5)::INT || ' days')::INTERVAL
FROM cartera_diaria cd
WHERE cd.estado_visita = 'GESTIONADO'
LIMIT 10;
