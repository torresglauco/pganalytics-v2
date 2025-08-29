-- Criar tabela para métricas de sistema
CREATE TABLE IF NOT EXISTS system_metrics_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_type VARCHAR(50) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC(15,6) NOT NULL,
    metric_unit VARCHAR(20),
    labels JSONB,
    database_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_system_metrics_type_name ON system_metrics_log(metric_type, metric_name);
CREATE INDEX IF NOT EXISTS idx_system_metrics_created_at ON system_metrics_log(created_at);
CREATE INDEX IF NOT EXISTS idx_system_metrics_database ON system_metrics_log(database_name);

-- Comentários
COMMENT ON TABLE system_metrics_log IS 'Métricas de sistema e performance';
COMMENT ON COLUMN system_metrics_log.metric_type IS 'Tipo da métrica (cpu, memory, disk, network, db)';
COMMENT ON COLUMN system_metrics_log.labels IS 'Labels adicionais em formato JSON';