-- Criar tabela para estatísticas de tabelas
CREATE TABLE IF NOT EXISTS table_stats_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    database_name VARCHAR(100) NOT NULL,
    schema_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    row_count BIGINT,
    table_size_bytes BIGINT,
    index_size_bytes BIGINT,
    total_size_bytes BIGINT,
    seq_scan_count BIGINT,
    seq_tup_read BIGINT,
    idx_scan_count BIGINT,
    idx_tup_fetch BIGINT,
    n_tup_ins BIGINT,
    n_tup_upd BIGINT,
    n_tup_del BIGINT,
    n_tup_hot_upd BIGINT,
    n_live_tup BIGINT,
    n_dead_tup BIGINT,
    vacuum_count BIGINT,
    autovacuum_count BIGINT,
    analyze_count BIGINT,
    autoanalyze_count BIGINT,
    last_vacuum TIMESTAMP WITH TIME ZONE,
    last_autovacuum TIMESTAMP WITH TIME ZONE,
    last_analyze TIMESTAMP WITH TIME ZONE,
    last_autoanalyze TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_table_stats_database_schema_table ON table_stats_log(database_name, schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_table_stats_created_at ON table_stats_log(created_at);
CREATE INDEX IF NOT EXISTS idx_table_stats_table_size ON table_stats_log(total_size_bytes DESC);

-- Comentários
COMMENT ON TABLE table_stats_log IS 'Estatísticas históricas de tabelas PostgreSQL';