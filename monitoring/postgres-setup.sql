-- Setup para monitoramento
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Usuário para monitoramento
CREATE ROLE pganalytics_monitor WITH LOGIN PASSWORD 'monitor_password';
GRANT CONNECT ON DATABASE pganalytics TO pganalytics_monitor;
GRANT pg_monitor TO pganalytics_monitor;

-- Permissões específicas
GRANT SELECT ON pg_stat_activity TO pganalytics_monitor;
GRANT SELECT ON pg_stat_database TO pganalytics_monitor;
GRANT SELECT ON pg_stat_user_tables TO pganalytics_monitor;
GRANT SELECT ON pg_settings TO pganalytics_monitor;
