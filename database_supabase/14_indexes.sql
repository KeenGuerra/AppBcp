-- 14_indexes.sql — Índices optimizados para consultas frecuentes

-- Usuarios
CREATE INDEX IF NOT EXISTS idx_usuarios_documento ON usuarios(documento);
CREATE INDEX IF NOT EXISTS idx_usuarios_codigo_empleado ON usuarios(codigo_empleado);
CREATE INDEX IF NOT EXISTS idx_usuarios_rol ON usuarios(rol);
CREATE INDEX IF NOT EXISTS idx_usuarios_estado ON usuarios(estado);

-- Clientes
CREATE INDEX IF NOT EXISTS idx_clientes_documento ON clientes(documento);
CREATE INDEX IF NOT EXISTS idx_clientes_id_usuario ON clientes(id_usuario);
CREATE INDEX IF NOT EXISTS idx_clientes_id_agencia ON clientes(id_agencia);
CREATE INDEX IF NOT EXISTS idx_clientes_estado ON clientes(estado);

-- Asesores
CREATE INDEX IF NOT EXISTS idx_asesores_codigo_empleado ON asesores(codigo_empleado);
CREATE INDEX IF NOT EXISTS idx_asesores_id_usuario ON asesores(id_usuario);
CREATE INDEX IF NOT EXISTS idx_asesores_id_agencia ON asesores(id_agencia);

-- Solicitudes de crédito
CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON solicitudes_credito(estado);
CREATE INDEX IF NOT EXISTS idx_solicitudes_id_cliente ON solicitudes_credito(id_cliente);
CREATE INDEX IF NOT EXISTS idx_solicitudes_id_asesor ON solicitudes_credito(id_asesor);
CREATE INDEX IF NOT EXISTS idx_solicitudes_created_at ON solicitudes_credito(created_at);
CREATE INDEX IF NOT EXISTS idx_solicitudes_canal ON solicitudes_credito(canal_origen);

-- Cartera diaria
CREATE INDEX IF NOT EXISTS idx_cartera_id_asesor ON cartera_diaria(id_asesor);
CREATE INDEX IF NOT EXISTS idx_cartera_fecha ON cartera_diaria(fecha_asignacion);
CREATE INDEX IF NOT EXISTS idx_cartera_estado ON cartera_diaria(estado_visita);
CREATE INDEX IF NOT EXISTS idx_cartera_asesor_fecha ON cartera_diaria(id_asesor, fecha_asignacion);

-- Créditos
CREATE INDEX IF NOT EXISTS idx_creditos_id_cliente ON cr_creditos(id_cliente);
CREATE INDEX IF NOT EXISTS idx_creditos_estado ON cr_creditos(estado);
CREATE INDEX IF NOT EXISTS idx_creditos_numero ON cr_creditos(numero_credito);

-- Cronograma de pagos
CREATE INDEX IF NOT EXISTS idx_cronograma_id_credito ON cr_cronograma_pagos(id_credito);
CREATE INDEX IF NOT EXISTS idx_cronograma_estado ON cr_cronograma_pagos(estado);
CREATE INDEX IF NOT EXISTS idx_cronograma_fecha ON cr_cronograma_pagos(fecha_pago);

-- Movimientos
CREATE INDEX IF NOT EXISTS idx_movimientos_id_cliente ON cr_movimientos(id_cliente);
CREATE INDEX IF NOT EXISTS idx_movimientos_id_credito ON cr_movimientos(id_credito);
CREATE INDEX IF NOT EXISTS idx_movimientos_tipo ON cr_movimientos(tipo_movimiento);
CREATE INDEX IF NOT EXISTS idx_movimientos_fecha ON cr_movimientos(fecha_movimiento);

-- Operaciones cliente
CREATE INDEX IF NOT EXISTS idx_operaciones_id_cliente ON operaciones_cliente(id_cliente);
CREATE INDEX IF NOT EXISTS idx_operaciones_tipo ON operaciones_cliente(tipo_operacion);
CREATE INDEX IF NOT EXISTS idx_operaciones_estado ON operaciones_cliente(estado);

-- Notificaciones
CREATE INDEX IF NOT EXISTS idx_notificaciones_id_usuario ON notificaciones(id_usuario);
CREATE INDEX IF NOT EXISTS idx_notificaciones_leida ON notificaciones(leida);
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_leida ON notificaciones(id_usuario, leida);

-- Sync
CREATE INDEX IF NOT EXISTS idx_sync_outbox_estado ON sync_outbox(estado);
CREATE INDEX IF NOT EXISTS idx_sync_outbox_entidad ON sync_outbox(entidad);
CREATE INDEX IF NOT EXISTS idx_sync_log_created_at ON sync_log(created_at);

-- Auditoría
CREATE INDEX IF NOT EXISTS idx_auditoria_id_usuario ON auditoria_eventos(id_usuario);
CREATE INDEX IF NOT EXISTS idx_auditoria_entidad ON auditoria_eventos(entidad);
CREATE INDEX IF NOT EXISTS idx_auditoria_created_at ON auditoria_eventos(created_at);

-- Consultas buró
CREATE INDEX IF NOT EXISTS idx_buro_id_solicitud ON consultas_buro(id_solicitud);
CREATE INDEX IF NOT EXISTS idx_buro_id_cliente ON consultas_buro(id_cliente);

-- Documentos
CREATE INDEX IF NOT EXISTS idx_documento_id_solicitud ON solicitudes_documentos(id_solicitud);

-- Visitas
CREATE INDEX IF NOT EXISTS idx_visitas_id_asesor ON visitas_cliente(id_asesor);
CREATE INDEX IF NOT EXISTS idx_visitas_id_cliente ON visitas_cliente(id_cliente);
