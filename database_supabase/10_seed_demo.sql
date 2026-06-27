-- 10_seed_demo.sql — 30 Casos Crédito Empresarial Microempresa
-- Alineado con el documento de práctica de Banco Andino

-- Clean up existing data (in reverse dependency order)
TRUNCATE auditoria_eventos, sync_log, sync_outbox, notificaciones, solicitudes_documentos, consultas_buro, listas_inhabilitados, visitas_cliente, cartera_diaria, cr_cronograma_pagos, cr_movimientos, cr_creditos, operaciones_cliente, tarjetas, cuentas_ahorro, negocios_cliente, clientes, asesores, productos_credito, usuarios, agencias, creditos_preaprobados, campanas_activas, alertas_cartera CASCADE;

-- Default password hash for '123456'
-- $2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe

-- 1. Insert Agencies
INSERT INTO agencias (id_agencia, codigo, nombre, direccion, distrito, provincia, departamento, estado) VALUES
('d0000000-0000-0000-0000-000000000001', 'AG001', 'Lima Centro', 'Av. Tacna 456', 'Lima', 'Lima', 'Lima', 'ACTIVO'),
('d0000000-0000-0000-0000-000000000002', 'AG002', 'Miraflores', 'Av. Larco 789', 'Miraflores', 'Lima', 'Lima', 'ACTIVO');

-- 2. Insert Users for Staff
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES
('a0000000-0000-0000-0000-000000000001', '00000001', 'ADM001', 'admin@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'ADMIN', 'ACTIVO'),
('a0000000-0000-0000-0000-000000000002', '00000002', 'SUP001', 'supervisor@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'SUPERVISOR', 'ACTIVO'),
('a0000000-0000-0000-0000-000000000003', '00000003', 'A001', 'advisor1@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'ASESOR', 'ACTIVO'),
('a0000000-0000-0000-0000-000000000004', '00000004', 'A002', 'advisor2@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'ASESOR', 'ACTIVO'),
('a0000000-0000-0000-0000-000000000005', '00000005', 'A003', 'advisor3@bcp.com.pe', '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'ASESOR', 'ACTIVO');

-- 3. Insert Advisors details
INSERT INTO asesores (id_asesor, id_usuario, id_agencia, codigo_empleado, nombres, apellidos, telefono, cargo, estado) VALUES
('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000001', 'A001', 'Roberto', 'Gomez Vargas', '999888771', 'Asesor Microfinanzas I', 'ACTIVO'),
('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000001', 'A002', 'Maria', 'Sanches Torres', '999888772', 'Asesor Microfinanzas II', 'ACTIVO'),
('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000002', 'A003', 'Carlos', 'Torres Quispe', '999888773', 'Asesor de Negocios Senior', 'ACTIVO');

-- 4. Insert Credit Products
-- TEA 40.92% con seguro de desgravamen, 43.90% sin seguro
INSERT INTO productos_credito (id_producto_credito, codigo, nombre, tipo, tea_con_seguro, tea_sin_seguro, monto_minimo, monto_maximo, plazo_minimo, plazo_maximo, moneda, estado) VALUES
('f0000000-0000-0000-0000-000000000001', 'CRED_EMP_MICRO', 'Crédito Empresarial Microempresa', 'MICROEMPRESA', 40.92, 43.90, 2000.00, 50000.00, 6, 48, 'PEN', 'ACTIVO'),
('f0000000-0000-0000-0000-000000000002', 'CRED_CONSUMO', 'Crédito Consumo Personal', 'CONSUMO', 45.00, 42.00, 1000.00, 30000.00, 12, 36, 'PEN', 'ACTIVO');

-- 5. Blacklist – Casos 7, 17, 27 (DNI termina en 7)
--    Caso 28 específico: DNI 41884084 → CONDICIONADO por DUDOSO
INSERT INTO listas_inhabilitados (documento, motivo, estado) VALUES
('41884037', 'Registrado en central de riesgos por deuda en mora extrema (+210 días)', 'ACTIVO'),
('41884047', 'Historial de fraude financiero documentado en SBS', 'ACTIVO'),  -- Caso 17 (dni ends in 7)
('41884057', 'Proceso judicial por deuda impaga en múltiples entidades', 'ACTIVO'); -- Caso 27 (dni ends in 7)

-- 6. Insert 30 Clients with realistic data from the 30 practice cases
DO $$
DECLARE
    i INT;
    u_id UUID;
    c_id UUID;
    n_id UUID;
    doc_val VARCHAR(15);
    as_id UUID;
    ag_id UUID;
    prod_id UUID := 'f0000000-0000-0000-0000-000000000001';
    sol_id UUID;
    cred_id UUID;  -- for DESEMBOLSADO cases
    tem_val NUMERIC(8,6);

    -- ▶ 30 DNIs: last digit determines buró outcome (deterministic)
    -- Digit 1=NORMAL, 2=CPP, 3=NORMAL, 4=DUDOSO, 5=DEFICIENTE, 6=NORMAL,
    --       7=PERDIDA(inhab), 8=CPP, 9=NORMAL, 0=NORMAL
    -- DNIs alineados con el documento: 41884031..41884060 (casos 1-30)
    -- Note: we use 41884030+i so that each case has unique last digit pattern
    docs_arr VARCHAR(8)[] := ARRAY[
        '41884031', -- Caso 01 – digit 1 → NORMAL
        '41884032', -- Caso 02 – digit 2 → CPP
        '41884033', -- Caso 03 – digit 3 → NORMAL
        '41884034', -- Caso 04 – digit 4 → DUDOSO
        '41884035', -- Caso 05 – digit 5 → DEFICIENTE
        '41884036', -- Caso 06 – digit 6 → NORMAL
        '41884037', -- Caso 07 – digit 7 → PERDIDA (inhabilitado)
        '41884038', -- Caso 08 – digit 8 → CPP → CONDICIONADO
        '41884039', -- Caso 09 – digit 9 → NORMAL
        '41884040', -- Caso 10 – digit 0 → NORMAL
        '41884041', -- Caso 11 – digit 1 → NORMAL
        '41884042', -- Caso 12 – digit 2 → CPP
        '41884043', -- Caso 13 – digit 3 → NORMAL
        '41884044', -- Caso 14 – digit 4 → DUDOSO
        '41884045', -- Caso 15 – digit 5 → DEFICIENTE
        '41884046', -- Caso 16 – digit 6 → NORMAL
        '41884047', -- Caso 17 – digit 7 → PERDIDA (inhabilitado)
        '41884048', -- Caso 18 – digit 8 → CPP
        '41884049', -- Caso 19 – digit 9 → NORMAL
        '41884050', -- Caso 20 – digit 0 → NORMAL
        '41884051', -- Caso 21 – digit 1 → NORMAL
        '41884052', -- Caso 22 – digit 2 → CPP
        '41884053', -- Caso 23 – digit 3 → NORMAL
        '41884054', -- Caso 24 – digit 4 → DUDOSO
        '41884055', -- Caso 25 – digit 5 → DEFICIENTE
        '41884056', -- Caso 26 – digit 6 → NORMAL
        '41884057', -- Caso 27 – digit 7 → PERDIDA (inhabilitado)
        '41884058', -- Caso 28 – digit 8 → CPP → resultado diferente
        '41884059', -- Caso 29 – digit 9 → NORMAL
        '41884060'  -- Caso 30 – digit 0 → NORMAL
    ];

    nombres_arr TEXT[] := ARRAY[
        'Carlos Enrique',    -- Caso 01
        'Rosa María',        -- Caso 02
        'Juan Pablo',        -- Caso 03
        'Elena Patricia',    -- Caso 04
        'Marcos Antonio',    -- Caso 05
        'Lucía Carmen',      -- Caso 06
        'Pedro Alonso',      -- Caso 07
        'Sandra Beatriz',    -- Caso 08
        'Miguel Ángel',      -- Caso 09
        'Gloria Esperanza',  -- Caso 10
        'David Fernando',    -- Caso 11
        'Ana Cecilia',       -- Caso 12
        'Roberto Luis',      -- Caso 13
        'Isabel Cristina',   -- Caso 14
        'Hernán Eduardo',    -- Caso 15
        'Mariela del Pilar', -- Caso 16
        'Jorge Alberto',     -- Caso 17
        'Carmen Rosa',       -- Caso 18
        'Luis Enrique',      -- Caso 19
        'Yolanda del Carmen',-- Caso 20
        'Fernando José',     -- Caso 21
        'Patricia Inés',     -- Caso 22
        'Rodrigo Alonso',    -- Caso 23
        'Teresa de Jesús',   -- Caso 24
        'Julio César',       -- Caso 25
        'Norma Angélica',    -- Caso 26
        'Hugo Oswaldo',      -- Caso 27
        'Claudia Margarita', -- Caso 28
        'Raúl Arturo',       -- Caso 29
        'Sofía Alejandra'    -- Caso 30
    ];

    apellidos_arr TEXT[] := ARRAY[
        'Mendoza Carrillo',  -- Caso 01
        'Quispe Huallpa',    -- Caso 02
        'Rojas Espinoza',    -- Caso 03
        'Vargas Condori',    -- Caso 04
        'Salinas Paredes',   -- Caso 05
        'Delgado Cárdenas',  -- Caso 06
        'Ramos Vilcahuaman', -- Caso 07
        'Flores Mamani',     -- Caso 08
        'Chávez Peralta',    -- Caso 09
        'Torres Sánchez',    -- Caso 10
        'Castillo Herrera',  -- Caso 11
        'García Pérez',      -- Caso 12
        'Díaz Medina',       -- Caso 13
        'Morales Valdivia',  -- Caso 14
        'Romero Arenas',     -- Caso 15
        'Gutiérrez Ponce',   -- Caso 16
        'Aguilar Benavides', -- Caso 17
        'Castro Olivares',   -- Caso 18
        'Rivera Dávila',     -- Caso 19
        'Jiménez Calderón',  -- Caso 20
        'Palacios Fuentes',  -- Caso 21
        'Campos Noriega',    -- Caso 22
        'Villanueva Meza',   -- Caso 23
        'Ortega Gamboa',     -- Caso 24
        'Reyes Málaga',      -- Caso 25
        'Núñez Palomino',    -- Caso 26
        'Peña Montoya',      -- Caso 27
        'Alvarado Ríos',     -- Caso 28
        'Cabrera Suárez',    -- Caso 29
        'Lozano Tapia'       -- Caso 30
    ];

    -- Correos realistas
    correos_arr TEXT[] := ARRAY[
        'cmendoza31@gmail.com', 'rquispe32@gmail.com', 'jrojas33@gmail.com',
        'evargas34@gmail.com', 'msalinas35@gmail.com', 'ldelgado36@gmail.com',
        'pramos37@gmail.com', 'sflores38@gmail.com', 'mchavez39@gmail.com',
        'gtorres40@gmail.com', 'dcastillo41@gmail.com', 'agarcia42@gmail.com',
        'rdiaz43@gmail.com', 'imorales44@gmail.com', 'hromero45@gmail.com',
        'mgutierrez46@gmail.com', 'jaguilar47@gmail.com', 'ccastro48@gmail.com',
        'lrivera49@gmail.com', 'yjimenez50@gmail.com', 'fpalacios51@gmail.com',
        'pcampos52@gmail.com', 'rvillanueva53@gmail.com', 'tortega54@gmail.com',
        'jreyes55@gmail.com', 'nnunez56@gmail.com', 'hpena57@gmail.com',
        'calvarado58@gmail.com', 'rcabrera59@gmail.com', 'slozano60@gmail.com'
    ];

    telefonos_arr VARCHAR(9)[] := ARRAY[
        '987654321', '987654322', '987654323', '987654324', '987654325',
        '987654326', '987654327', '987654328', '987654329', '987654330',
        '987654331', '987654332', '987654333', '987654334', '987654335',
        '987654336', '987654337', '987654338', '987654339', '987654340',
        '987654341', '987654342', '987654343', '987654344', '987654345',
        '987654346', '987654347', '987654348', '987654349', '987654350'
    ];

    distritos_arr TEXT[] := ARRAY[
        'Los Olivos', 'San Juan de Lurigancho', 'La Victoria', 'Ate', 'Villa María del Triunfo',
        'San Martín de Porres', 'Independencia', 'Villa El Salvador', 'Comas', 'Puente Piedra',
        'Callao', 'San Juan de Miraflores', 'El Agustino', 'Chorrillos', 'Surquillo',
        'Breña', 'Rímac', 'Lince', 'Santa Anita', 'Lurigancho',
        'Carabayllo', 'Lurín', 'Pachacámac', 'San Luis', 'La Molina',
        'Miraflores', 'Barranco', 'Magdalena', 'Jesús María', 'San Borja'
    ];

    -- Negocios realistas
    negocios_arr TEXT[] := ARRAY[
        'Bodega & Abarrotes Mendoza',          -- Caso 01
        'Librería y Útiles Escol. Quispe',     -- Caso 02
        'Rest. Cevichería El Rojas',           -- Caso 03
        'Farmacia Botica San Mateo',           -- Caso 04
        'Confecciones & Telas Salinas',        -- Caso 05
        'Ferretería El Constructor Delgado',   -- Caso 06
        'Peluquería y Estética Ramos',         -- Caso 07
        'Pastelería & Dulces Flores',          -- Caso 08
        'Llantería y Servitec Chávez',         -- Caso 09
        'Minimarket La Torre',                 -- Caso 10
        'Zapatería y Calzado Castillo',        -- Caso 11
        'Bazar El Buen Precio García',         -- Caso 12
        'Taller Mecánico & Lavado Díaz',       -- Caso 13
        'Óptica Santa Clara Morales',          -- Caso 14
        'Sastrería & Costura Romero',          -- Caso 15
        'Joyería y Relojes Gutiérrez',         -- Caso 16
        'Distribuidora Aguilar E.I.R.L.',      -- Caso 17
        'Bodega Los Compadres Castro',         -- Caso 18
        'Papelería & Copias Rivera',           -- Caso 19
        'Pollería Jiménez SAC',                -- Caso 20
        'Abarrotes y Embutidos Palacios',      -- Caso 21
        'Farmacia y Botica Popular Campos',    -- Caso 22
        'Carpintería Fina Villanueva',         -- Caso 23
        'Centro Estético Ortega',              -- Caso 24
        'Vidriería & Aluminio Reyes',          -- Caso 25
        'Imprenta y Diseño Núñez',             -- Caso 26
        'Distribuidora Peña & Hnos.',          -- Caso 27
        'Catering & Eventos Alvarado',         -- Caso 28
        'Consultora Tributaria Cabrera',       -- Caso 29
        'Agencia de Viajes Lozano'             -- Caso 30
    ];

    giros_arr TEXT[] := ARRAY[
        'Bodega Abarrotes', 'Librería y Papelería', 'Restaurante y Comidas', 'Farmacia y Botica',
        'Confecciones y Tejidos', 'Ferretería', 'Peluquería y Estética', 'Pastelería y Dulces',
        'Taller Mecánico', 'Minimarket', 'Zapatería', 'Bazar', 'Taller Mecánico',
        'Óptica', 'Sastrería', 'Joyería', 'Distribuidora', 'Bodega Abarrotes',
        'Librería y Papelería', 'Restaurante y Comidas', 'Abarrotes', 'Farmacia y Botica',
        'Carpintería', 'Centro Estético', 'Vidriería', 'Imprenta', 'Distribuidora',
        'Catering y Eventos', 'Consultoría', 'Agencia de Viajes'
    ];

    -- Ingresos mensuales (ventas brutas del negocio) – en soles
    ingresos_arr NUMERIC[] := ARRAY[
        4800, 6200, 5500, 7800, 3900,
        8500, 6000, 5200, 9200, 4600,
        7100, 6800, 8300, 5900, 4200,
        9800, 5700, 6400, 7600, 5100,
        8900, 6700, 5400, 7200, 4500,
        9500, 5800, 8100, 7300, 6900
    ];

    -- Gastos mensuales del negocio
    gastos_arr NUMERIC[] := ARRAY[
        2400, 2900, 2800, 3500, 2100,
        3800, 2700, 2600, 4100, 2200,
        3200, 3100, 3700, 2800, 2000,
        4400, 2600, 3000, 3400, 2400,
        4000, 3100, 2600, 3300, 2200,
        4300, 2700, 3700, 3300, 3100
    ];

    -- Antigüedad del negocio en meses
    antiguedad_arr INT[] := ARRAY[
        36, 24, 48, 60, 18,
        72, 30, 42, 84, 12,
        54, 36, 48, 66, 24,
        90, 38, 48, 60, 18,
        72, 42, 36, 54, 30,
        96, 24, 48, 60, 84
    ];

    -- Montos solicitados
    montos_arr NUMERIC[] := ARRAY[
        8000, 12000, 15000, 6000, 10000,
        18000, 9000, 7500, 20000, 5000,
        13000, 11000, 16000, 8500, 9500,
        22000, 7000, 12000, 17000, 6500,
        14000, 10500, 13500, 9000, 11000,
        25000, 8000, 15000, 20000, 18000
    ];

    -- Plazos en meses
    plazos_arr INT[] := ARRAY[
        12, 18, 24, 12, 18,
        24, 12, 18, 36, 12,
        24, 18, 24, 12, 18,
        36, 12, 24, 24, 18,
        24, 18, 24, 12, 18,
        36, 12, 24, 36, 24
    ];

    -- Destinos del crédito
    destinos_arr TEXT[] := ARRAY[
        'Compra de mercaderías', 'Compra de stock y útiles', 'Capital de trabajo', 'Compra de equipos médicos', 'Compra de materia prima',
        'Compra de materiales de construcción', 'Remodelación del local', 'Compra de insumos y equipos', 'Compra de llantas y equipos', 'Capital de trabajo',
        'Compra de mercadería de calzado', 'Compra de stock de bazar', 'Compra de herramientas', 'Compra de monturas y lentes', 'Compra de telas e insumos',
        'Compra de joyas y relojes', 'Compra de mercadería al por mayor', 'Capital de trabajo', 'Compra de suministros de oficina', 'Capital de trabajo',
        'Compra de abarrotes al por mayor', 'Compra de medicamentos', 'Compra de madera y herramientas', 'Compra de equipos de estética', 'Compra de vidrios y marcos',
        'Compra de maquinaria de impresión', 'Capital de trabajo', 'Compra de equipo de cocina', 'Capital de trabajo para asesorías', 'Capital de trabajo'
    ];

    -- Estado inicial de las solicitudes
    -- Para practicar el flujo, dejamos algunas en BORRADOR y otras más avanzadas
    estados_arr TEXT[] := ARRAY[
        'EN_EVALUACION',   -- Caso 01 → Asesor la envió a comité, lista para procesar
        'EN_EVALUACION',   -- Caso 02
        'EN_EVALUACION',   -- Caso 03
        'EN_EVALUACION',   -- Caso 04
        'EN_EVALUACION',   -- Caso 05
        'EN_EVALUACION',   -- Caso 06
        'RECHAZADO',       -- Caso 07 → inhabilitado, ya rechazado
        'EN_EVALUACION',   -- Caso 08 → CPP, comité condicionará
        'EN_EVALUACION',   -- Caso 09
        'APROBADO',        -- Caso 10 → ya aprobado (listo para desembolso)
        'EN_EVALUACION',   -- Caso 11
        'EN_EVALUACION',   -- Caso 12
        'EN_EVALUACION',   -- Caso 13
        'EN_EVALUACION',   -- Caso 14
        'EN_EVALUACION',   -- Caso 15
        'EN_EVALUACION',   -- Caso 16
        'RECHAZADO',       -- Caso 17 → inhabilitado
        'EN_EVALUACION',   -- Caso 18
        'EN_EVALUACION',   -- Caso 19
        'DESEMBOLSADO',    -- Caso 20 → ya desembolsado (ejemplo)
        'BORRADOR',        -- Caso 21 → aún en borrador
        'BORRADOR',        -- Caso 22
        'BORRADOR',        -- Caso 23
        'BORRADOR',        -- Caso 24
        'BORRADOR',        -- Caso 25
        'BORRADOR',        -- Caso 26
        'RECHAZADO',       -- Caso 27 → inhabilitado
        'EN_EVALUACION',   -- Caso 28 → CPP especial
        'EN_EVALUACION',   -- Caso 29 → ingreso alto, excelente perfil
        'EN_EVALUACION'    -- Caso 30
    ];

    buro_arr TEXT[] := ARRAY[
        'NORMAL', 'CPP', 'NORMAL', 'DUDOSO', 'DEFICIENTE',
        'NORMAL', 'PERDIDA', 'CPP', 'NORMAL', 'NORMAL',
        'NORMAL', 'CPP', 'NORMAL', 'DUDOSO', 'DEFICIENTE',
        'NORMAL', 'PERDIDA', 'CPP', 'NORMAL', 'NORMAL',
        'NORMAL', 'CPP', 'NORMAL', 'DUDOSO', 'DEFICIENTE',
        'NORMAL', 'PERDIDA', 'CPP', 'NORMAL', 'NORMAL'
    ];

    preevalua_arr TEXT[] := ARRAY[
        'APTO', 'REVISAR', 'APTO', 'REVISAR', 'REVISAR',
        'APTO', 'NO_APTO', 'REVISAR', 'APTO', 'APTO',
        'APTO', 'REVISAR', 'APTO', 'REVISAR', 'REVISAR',
        'APTO', 'NO_APTO', 'REVISAR', 'APTO', 'APTO',
        'APTO', 'REVISAR', 'APTO', 'REVISAR', 'REVISAR',
        'APTO', 'NO_APTO', 'REVISAR', 'APTO', 'APTO'
    ];

    scores_arr INT[] := ARRAY[
        82, 65, 88, 48, 55,
        91, 20, 68, 85, 90,
        80, 63, 86, 45, 52,
        94, 18, 70, 83, 89,
        78, 61, 84, 42, 50,
        92, 15, 66, 88, 87
    ];

    canal_arr TEXT[] := ARRAY[
        'ASESOR', 'ASESOR', 'CLIENTE', 'ASESOR', 'CLIENTE',
        'ASESOR', 'ASESOR', 'CLIENTE', 'ASESOR', 'CLIENTE',
        'ASESOR', 'ASESOR', 'CLIENTE', 'ASESOR', 'CLIENTE',
        'ASESOR', 'ASESOR', 'CLIENTE', 'ASESOR', 'CLIENTE',
        'ASESOR', 'ASESOR', 'CLIENTE', 'ASESOR', 'CLIENTE',
        'ASESOR', 'ASESOR', 'CLIENTE', 'ASESOR', 'CLIENTE'
    ];

BEGIN
    FOR i IN 1..30 LOOP
        -- Select advisor & agency (10 clients each)
        IF i <= 10 THEN
            as_id := 'b0000000-0000-0000-0000-000000000001';
            ag_id := 'd0000000-0000-0000-0000-000000000001';
        ELSIF i <= 20 THEN
            as_id := 'b0000000-0000-0000-0000-000000000002';
            ag_id := 'd0000000-0000-0000-0000-000000000001';
        ELSE
            as_id := 'b0000000-0000-0000-0000-000000000003';
            ag_id := 'd0000000-0000-0000-0000-000000000002';
        END IF;

        doc_val := docs_arr[i];

        -- Insert User (cliente login)
        u_id := gen_random_uuid();
        INSERT INTO usuarios (id_usuario, documento, correo, password_hash, rol, estado)
        VALUES (u_id, doc_val, correos_arr[i], '$2b$12$g13liyNESyQ4mQhCpWXPFeFBxxT6AslZ6UXT.O0b2TyrXYskXxjYe', 'CLIENTE', 'ACTIVO');

        -- Insert Client
        c_id := gen_random_uuid();
        INSERT INTO clientes (
            id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo,
            direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado
        )
        VALUES (
            c_id, u_id, ag_id, doc_val, nombres_arr[i], apellidos_arr[i],
            telefonos_arr[i], correos_arr[i],
            'Jr. ' || distritos_arr[i] || ' Nro.' || (100 + i),
            distritos_arr[i], 'Lima', 'Lima',
            ('1980-01-01'::DATE + ((i * 7) || ' months')::INTERVAL)::DATE,
            CASE WHEN i % 3 = 0 THEN 'CASADO' WHEN i % 3 = 1 THEN 'SOLTERO' ELSE 'CONVIVIENTE' END,
            'Comerciante independiente', 'PN', 'ACTIVO'
        );

        -- Insert Business
        n_id := gen_random_uuid();
        INSERT INTO negocios_cliente (
            id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses,
            ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado
        )
        VALUES (
            n_id, c_id, negocios_arr[i], giros_arr[i], antiguedad_arr[i],
            ingresos_arr[i], gastos_arr[i],
            'Mercado Nro.' || i || ' Puesto ' || (10 + i),
            -12.046374 + (i * 0.002), -77.042793 + (i * 0.002), 'ACTIVO'
        );

        -- Insert Savings Account
        INSERT INTO cuentas_ahorro (
            id_cuenta, id_cliente, numero_cuenta, cci, moneda,
            saldo_disponible, saldo_contable, estado
        )
        VALUES (
            gen_random_uuid(), c_id,
            '191-' || LPAD((i * 10009)::text, 8, '0') || '-0-' || LPAD(i::text, 2, '0'),
            '002-191' || LPAD((i * 10009)::text, 12, '0') || '00',
            'PEN',
            ROUND((ingresos_arr[i] * 0.3)::numeric, 2),
            ROUND((ingresos_arr[i] * 0.3)::numeric, 2),
            'ACTIVO'
        );

        -- Insert Debit Card
        INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento)
        VALUES (
            gen_random_uuid(), c_id,
            '4557 **** **** ' || LPAD(i::text, 4, '0'),
            'DEBITO', 'VISA', 'ACTIVO', '2030-12-31'::DATE
        );

        -- Insert Credit Application
        sol_id := gen_random_uuid();
        INSERT INTO solicitudes_credito (
            id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor,
            id_producto_credito, canal_origen, monto_solicitado, plazo_meses,
            tea_referencial, con_seguro_desgravamen, garantia, destino_credito,
            cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion,
            resultado_buro, monto_aprobado, created_at
        )
        VALUES (
            sol_id,
            'EXP-2026-' || LPAD(i::text, 3, '0'),
            c_id, n_id, as_id, prod_id,
            canal_arr[i],
            montos_arr[i],
            plazos_arr[i],
            40.92,
            TRUE,
            CASE WHEN montos_arr[i] > 15000 THEN 'Aval solidario' ELSE 'Sola firma' END,
            destinos_arr[i],
            ROUND((montos_arr[i] * 0.04012)::numeric, 2),  -- approx cuota at TEA 40.92%, 12 m
            estados_arr[i],
            preevalua_arr[i],
            scores_arr[i],
            buro_arr[i],
            CASE WHEN estados_arr[i] IN ('APROBADO', 'DESEMBOLSADO') THEN montos_arr[i] ELSE NULL END,
            CURRENT_TIMESTAMP - ((31 - i) * INTERVAL '1 hour')
        );

        -- Assign to daily portfolio
        INSERT INTO cartera_diaria (
            id_cartera, id_asesor, id_cliente, id_solicitud,
            fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita, created_at
        )
        VALUES (
            gen_random_uuid(), as_id, c_id, sol_id,
            CURRENT_DATE,
            CASE
                WHEN buro_arr[i] IN ('DUDOSO', 'DEFICIENTE') THEN 'RECUPERACION_MORA'
                WHEN estados_arr[i] = 'BORRADOR' THEN 'NUEVA_SOLICITUD'
                ELSE 'SEGUIMIENTO'
            END,
            CASE WHEN scores_arr[i] >= 80 THEN 'ALTA' WHEN scores_arr[i] >= 60 THEN 'MEDIA' ELSE 'BAJA' END,
            scores_arr[i],
            CASE WHEN estados_arr[i] IN ('RECHAZADO') THEN 'GESTIONADO' ELSE 'PENDIENTE' END,
            CURRENT_TIMESTAMP
        );

        -- Pre-approved offers for clients with NORMAL buró and score >= 80
        IF buro_arr[i] = 'NORMAL' AND scores_arr[i] >= 80 THEN
            INSERT INTO creditos_preaprobados (
                id, id_cliente, monto_maximo, plazo_sugerido,
                tea_referencial, score_confianza, nivel_confianza,
                vigente, fecha_vencimiento
            )
            VALUES (
                gen_random_uuid(), c_id,
                ROUND((montos_arr[i] * 1.20)::numeric, 2),  -- 20% more than requested
                plazos_arr[i],
                40.92,
                scores_arr[i],
                CASE WHEN scores_arr[i] >= 85 THEN 'ALTO' ELSE 'MEDIO' END,
                TRUE,
                CURRENT_DATE + INTERVAL '90 days'
            );
        END IF;

        -- Campaign offers for high-value clients
        IF montos_arr[i] >= 15000 AND estados_arr[i] NOT IN ('RECHAZADO') THEN
            INSERT INTO campanas_activas (id, id_asesor, id_cliente, tipo, monto_oferta, activa, fecha_vencimiento)
            VALUES (
                gen_random_uuid(), as_id, c_id,
                CASE WHEN i % 2 = 0 THEN 'RENOVACION' ELSE 'AMPLIACION' END,
                ROUND((montos_arr[i] * 1.5)::numeric, 2),
                TRUE,
                CURRENT_DATE + INTERVAL '60 days'
            );
        END IF;

        -- Alerts for DEFICIENTE / DUDOSO
        IF buro_arr[i] IN ('DUDOSO', 'DEFICIENTE', 'PERDIDA') THEN
            INSERT INTO alertas_cartera (id, id_asesor, id_cliente, tipo, mensaje, leida)
            VALUES (
                gen_random_uuid(), as_id, c_id,
                CASE WHEN buro_arr[i] = 'PERDIDA' THEN 'MORA_90D' ELSE 'PRIMER_DIA_MORA' END,
                'El cliente ' || nombres_arr[i] || ' ' || apellidos_arr[i] || 
                ' (DNI ' || doc_val || ') presenta calificación SBS: ' || buro_arr[i] || '.',
                FALSE
            );
        END IF;

        -- Simulate active credit for DESEMBOLSADO cases
        IF estados_arr[i] = 'DESEMBOLSADO' THEN
            cred_id := gen_random_uuid();
            -- TEM = (1 + TEA/100)^(1/12) - 1
            tem_val := ROUND((POWER(1 + 40.92/100.0, 1.0/12.0) - 1)::numeric, 6);

            INSERT INTO cr_creditos (
                id_credito, id_solicitud, id_cliente, numero_credito,
                producto, monto_desembolsado, saldo_capital,
                plazo_meses, tea, tem, cuota_mensual,
                fecha_desembolso, dia_pago, estado
            )
            VALUES (
                cred_id, sol_id, c_id,
                'CRED-2026-' || LPAD(i::text, 3, '0'),
                'Crédito Empresarial Microempresa',
                montos_arr[i], montos_arr[i],
                plazos_arr[i], 40.92, tem_val,
                ROUND((montos_arr[i] * 0.04012)::numeric, 2),
                CURRENT_DATE - INTERVAL '5 days',
                EXTRACT(DAY FROM CURRENT_DATE)::INTEGER,
                'VIGENTE'
            );

            -- Deposit: credit the savings account
            UPDATE cuentas_ahorro SET
                saldo_disponible = saldo_disponible + montos_arr[i],
                saldo_contable   = saldo_contable   + montos_arr[i]
            WHERE id_cliente = c_id;

            -- Record the disbursement movement
            INSERT INTO cr_movimientos (
                id_movimiento, id_cliente, id_credito,
                tipo_movimiento, descripcion, monto,
                moneda, fecha_movimiento, canal
            )
            VALUES (
                gen_random_uuid(), c_id, cred_id,
                'DESEMBOLSO_CREDITO',
                'Desembolso crédito CRED-2026-' || LPAD(i::text, 3, '0'),
                montos_arr[i], 'PEN',
                CURRENT_TIMESTAMP - INTERVAL '5 days',
                'BANCA_MOVIL'
            );
        END IF;

    END LOOP;
END $$;

-- 7. Demo Notifications
INSERT INTO notificaciones (id_usuario, titulo, mensaje, tipo, leida) VALUES
('a0000000-0000-0000-0000-000000000001', 'Sistema Listo', 'Banco Andino Mobile Core 360 inicializado con 30 casos de práctica.', 'INFORMATIVA', false),
('a0000000-0000-0000-0000-000000000002', 'Solicitudes Pendientes', '12 solicitudes esperan evaluación de comité.', 'ALERTA', false);
