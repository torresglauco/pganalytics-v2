
-- PostgreSQL Clusters
CREATE TABLE pg_clusters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    client_identifier VARCHAR(100) NOT NULL,
    host VARCHAR(255) NOT NULL,
    port INTEGER DEFAULT 5432 CHECK (port > 0 AND port <= 65535),
    pg_version_major INTEGER,
    pg_version_minor INTEGER,
    pg_version_patch INTEGER,
    pg_version_string VARCHAR(100),
    pg_version_num INTEGER,
    supports_progress_vacuum BOOLEAN DEFAULT FALSE,
    supports_progress_create_index BOOLEAN DEFAULT FALSE,
    supports_progress_cluster BOOLEAN DEFAULT FALSE,
    supports_stat_io BOOLEAN DEFAULT FALSE,
    supports_incremental_vacuum BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'inactive', 'error', 'maintenance')),
    last_seen TIMESTAMPTZ,
    last_successful_collection TIMESTAMPTZ,
    collector_version VARCHAR(50),
    timezone VARCHAR(100) DEFAULT 'UTC',
    locale VARCHAR(50),
    encoding VARCHAR(50),
    total_collections BIGINT DEFAULT 0,
    failed_collections BIGINT DEFAULT 0,
    avg_collection_duration_ms FLOAT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}',
    UNIQUE(organization_id, client_identifier),
    UNIQUE(organization_id, name)
);

CREATE INDEX idx_pg_clusters_org_status ON pg_clusters(organization_id, status);
CREATE INDEX idx_pg_clusters_client_id ON pg_clusters(client_identifier) WHERE status = 'active';
CREATE INDEX idx_pg_clusters_last_seen ON pg_clusters(last_seen DESC) WHERE status = 'active';
CREATE INDEX idx_pg_clusters_version ON pg_clusters(pg_version_major, pg_version_minor);

CREATE TRIGGER update_pg_clusters_updated_at BEFORE UPDATE ON pg_clusters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- PostgreSQL Databases
CREATE TABLE pg_databases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cluster_id UUID NOT NULL REFERENCES pg_clusters(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    size_bytes BIGINT DEFAULT 0,
    is_monitored BOOLEAN DEFAULT TRUE,
    monitor_tables BOOLEAN DEFAULT TRUE,
    monitor_indexes BOOLEAN DEFAULT TRUE,
    monitor_queries BOOLEAN DEFAULT TRUE,
    table_count INTEGER DEFAULT 0,
    index_count INTEGER DEFAULT 0,
    connection_count INTEGER DEFAULT 0,
    last_analyzed TIMESTAMPTZ,
    analyze_duration_ms INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(cluster_id, name)
);

CREATE INDEX idx_pg_databases_cluster_monitored ON pg_databases(cluster_id) WHERE is_monitored = TRUE;
CREATE INDEX idx_pg_databases_size ON pg_databases(cluster_id, size_bytes DESC);

CREATE TRIGGER update_pg_databases_updated_at BEFORE UPDATE ON pg_databases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
