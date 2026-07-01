-- 19_verificar_usuario_especifico.sql
-- Verificacion completa para: 41884031 (cliente), A001 (asesor), SUP001 (supervisor)

-- ============================================================
-- 1. USUARIOS Y SUS ROLES
-- ============================================================
SELECT 
    u.documento,
    u.nombres,
    u.rol,
    u.estado AS usuario_estado,
    u.id_usuario
FROM usuarios u
WHERE u.documento IN ('41884031', 'A001', 'SUP001');

-- ============================================================
-- 2. CLIENTE 41884031 - Datos completos
-- ============================================================
SELECT 
    c.id_cliente,
    c.documento,
    c.nombres || ' ' || c.apellidos AS nombre_completo,
    c.id_usuario,
    c.id_agencia,
    c.estado
FROM clientes c
WHERE c.documento = '41884031';

-- ============================================================
-- 3. ASESOR A001 - Datos completos
-- ============================================================
SELECT 
    a.id_asesor,
    a.codigo_empleado,
    a.nombres || ' ' || a.apellidos AS nombre_completo,
    a.id_usuario,
    a.id_agencia,
    a.estado
FROM asesores a
WHERE a.codigo_empleado = 'A001';

-- ============================================================
-- 4. SUPERVISOR SUP001 - Datos completos
-- ============================================================
SELECT 
    s.id_supervisor,
    s.codigo_empleado,
    s.nombres || ' ' || s.apellidos AS nombre_completo,
    s.id_usuario,
    s.id_agencia,
    s.estado
FROM supervisores s
WHERE s.codigo_empleado = 'SUP001';

-- ============================================================
-- 5. SOLICITUDES DEL CLIENTE 41884031 (con todo detalle)
-- ============================================================
SELECT 
    sol.numero_expediente,
    sol.estado,
    sol.monto_solicitado,
    sol.monto_aprobado,
    sol.plazo_meses,
    sol.tea_referencial,
    sol.moneda,
    sol.resultado_preevaluacion,
    sol.puntaje_preevaluacion,
    sol.motivo_rechazo,
    sol.condicion_adicional,
    sol.created_at,
    sol.updated_at,
    sol.id_solicitud,
    p.nombre AS producto_nombre,
    c.documento AS cliente_doc,
    c.nombres || ' ' || c.apellidos AS cliente_nombre,
    a.codigo_empleado AS asesor_codigo
FROM solicitudes_credito sol
LEFT JOIN clientes c ON c.id_cliente = sol.id_cliente
LEFT JOIN asesores a ON a.id_asesor = sol.id_asesor
LEFT JOIN productos_credito p ON p.id_producto_credito = sol.id_producto_credito
WHERE c.documento = '41884031'
ORDER BY sol.created_at DESC;

-- ============================================================
-- 6. CUENTAS DE AHORRO DEL CLIENTE 41884031
-- ============================================================
SELECT 
    cu.numero_cuenta,
    cu.cci,
    cu.moneda,
    cu.saldo_disponible,
    cu.saldo_contable,
    cu.estado
FROM cuentas_ahorro cu
INNER JOIN clientes c ON c.id_cliente = cu.id_cliente
WHERE c.documento = '41884031';

-- ============================================================
-- 7. CREDITOS DEL CLIENTE 41884031
-- ============================================================
SELECT 
    cr.numero_credito,
    cr.producto,
    cr.monto_desembolsado,
    cr.saldo_capital,
    cr.plazo_meses,
    cr.tea,
    cr.cuota_mensual,
    cr.fecha_desembolso,
    cr.estado
FROM cr_creditos cr
INNER JOIN clientes c ON c.id_cliente = cr.id_cliente
WHERE c.documento = '41884031';

-- ============================================================
-- 8. MOVIMIENTOS DEL CLIENTE 41884031
-- ============================================================
SELECT 
    m.tipo_movimiento,
    m.descripcion,
    m.monto,
    m.moneda,
    m.fecha_movimiento,
    m.canal
FROM cr_movimientos m
INNER JOIN clientes c ON c.id_cliente = m.id_cliente
WHERE c.documento = '41884031'
ORDER BY m.fecha_movimiento DESC;

-- ============================================================
-- 9. NOTIFICACIONES DEL CLIENTE 41884031
-- ============================================================
SELECT 
    n.titulo,
    n.mensaje,
    n.tipo,
    n.leida,
    n.created_at
FROM notificaciones n
INNER JOIN usuarios u ON u.id_usuario = n.id_usuario
WHERE u.documento = '41884031'
ORDER BY n.created_at DESC;

-- ============================================================
-- 10. SOLICITUDES ASIGNADAS AL ASESOR A001
-- ============================================================
SELECT 
    sol.numero_expediente,
    sol.estado,
    sol.monto_solicitado,
    sol.monto_aprobado,
    c.documento AS cliente_doc,
    c.nombres || ' ' || c.apellidos AS cliente_nombre,
    sol.created_at
FROM solicitudes_credito sol
INNER JOIN asesores a ON a.id_asesor = sol.id_asesor
LEFT JOIN clientes c ON c.id_cliente = sol.id_cliente
WHERE a.codigo_empleado = 'A001'
ORDER BY sol.created_at DESC;

-- ============================================================
-- 11. PRODUCTO DE CREDITO DISPONIBLE
-- ============================================================
SELECT 
    p.codigo,
    p.nombre,
    p.tipo,
    p.tea_con_seguro,
    p.tea_sin_seguro,
    p.monto_minimo,
    p.monto_maximo,
    p.plazo_minimo,
    p.plazo_maximo,
    p.moneda,
    p.estado
FROM productos_credito p
WHERE p.estado = 'ACTIVO';
