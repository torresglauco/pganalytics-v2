-- Criar tabela para queries lentas
CREATE TABLE IF NOT EXISTS slow_queries_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    database_name VARCHAR(100) NOT NULL,
    username VARCHAR(100) NOT NULL,
    query_text TEXT NOT NULL,
    query_hash VARCHAR(64) NOT NULL,
    execution_time_ms BIGINT NOT NULL,
    rows_returned BIGINT,
    rows_affected BIGINT,
    cpu_time_ms BIGINT,
    io_time_ms BIGINT,
    temp_files_count INTEGER,
    temp_files_size_mb NUMERIC(10,2),
    query_plan JSONB,
    explain_analyze JSONB,
    client_addr INET,
    application_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_slow_queries_database ON slow_queries_log(database_name);
CREATE INDEX IF NOT EXISTS idx_slow_queries_execution_time ON slow_queries_log(execution_time_ms DESC);
CREATE INDEX IF NOT EXISTS idx_slow_queries_query_hash ON slow_queries_log(query_hash);
CREATE INDEX IF NOT EXISTS idx_slow_queries_created_at ON slow_queries_log(created_at);
CREATE INDEX IF NOT EXISTS idx_slow_queries_username ON slow_queries_log(username);

-- Comentários
COMMENT ON TABLE slow_queries_log IS 'Log de queries lentas para análise de performance';
COMMENT ON COLUMN slow_queries_log.query_hash IS 'Hash MD5 da query normalizada';
COMMENT ON COLUMN slow_queries_log.query_plan IS 'Plano de execução da query (JSON)';