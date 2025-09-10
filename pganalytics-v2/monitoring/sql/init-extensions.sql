-- Enhanced PostgreSQL monitoring extensions
\echo 'Installing enhanced monitoring extensions...'

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;

GRANT SELECT ON pg_stat_statements TO admin;
GRANT SELECT ON pg_stat_activity TO admin;
GRANT SELECT ON pg_stat_database TO admin;
GRANT SELECT ON pg_stat_bgwriter TO admin;
GRANT SELECT ON pg_stat_replication TO admin;
GRANT SELECT ON pg_locks TO admin;
GRANT SELECT ON pg_statio_user_tables TO admin;

\echo 'Enhanced monitoring extensions installed!'
