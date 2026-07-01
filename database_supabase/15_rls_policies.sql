-- 15_rls_policies.sql — Políticas Row Level Security para Supabase
-- Nota: El backend FastAPI usa service_role key que bypasea RLS.
-- Estas políticas son para protección adicional si se accede directamente desde el cliente.

-- ============================================================
-- ELIMINAR POLÍTICAS EXISTENTES (idempotente)
-- ============================================================

-- SERVICE_ROLE
DROP POLICY IF EXISTS "service_role_all_usuarios" ON usuarios;
DROP POLICY IF EXISTS "service_role_all_agencias" ON agencias;
DROP POLICY IF EXISTS "service_role_all_clientes" ON clientes;
DROP POLICY IF EXISTS "service_role_all_negocios" ON negocios_cliente;
DROP POLICY IF EXISTS "service_role_all_asesores" ON asesores;
DROP POLICY IF EXISTS "service_role_all_productos" ON productos_credito;
DROP POLICY IF EXISTS "service_role_all_cuentas" ON cuentas_ahorro;
DROP POLICY IF EXISTS "service_role_all_tarjetas" ON tarjetas;
DROP POLICY IF EXISTS "service_role_all_solicitudes" ON solicitudes_credito;
DROP POLICY IF EXISTS "service_role_all_cartera" ON cartera_diaria;
DROP POLICY IF EXISTS "service_role_all_visitas" ON visitas_cliente;
DROP POLICY IF EXISTS "service_role_all_buro" ON consultas_buro;
DROP POLICY IF EXISTS "service_role_all_inhabilitados" ON listas_inhabilitados;
DROP POLICY IF EXISTS "service_role_all_documentos" ON solicitudes_documentos;
DROP POLICY IF EXISTS "service_role_all_creditos" ON cr_creditos;
DROP POLICY IF EXISTS "service_role_all_cronograma" ON cr_cronograma_pagos;
DROP POLICY IF EXISTS "service_role_all_movimientos" ON cr_movimientos;
DROP POLICY IF EXISTS "service_role_all_operaciones" ON operaciones_cliente;
DROP POLICY IF EXISTS "service_role_all_notificaciones" ON notificaciones;
DROP POLICY IF EXISTS "service_role_all_outbox" ON sync_outbox;
DROP POLICY IF EXISTS "service_role_all_synclog" ON sync_log;
DROP POLICY IF EXISTS "service_role_all_auditoria" ON auditoria_eventos;

-- ANON
DROP POLICY IF EXISTS "anon_read_agencias" ON agencias;
DROP POLICY IF EXISTS "anon_read_productos" ON productos_credito;
DROP POLICY IF EXISTS "anon_read_inhabilitados" ON listas_inhabilitados;

-- CLIENTE
DROP POLICY IF EXISTS "cliente_select_own" ON clientes;
DROP POLICY IF EXISTS "cliente_select_own_cuentas" ON cuentas_ahorro;
DROP POLICY IF EXISTS "cliente_select_own_tarjetas" ON tarjetas;
DROP POLICY IF EXISTS "cliente_select_own_solicitudes" ON solicitudes_credito;
DROP POLICY IF EXISTS "cliente_insert_own_solicitudes" ON solicitudes_credito;
DROP POLICY IF EXISTS "cliente_select_own_creditos" ON cr_creditos;
DROP POLICY IF EXISTS "cliente_select_own_cronograma" ON cr_cronograma_pagos;
DROP POLICY IF EXISTS "cliente_select_own_movimientos" ON cr_movimientos;
DROP POLICY IF EXISTS "cliente_select_own_operaciones" ON operaciones_cliente;
DROP POLICY IF EXISTS "cliente_select_own_notificaciones" ON notificaciones;
DROP POLICY IF EXISTS "cliente_update_own_notificaciones" ON notificaciones;

-- ASESOR
DROP POLICY IF EXISTS "asesor_select_own_cartera" ON cartera_diaria;
DROP POLICY IF EXISTS "asesor_update_own_cartera" ON cartera_diaria;
DROP POLICY IF EXISTS "asesor_insert_own_visitas" ON visitas_cliente;
DROP POLICY IF EXISTS "asesor_select_own_visitas" ON visitas_cliente;
DROP POLICY IF EXISTS "asesor_select_own_solicitudes" ON solicitudes_credito;
DROP POLICY IF EXISTS "asesor_update_own_solicitudes" ON solicitudes_credito;
DROP POLICY IF EXISTS "asesor_insert_own_documentos" ON solicitudes_documentos;
DROP POLICY IF EXISTS "asesor_select_own_documentos" ON solicitudes_documentos;
DROP POLICY IF EXISTS "asesor_insert_own_buro" ON consultas_buro;

-- SUPERVISOR
DROP POLICY IF EXISTS "supervisor_select_solicitudes" ON solicitudes_credito;
DROP POLICY IF EXISTS "supervisor_update_solicitudes" ON solicitudes_credito;
DROP POLICY IF EXISTS "supervisor_select_cartera" ON cartera_diaria;

-- PUBLIC
DROP POLICY IF EXISTS "public_read_agencias" ON agencias;
DROP POLICY IF EXISTS "public_read_productos" ON productos_credito;

-- ============================================================
-- HABILITAR RLS EN TODAS LAS TABLAS
-- ============================================================

ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE agencias ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE negocios_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE asesores ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos_credito ENABLE ROW LEVEL SECURITY;
ALTER TABLE cuentas_ahorro ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarjetas ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_credito ENABLE ROW LEVEL SECURITY;
ALTER TABLE cartera_diaria ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitas_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultas_buro ENABLE ROW LEVEL SECURITY;
ALTER TABLE listas_inhabilitados ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_documentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cr_creditos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cr_cronograma_pagos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cr_movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE operaciones_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE auditoria_eventos ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLÍTICAS PARA SERVICE_ROLE (bypasea todo - acceso total)
-- ============================================================

CREATE POLICY "service_role_all_usuarios" ON usuarios FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_agencias" ON agencias FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_clientes" ON clientes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_negocios" ON negocios_cliente FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_asesores" ON asesores FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_productos" ON productos_credito FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_cuentas" ON cuentas_ahorro FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_tarjetas" ON tarjetas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_solicitudes" ON solicitudes_credito FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_cartera" ON cartera_diaria FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_visitas" ON visitas_cliente FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_buro" ON consultas_buro FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_inhabilitados" ON listas_inhabilitados FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_documentos" ON solicitudes_documentos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_creditos" ON cr_creditos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_cronograma" ON cr_cronograma_pagos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_movimientos" ON cr_movimientos FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_operaciones" ON operaciones_cliente FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_notificaciones" ON notificaciones FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_outbox" ON sync_outbox FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_synclog" ON sync_log FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "service_role_all_auditoria" ON auditoria_eventos FOR ALL USING (true) WITH CHECK (true);

-- ============================================================
-- POLÍTICAS PARA ANON (lectura pública limitada)
-- ============================================================

CREATE POLICY "anon_read_agencias" ON agencias FOR SELECT USING (estado = 'ACTIVO');
CREATE POLICY "anon_read_productos" ON productos_credito FOR SELECT USING (estado = 'ACTIVO');
CREATE POLICY "anon_read_inhabilitados" ON listas_inhabilitados FOR SELECT USING (true);

-- ============================================================
-- POLÍTICAS POR ROL (usando JWT claims)
-- ============================================================

-- CLIENTE: solo ve sus propios datos
CREATE POLICY "cliente_select_own" ON clientes
    FOR SELECT USING (id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid);

CREATE POLICY "cliente_select_own_cuentas" ON cuentas_ahorro
    FOR SELECT USING (id_cliente IN (SELECT id_cliente FROM clientes WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "cliente_select_own_tarjetas" ON tarjetas
    FOR SELECT USING (id_cliente IN (SELECT id_cliente FROM clientes WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "cliente_select_own_solicitudes" ON solicitudes_credito
    FOR SELECT USING (id_cliente IN (SELECT id_cliente FROM clientes WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "cliente_insert_own_solicitudes" ON solicitudes_credito
    FOR INSERT WITH CHECK (id_cliente IN (SELECT id_cliente FROM clientes WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "cliente_select_own_creditos" ON cr_creditos
    FOR SELECT USING (id_cliente IN (SELECT id_cliente FROM clientes WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "cliente_select_own_cronograma" ON cr_cronograma_pagos
    FOR SELECT USING (id_credito IN (SELECT id_credito FROM cr_creditos WHERE id_cliente IN (SELECT id_cliente FROM clientes WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid)));

CREATE POLICY "cliente_select_own_movimientos" ON cr_movimientos
    FOR SELECT USING (id_cliente IN (SELECT id_cliente FROM clientes WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "cliente_select_own_operaciones" ON operaciones_cliente
    FOR SELECT USING (id_cliente IN (SELECT id_cliente FROM clientes WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "cliente_select_own_notificaciones" ON notificaciones
    FOR SELECT USING (id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid);

CREATE POLICY "cliente_update_own_notificaciones" ON notificaciones
    FOR UPDATE USING (id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid);

-- ASESOR: ve su cartera asignada
CREATE POLICY "asesor_select_own_cartera" ON cartera_diaria
    FOR SELECT USING (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "asesor_update_own_cartera" ON cartera_diaria
    FOR UPDATE USING (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "asesor_insert_own_visitas" ON visitas_cliente
    FOR INSERT WITH CHECK (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "asesor_select_own_visitas" ON visitas_cliente
    FOR SELECT USING (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "asesor_select_own_solicitudes" ON solicitudes_credito
    FOR SELECT USING (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "asesor_update_own_solicitudes" ON solicitudes_credito
    FOR UPDATE USING (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid));

CREATE POLICY "asesor_insert_own_documentos" ON solicitudes_documentos
    FOR INSERT WITH CHECK (id_solicitud IN (SELECT id_solicitud FROM solicitudes_credito WHERE id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid)));

CREATE POLICY "asesor_select_own_documentos" ON solicitudes_documentos
    FOR SELECT USING (id_solicitud IN (SELECT id_solicitud FROM solicitudes_credito WHERE id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid)));

CREATE POLICY "asesor_insert_own_buro" ON consultas_buro
    FOR INSERT WITH CHECK (id_solicitud IN (SELECT id_solicitud FROM solicitudes_credito WHERE id_asesor IN (SELECT id_asesor FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid)));

-- SUPERVISOR: ve solicitudes de su agencia
CREATE POLICY "supervisor_select_solicitudes" ON solicitudes_credito
    FOR SELECT USING (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_agencia IN (SELECT id_agencia FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid)));

CREATE POLICY "supervisor_update_solicitudes" ON solicitudes_credito
    FOR UPDATE USING (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_agencia IN (SELECT id_agencia FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid)));

CREATE POLICY "supervisor_select_cartera" ON cartera_diaria
    FOR SELECT USING (id_asesor IN (SELECT id_asesor FROM asesores WHERE id_agencia IN (SELECT id_agencia FROM asesores WHERE id_usuario = NULLIF(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid)));

-- ADMIN: acceso total (ya cubierto por service_role policies)

-- ============================================================
-- POLÍTICAS PARA TABLAS PÚBLICAS (lectura libre)
-- ============================================================

CREATE POLICY "public_read_agencias" ON agencias FOR SELECT USING (true);
CREATE POLICY "public_read_productos" ON productos_credito FOR SELECT USING (true);
