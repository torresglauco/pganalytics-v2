
-- View para estatísticas atuais de tabelas por organização
CREATE VIEW v_current_table_stats AS
WITH latest_snapshots AS (
    SELECT DISTINCT
        cluster_id,
        database_name,
        FIRST_VALUE(id) OVER (
            PARTITION BY cluster_id, database_name 
            ORDER BY collected_at DESC
        ) as latest_snapshot_id
    FROM sn_stat_snapshots 
    WHERE snapshot_type = 'tables' 
    AND collected_at >= NOW() - INTERVAL '1 hour'
)
SELECT 
    o.id as organization_id,
    o.name as organization_name,
    o.slug as organization_slug,
    c.id as cluster_id,
    c.name as cluster_name,
    c.client_identifier,
    t.database_name,
    t.schemaname,
    t.tablename,
    t.total_size_bytes,
    t.n_live_tup,
    t.n_dead_tup,
    t.bloat_ratio,
    t.health_score,
    t.performance_category,
    t.last_vacuum,
    t.last_autovacuum,
    t.collected_at
FROM latest_snapshots ls
JOIN sn_stat_user_tables_modern t ON t.snapshot_id = ls.latest_snapshot_id
JOIN pg_clusters c ON c.id = t.cluster_id
JOIN organizations o ON o.id = c.organization_id
WHERE o.is_active = TRUE 
AND c.status = 'active';

-- View para estatísticas agregadas por organização
CREATE VIEW v_organization_summary AS
SELECT 
    o.id as organization_id,
    o.name as organization_name,
    o.slug as organization_slug,
    o.plan_type,
    COUNT(DISTINCT c.id) as total_clusters,
    COUNT(DISTINCT c.id) FILTER (WHERE c.status = 'active') as active_clusters,
    COUNT(DISTINCT CONCAT(c.id, ':', d.name)) as total_databases,
    COALESCE(SUM(stats.table_count), 0) as total_tables,
    COALESCE(SUM(stats.total_size), 0) as total_size_bytes,
    COALESCE(AVG(stats.avg_health_score), 100) as avg_health_score,
    MAX(c.last_seen) as last_activity
FROM organizations o
LEFT JOIN pg_clusters c ON c.organization_id = o.id
LEFT JOIN pg_databases d ON d.cluster_id = c.id AND d.is_monitored = TRUE
LEFT JOIN (
    SELECT 
        cluster_id,
        database_name,
        COUNT(*) as table_count,
        SUM(total_size_bytes) as total_size,
        AVG(health_score) as avg_health_score
    FROM v_current_table_stats
    GROUP BY cluster_id, database_name
) stats ON stats.cluster_id = c.id AND stats.database_name = d.name
WHERE o.is_active = TRUE
GROUP BY o.id, o.name, o.slug, o.plan_type;

-- Função para calcular health score automático
CREATE OR REPLACE FUNCTION calculate_table_health_score(
    dead_ratio FLOAT,
    index_ratio FLOAT,
    days_since_vacuum INTEGER,
    table_size_bytes BIGINT
)
RETURNS INTEGER AS $$
DECLARE
    score INTEGER := 100;
BEGIN
    -- Penalizar bloat (tuplas mortas)
    IF dead_ratio > 0.5 THEN
        score := score - 50;
    ELSIF dead_ratio > 0.3 THEN
        score := score - 30;
    ELSIF dead_ratio > 0.1 THEN
        score := score - 15;
    END IF;
    
    -- Penalizar baixo uso de índices (apenas para tabelas com atividade)
    IF index_ratio < 0.1 AND table_size_bytes > 1024*1024 THEN -- > 1MB
        score := score - 25;
    ELSIF index_ratio < 0.3 AND table_size_bytes > 10*1024*1024 THEN -- > 10MB
        score := score - 15;
    END IF;
    
    -- Penalizar tempo desde último vacuum
    IF days_since_vacuum > 30 THEN
        score := score - 20;
    ELSIF days_since_vacuum > 7 THEN
        score := score - 10;
    END IF;
    
    -- Garantir limites
    IF score < 0 THEN score := 0; END IF;
    IF score > 100 THEN score := 100; END IF;
    
    RETURN score;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Função para auto-manutenção do sistema
CREATE OR REPLACE FUNCTION system_maintenance()
RETURNS TABLE(task VARCHAR, result VARCHAR, details TEXT) AS $$
BEGIN
    -- 1. Criar novas partições
    BEGIN
        PERFORM create_snapshot_partitions();
        PERFORM create_table_stats_partitions();
        PERFORM create_index_stats_partitions();
        RETURN QUERY SELECT 'create_partitions'::VARCHAR, 'success'::VARCHAR, 'Partições criadas/verificadas'::TEXT;
    EXCEPTION WHEN others THEN
        RETURN QUERY SELECT 'create_partitions'::VARCHAR, 'error'::VARCHAR, SQLERRM::TEXT;
    END;
    
    -- 2. Atualizar estatísticas das tabelas do sistema
    BEGIN
        ANALYZE organizations;
        ANALYZE pg_clusters;
        ANALYZE pg_databases;
        RETURN QUERY SELECT 'analyze_tables'::VARCHAR, 'success'::VARCHAR, 'Estatísticas atualizadas'::TEXT;
    EXCEPTION WHEN others THEN
        RETURN QUERY SELECT 'analyze_tables'::VARCHAR, 'error'::VARCHAR, SQLERRM::TEXT;
    END;
    
END;
$$ LANGUAGE plpgsql;
