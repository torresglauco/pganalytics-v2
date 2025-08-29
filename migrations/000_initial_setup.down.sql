-- Remover setup inicial
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP EXTENSION IF EXISTS "pg_trgm";
DROP EXTENSION IF EXISTS "pg_stat_statements";
-- Nota: uuid-ossp não é removido pois pode ser usado por outras aplicações