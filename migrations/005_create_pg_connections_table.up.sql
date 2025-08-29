-- Criar tabela para monitorar conexões PostgreSQL
CREATE TABLE IF NOT EXISTS pg_connections_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    database_name VARCHAR(100) NOT NULL,
    username VARCHAR(100) NOT NULL,
    client_addr INET,
    application_name VARCHAR(255),
    state VARCHAR(50),
    backend_start TIMESTAMP WITH TIME ZONE,
    query_start TIMESTAMP WITH TIME ZONE,
    state_change TIMESTAMP WITH TIME ZONE,
    wait_event_type VARCHAR(100),
    wait_event VARCHAR(255),
    query TEXT,
    connection_duration_ms INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_pg_connections_database ON pg_connections_log(database_name);
CREATE INDEX IF NOT EXISTS idx_pg_connections_username ON pg_connections_log(username);
CREATE INDEX IF NOT EXISTS idx_pg_connections_created_at ON pg_connections_log(created_at);
CREATE INDEX IF NOT EXISTS idx_pg_connections_client_addr ON pg_connections_log(client_addr);

-- Comentários
COMMENT ON TABLE pg_connections_log IS 'Log de conexões PostgreSQL para análise';