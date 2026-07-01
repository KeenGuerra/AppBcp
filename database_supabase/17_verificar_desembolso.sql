-- CONSULTA 1: Creditos desembolsados
SELECT sc.numero_expediente, sc.estado, sc.monto_solicitado, sc.monto_aprobado,
       cc.numero_credito, cc.monto_desembolsado, cc.saldo_capital, cc.fecha_desembolso,
       cl.nombres, cl.apellidos, cl.documento
FROM solicitudes_credito sc
JOIN cr_creditos cc ON cc.id_solicitud = sc.id_solicitud
JOIN clientes cl ON cl.id_cliente = sc.id_cliente
WHERE sc.estado = 'DESEMBOLSADO';

-- CONSULTA 2: Saldo de cuentas
SELECT cl.nombres, cl.apellidos, cl.documento,
       ca.numero_cuenta, ca.moneda, ca.saldo_disponible, ca.saldo_contable, ca.estado
FROM cuentas_ahorro ca
JOIN clientes cl ON cl.id_cliente = ca.id_cliente
WHERE ca.estado = 'ACTIVO'
ORDER BY ca.saldo_disponible DESC;

-- CONSULTA 3: Movimientos de desembolso
SELECT cm.fecha_movimiento, cm.tipo_movimiento, cm.descripcion, cm.monto,
       cl.nombres, cl.apellidos, cl.documento
FROM cr_movimientos cm
JOIN clientes cl ON cl.id_cliente = cm.id_cliente
WHERE cm.tipo_movimiento = 'DESEMBOLSO_CREDITO'
ORDER BY cm.fecha_movimiento DESC;

-- CONSULTA 4: Cronograma de cuotas
SELECT cr.numero_credito, cp.numero_cuota, cp.fecha_pago, cp.monto_cuota,
       cp.capital, cp.interes, cp.saldo, cp.estado
FROM cr_cronograma_pagos cp
JOIN cr_creditos cr ON cr.id_credito = cp.id_credito
WHERE cr.estado = 'VIGENTE'
ORDER BY cr.numero_credito, cp.numero_cuota;

-- CONSULTA 5: Resumen completo
SELECT cl.documento, cl.nombres || ' ' || cl.apellidos AS cliente,
       sc.numero_expediente, sc.monto_aprobado,
       cc.numero_credito, cc.monto_desembolsado,
       ca.numero_cuenta, ca.saldo_disponible AS saldo_actual,
       cm.monto AS depositado
FROM solicitudes_credito sc
JOIN clientes cl ON cl.id_cliente = sc.id_cliente
LEFT JOIN cr_creditos cc ON cc.id_solicitud = sc.id_solicitud
LEFT JOIN cr_movimientos cm ON cm.id_cliente = cl.id_cliente
  AND cm.tipo_movimiento = 'DESEMBOLSO_CREDITO'
LEFT JOIN cuentas_ahorro ca ON ca.id_cliente = cl.id_cliente
  AND ca.estado = 'ACTIVO'
WHERE sc.estado = 'DESEMBOLSADO';
