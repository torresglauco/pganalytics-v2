-- Criar tabela de configurações
CREATE TABLE IF NOT EXISTS system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(20) NOT NULL DEFAULT 'string' CHECK (config_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    is_sensitive BOOLEAN DEFAULT FALSE,
    updated_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_system_config_key ON system_config(config_key);
CREATE INDEX IF NOT EXISTS idx_system_config_type ON system_config(config_type);

-- Trigger
CREATE TRIGGER update_system_config_updated_at 
    BEFORE UPDATE ON system_config 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE system_config IS 'Configurações do sistema';
COMMENT ON COLUMN system_config.is_sensitive IS 'Indica se o valor é sensível (senhas, tokens)';