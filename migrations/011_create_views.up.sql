-- Criar views para relatórios e consultas

-- View de usuários ativos
CREATE OR REPLACE VIEW v_active_users AS
SELECT 
    u.id,
    u.email,
    u.name,
    u.role,
    u.last_login_at,
    u.created_at,
    COUNT(rt.id) as active_sessions
FROM users u
LEFT JOIN refresh_tokens rt ON u.id = rt.user_id 
    AND rt.expires_at > NOW() 
    AND rt.revoked_at IS NULL
WHERE u.account_locked_until IS NULL OR u.account_locked_until < NOW()
GROUP BY u.id, u.email, u.name, u.role, u.last_login_at, u.created_at;

-- View de queries mais lentas
CREATE OR REPLACE VIEW v_slowest_queries AS
SELECT 
    query_hash,
    query_text,
    COUNT(*) as execution_count,
    AVG(execution_time_ms) as avg_execution_time_ms,
    MAX(execution_time_ms) as max_execution_time_ms,
    MIN(execution_time_ms) as min_execution_time_ms,
    SUM(execution_time_ms) as total_execution_time_ms,
    AVG(rows_returned) as avg_rows_returned,
    MAX(created_at) as last_execution
FROM slow_queries_log
WHERE created_at >= NOW() - INTERVAL '24 hours'
GROUP BY query_hash, query_text
ORDER BY avg_execution_time_ms DESC;

-- View de estatísticas de tabelas mais recentes
CREATE OR REPLACE VIEW v_latest_table_stats AS
SELECT DISTINCT ON (database_name, schema_name, table_name)
    database_name,
    schema_name,
    table_name,
    row_count,
    table_size_bytes,
    index_size_bytes,
    total_size_bytes,
    seq_scan_count,
    idx_scan_count,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_analyze,
    created_at
FROM table_stats_log
ORDER BY database_name, schema_name, table_name, created_at DESC;

-- View de métricas de sistema mais recentes
CREATE OR REPLACE VIEW v_latest_system_metrics AS
SELECT DISTINCT ON (metric_type, metric_name, database_name)
    metric_type,
    metric_name,
    metric_value,
    metric_unit,
    labels,
    database_name,
    created_at
FROM system_metrics_log
ORDER BY metric_type, metric_name, database_name, created_at DESC;

-- Comentários das views
COMMENT ON VIEW v_active_users IS 'Usuários ativos com contagem de sessões';
COMMENT ON VIEW v_slowest_queries IS 'Queries mais lentas das últimas 24 horas';
COMMENT ON VIEW v_latest_table_stats IS 'Estatísticas mais recentes de cada tabela';
COMMENT ON VIEW v_latest_system_metrics IS 'Métricas de sistema mais recentes';