#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create user if not exists
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'pganalytics') THEN
            CREATE ROLE pganalytics LOGIN PASSWORD 'pganalytics123';
        END IF;
    END
    \$\$;

    -- Grant permissions
    GRANT ALL PRIVILEGES ON DATABASE pganalytics TO pganalytics;
    ALTER USER pganalytics CREATEDB;

    -- Create sample tables
    CREATE TABLE IF NOT EXISTS metrics (
        id SERIAL PRIMARY KEY,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        metric_name VARCHAR(255) NOT NULL,
        metric_value FLOAT NOT NULL,
        tags JSONB
    );

    CREATE TABLE IF NOT EXISTS query_stats (
        id SERIAL PRIMARY KEY,
        query_hash VARCHAR(64) NOT NULL,
        query_text TEXT NOT NULL,
        calls INTEGER DEFAULT 0,
        total_time FLOAT DEFAULT 0,
        avg_time FLOAT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Grant table permissions
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pganalytics;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pganalytics;
EOSQL
