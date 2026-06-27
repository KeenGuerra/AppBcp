-- 09_policies_rls.sql

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_usuarios_modtime BEFORE UPDATE ON usuarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_clientes_modtime BEFORE UPDATE ON clientes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_negocios_cliente_modtime BEFORE UPDATE ON negocios_cliente FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_asesores_modtime BEFORE UPDATE ON asesores FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_solicitudes_credito_modtime BEFORE UPDATE ON solicitudes_credito FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cartera_diaria_modtime BEFORE UPDATE ON cartera_diaria FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_cr_creditos_modtime BEFORE UPDATE ON cr_creditos FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_operaciones_cliente_modtime BEFORE UPDATE ON operaciones_cliente FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
