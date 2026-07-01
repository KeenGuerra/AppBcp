-- 18_verificar_flujo_supervisor.sql
-- Script para verificar el flujo completo de supervisor: Aprobar -> Desembolsar

-- ============================================================
-- 1. VER ESTADO ACTUAL DE SOLICITUDES
-- ============================================================
SELECT 
    s.numero_expediente,
    s.estado,
    s.monto_solicitado,
    s.monto_aprobado,
    s.plazo_meses,
    s.tea_referencial,
    c.nombres || ' ' || c.apellidos AS cliente_nombre,
    c.documento AS cliente_documento,
    a.codigo_empleado AS asesor_codigo,
    s.id_solicitud,
    s.id_cliente,
    s.id_asesor
FROM solicitudes_credito s
LEFT JOIN clientes c ON c.id_cliente = s.id_cliente
LEFT JOIN asesores a ON a.id_asesor = s.id_asesor
ORDER BY s.created_at DESC
LIMIT 20;

-- ============================================================
-- 2. VER CUENTAS DE AHORRO (antes del desembolso)
-- ============================================================
SELECT 
    cu.numero_cuenta,
    cu.saldo_disponible,
    cu.saldo_contable,
    cu.estado,
    c.nombres || ' ' || c.apellidos AS cliente_nombre,
    c.documento,
    cu.id_cliente
FROM cuentas_ahorro cu
LEFT JOIN clientes c ON c.id_cliente = cu.id_cliente
WHERE cu.estado = 'ACTIVO'
ORDER BY cu.created_at DESC;

-- ============================================================
-- 3. VER CREDITOS EXISTENTES
-- ============================================================
SELECT 
    cr.numero_credito,
    cr.producto,
    cr.monto_desembolsado,
    cr.saldo_capital,
    cr.estado,
    cr.fecha_desembolso,
    c.nombres || ' ' || c.apellidos AS cliente_nombre
FROM cr_creditos cr
LEFT JOIN clientes c ON c.id_cliente = cr.id_cliente
ORDER BY cr.created_at DESC;

-- ============================================================
-- 4. VER ULTIMOS MOVIMIENTOS
-- ============================================================
SELECT 
    m.tipo_movimiento,
    m.descripcion,
    m.monto,
    m.moneda,
    m.fecha_movimiento,
    cu.numero_cuenta,
    c.nombres || ' ' || c.apellidos AS cliente_nombre
FROM cr_movimientos m
LEFT JOIN cuentas_ahorro cu ON cu.id_cuenta = m.id_cuenta
LEFT JOIN clientes c ON c.id_cliente = m.id_cliente
ORDER BY m.created_at DESC
LIMIT 20;

-- ============================================================
-- 5. VER CRONOGRAMA DE PAGOS DE CREDITOS
-- ============================================================
SELECT 
    cr.numero_credito,
    cp.numero_cuota,
    cp.fecha_pago,
    cp.monto_cuota,
    cp.capital,
    cp.interes,
    cp.saldo,
    cp.estado AS cuota_estado
FROM cr_cronograma_pagos cp
INNER JOIN cr_creditos cr ON cr.id_credito = cp.id_credito
ORDER BY cr.numero_credito, cp.numero_cuota
LIMIT 30;

-- ============================================================
-- 6. VER NOTIFICACIONES RECIENTES
-- ============================================================
SELECT 
    n.titulo,
    n.mensaje,
    n.tipo,
    n.leida,
    n.created_at,
    u.documento AS usuario_documento
FROM notificaciones n
LEFT JOIN usuarios u ON u.id_usuario = n.id_usuario
ORDER BY n.created_at DESC
LIMIT 10;

-- ============================================================
-- 7. VERificar SOLICITUDES EN ESTADO APROBADO (listas para desembolsar)
-- ============================================================
SELECT 
    s.numero_expediente,
    s.estado,
    s.monto_aprobado,
    c.nombres || ' ' || c.apellidos AS cliente_nombre,
    c.documento,
    (SELECT COUNT(*) FROM cuentas_ahorro ca WHERE ca.id_cliente = s.id_cliente AND ca.estado = 'ACTIVO') AS num_cuentas_activas,
    s.id_solicitud
FROM solicitudes_credito s
LEFT JOIN clientes c ON c.id_cliente = s.id_cliente
WHERE s.estado = 'APROBADO';

-- ============================================================
-- 8. VERificar SOLICITUDES DESEMBOLSADAS (verificar que se crearon creditos)
-- ============================================================
SELECT 
    s.numero_expediente,
    s.estado,
    s.monto_aprobado,
    cr.numero_credito,
    cr.monto_desembolsado,
    cr.estado AS credito_estado,
    c.nombres || ' ' || c.apellidos AS cliente_nombre
FROM solicitudes_credito s
LEFT JOIN clientes c ON c.id_cliente = s.id_cliente
LEFT JOIN cr_creditos cr ON cr.id_solicitud = s.id_solicitud
WHERE s.estado = 'DESEMBOLSADO';

-- ============================================================
-- 9. VERificar SALDOS POST-DESEMBOLSO
-- ============================================================
-- Comparar saldos antes y despues
SELECT 
    c.documento,
    c.nombres || ' ' || c.apellidos AS cliente_nombre,
    cu.numero_cuenta,
    cu.saldo_disponible,
    cu.saldo_contable,
    (SELECT COALESCE(SUM(cr.monto_desembolsado), 0) 
     FROM cr_creditos cr 
     WHERE cr.id_cliente = c.id_cliente) AS total_desembolsado
FROM clientes c
INNER JOIN cuentas_ahorro cu ON cu.id_cliente = c.id_cliente
WHERE cu.estado = 'ACTIVO'
ORDER BY c.documento;
