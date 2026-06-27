-- 11_views_dashboard.sql

CREATE OR REPLACE VIEW vista_resumen_solicitudes AS
SELECT 
    estado,
    COUNT(*) as total_solicitudes,
    SUM(monto_solicitado) as monto_total_solicitado,
    SUM(monto_aprobado) as monto_total_aprobado
FROM solicitudes_credito
GROUP BY estado;

CREATE OR REPLACE VIEW vista_desempeno_asesores AS
SELECT 
    a.id_asesor,
    a.codigo_empleado,
    a.nombres || ' ' || a.apellidos as nombre_asesor,
    COUNT(s.id_solicitud) as total_solicitudes,
    SUM(CASE WHEN s.estado = 'DESEMBOLSADO' THEN 1 ELSE 0 END) as total_desembolsados,
    SUM(s.monto_solicitado) as monto_solicitado_total,
    SUM(s.monto_aprobado) as monto_aprobado_total
FROM asesores a
LEFT JOIN solicitudes_credito s ON a.id_asesor = s.id_asesor
GROUP BY a.id_asesor, a.codigo_empleado, a.nombres, a.apellidos;

CREATE OR REPLACE VIEW vista_mora_cartera AS
SELECT 
    c.id_credito,
    c.numero_credito,
    cl.nombres || ' ' || cl.apellidos as cliente,
    c.monto_desembolsado,
    c.saldo_capital,
    COUNT(cp.id_cuota) as cuotas_vencidas,
    SUM(cp.monto_cuota) as monto_vencido
FROM cr_creditos c
JOIN clientes cl ON c.id_cliente = cl.id_cliente
LEFT JOIN cr_cronograma_pagos cp ON c.id_credito = cp.id_credito AND cp.estado = 'VENCIDA'
WHERE c.estado = 'VIGENTE'
GROUP BY c.id_credito, c.numero_credito, cl.nombres, cl.apellidos, c.monto_desembolsado, c.saldo_capital;
