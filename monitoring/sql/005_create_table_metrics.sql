
-- Estatísticas de tabelas (PARTICIONADA por tempo)
CREATE TABLE sn_stat_user_tables_modern (
    snapshot_id BIGINT,
    cluster_id UUID NOT NULL,
    database_name VARCHAR(255),
    schemaname NAME,
    tablename NAME,
    
    -- Métricas básicas PostgreSQL (todas as versões)
    seq_scan BIGINT DEFAULT 0,
    seq_tup_read BIGINT DEFAULT 0,
    idx_scan BIGINT DEFAULT 0,
    idx_tup_fetch BIGINT DEFAULT 0,
    n_tup_ins BIGINT DEFAULT 0,
    n_tup_upd BIGINT DEFAULT 0,
    n_tup_del BIGINT DEFAULT 0,
    n_tup_hot_upd BIGINT DEFAULT 0,
    n_live_tup BIGINT DEFAULT 0,
    n_dead_tup BIGINT DEFAULT 0,
    n_mod_since_analyze BIGINT DEFAULT 0,
    
    -- Timestamps de manutenção
    last_vacuum TIMESTAMPTZ,
    last_autovacuum TIMESTAMPTZ,
    last_analyze TIMESTAMPTZ,
    last_autoanalyze TIMESTAMPTZ,
    vacuum_count BIGINT DEFAULT 0,
    autovacuum_count BIGINT DEFAULT 0,
    analyze_count BIGINT DEFAULT 0,
    autoanalyze_count BIGINT DEFAULT 0,
    
    -- Métricas modernas (PostgreSQL 13+)
    n_ins_since_vacuum BIGINT, -- PG 13+
    
    -- Análises de tamanho e performance
    table_size_bytes BIGINT DEFAULT 0,
    index_size_bytes BIGINT DEFAULT 0,
    total_size_bytes BIGINT DEFAULT 0,
    
    -- Ratios calculados (0.0 a 1.0)
    bloat_ratio FLOAT DEFAULT 0 CHECK (bloat_ratio >= 0 AND bloat_ratio <= 1),
    dead_tuple_ratio FLOAT DEFAULT 0 CHECK (dead_tuple_ratio >= 0 AND dead_tuple_ratio <= 1),
    index_scan_ratio FLOAT DEFAULT 0 CHECK (index_scan_ratio >= 0 AND index_scan_ratio <= 1),
    cache_hit_ratio FLOAT DEFAULT 0 CHECK (cache_hit_ratio >= 0 AND cache_hit_ratio <= 1),
    
    -- Scores e análises automáticas (0-100)
    health_score INTEGER DEFAULT 100 CHECK (health_score >= 0 AND health_score <= 100),
    performance_score INTEGER DEFAULT 100 CHECK (performance_score >= 0 AND performance_score <= 100),
    maintenance_score INTEGER DEFAULT 100 CHECK (maintenance_score >= 0 AND maintenance_score <= 100),
    
    -- Categorias automáticas
    performance_category VARCHAR(20) DEFAULT 'unknown' CHECK (performance_category IN ('excellent', 'good', 'fair', 'poor', 'critical', 'unknown')),
    bloat_category VARCHAR(20) DEFAULT 'minimal' CHECK (bloat_category IN ('minimal', 'low', 'moderate', 'high', 'critical')),
    usage_pattern VARCHAR(20) DEFAULT 'unknown' CHECK (usage_pattern IN ('heavy_read', 'heavy_write', 'balanced', 'minimal', 'unknown')),
    
    -- Metadados da versão PostgreSQL
    pg_version_num INTEGER,
    
    -- Timestamp de coleta (CHAVE DE PARTICIONAMENTO)
    collected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (snapshot_id, cluster_id, database_name, schemaname, tablename, collected_at),
    FOREIGN KEY (cluster_id) REFERENCES pg_clusters(id)
) PARTITION BY RANGE (collected_at);

-- Função para criar partições de tabelas
CREATE OR REPLACE FUNCTION create_table_stats_partitions()
RETURNS void AS $$
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
    sql_cmd TEXT;
BEGIN
    FOR i IN 0..2 LOOP
        start_date := date_trunc('month', CURRENT_DATE) + (i || ' months')::INTERVAL;
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'sn_stat_user_tables_modern_' || to_char(start_date, 'YYYY_MM');
        
        IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = partition_name) THEN
            sql_cmd := format(
                'CREATE TABLE %I PARTITION OF sn_stat_user_tables_modern 
                 FOR VALUES FROM (%L) TO (%L)',
                partition_name, start_date, end_date
            );
            EXECUTE sql_cmd;
            
            -- Índices otimizados para queries multi-tenant
            EXECUTE format('CREATE INDEX idx_%s_cluster_table ON %I (cluster_id, database_name, schemaname, tablename)', 
                          partition_name, partition_name);
            EXECUTE format('CREATE INDEX idx_%s_cluster_time ON %I (cluster_id, collected_at DESC)', 
                          partition_name, partition_name);
            EXECUTE format('CREATE INDEX idx_%s_size ON %I (cluster_id, total_size_bytes DESC)', 
                          partition_name, partition_name);
            EXECUTE format('CREATE INDEX idx_%s_health ON %I (cluster_id, health_score)', 
                          partition_name, partition_name);
            EXECUTE format('CREATE INDEX idx_%s_bloat ON %I (cluster_id, bloat_ratio) WHERE bloat_ratio > 0.1', 
                          partition_name, partition_name);
            
            RAISE NOTICE 'Criada partição de tabelas: %', partition_name;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Executar criação inicial
SELECT create_table_stats_partitions();
