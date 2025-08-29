-- Remover tabela de configurações
DROP TRIGGER IF EXISTS update_system_config_updated_at ON system_config;
DROP TABLE IF EXISTS system_config;