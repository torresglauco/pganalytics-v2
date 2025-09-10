
-- Estatísticas de índices (PARTICIONADA por tempo)
CREATE TABLE sn_stat_user_indexes_modern (
    snapshot_id BIGINT,
    cluster_id UUID NOT NULL,
    database_name VARCHAR(255),
    schemaname NAME,
    tablename NAME,
    indexrelname NAME,
    
    -- Métricas básicas de índices
    idx_scan BIGINT DEFAULT 0,
    idx_tup_read BIGINT DEFAULT 0,
    idx_tup_fetch BIGINT DEFAULT 0,
    
    -- Informações do índice
    index_size_bytes BIGINT DEFAULT 0,
    is_unique BOOLEAN DEFAULT FALSE,
    is_primary BOOLEAN DEFAULT FALSE,
    is_covering_index BOOLEAN DEFAULT FALSE, -- PG 11+ INCLUDE clause
    is_partial BOOLEAN DEFAULT FALSE,
    index_type VARCHAR(50), -- btree, hash, gin, gist, etc.
    index_definition TEXT,
    
    -- Análises de performance
    index_efficiency_score FLOAT DEFAULT 0 CHECK (index_efficiency_score >= 0 AND index_efficiency_score <= 1),
    bloat_ratio FLOAT DEFAULT 0 CHECK (bloat_ratio >= 0 AND bloat_ratio <= 1),
    usage_score INTEGER DEFAULT 0 CHECK (usage_score >= 0 AND usage_score <= 100),
    
    -- Métricas de fragmentação (quando disponível)
    avg_leaf_density FLOAT,
    leaf_fragmentation FLOAT,
    
    -- Categorias automáticas
    usage_pattern VARCHAR(20) DEFAULT 'unknown' CHECK (usage_pattern IN ('heavy', 'moderate', 'light', 'unused', 'unknown')),
    efficiency_category VARCHAR(20) DEFAULT 'unknown' CHECK (efficiency_category IN ('excellent', 'good', 'fair', 'poor', 'unused', 'unknown')),
    
    -- Recomendações automáticas
    needs_rebuild BOOLEAN DEFAULT FALSE,
    is_duplicate BOOLEAN DEFAULT FALSE,
    is_redundant BOOLEAN DEFAULT FALSE,
    
    -- Metadados
    pg_version_num INTEGER,
    collected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (snapshot_id, cluster_id, database_name, schemaname, tablename, indexrelname, collected_at),
    FOREIGN KEY (cluster_id) REFERENCES pg_clusters(id)
) PARTITION BY RANGE (collected_at);

-- Função para criar partições de índices
CREATE OR REPLACE FUNCTION create_index_stats_partitions()
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
        partition_name := 'sn_stat_user_indexes_modern_' || to_char(start_date, 'YYYY_MM');
        
        IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = partition_name) THEN
            sql_cmd := format(
                'CREATE TABLE %I PARTITION OF sn_stat_user_indexes_modern 
                 FOR VALUES FROM (%L) TO (%L)',
                partition_name, start_date, end_date
            );
            EXECUTE sql_cmd;
            
            -- Índices específicos para consultas de índices
            EXECUTE format('CREATE INDEX idx_%s_cluster_index ON %I (cluster_id, database_name, schemaname, indexrelname)', 
                          partition_name, partition_name);
            EXECUTE format('CREATE INDEX idx_%s_unused ON %I (cluster_id, usage_pattern) WHERE usage_pattern = ''unused''', 
                          partition_name, partition_name);
            EXECUTE format('CREATE INDEX idx_%s_efficiency ON %I (cluster_id, efficiency_category)', 
                          partition_name, partition_name);
            EXECUTE format('CREATE INDEX idx_%s_size ON %I (cluster_id, index_size_bytes DESC)', 
                          partition_name, partition_name);
            
            RAISE NOTICE 'Criada partição de índices: %', partition_name;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Executar criação inicial
SELECT create_index_stats_partitions();
