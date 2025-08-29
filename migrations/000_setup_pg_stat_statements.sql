-- Enable pg_stat_statements extension for query analysis

-- Arquivo: 000_setup_pg_stat_statements.sql
-- Descrição: Configuração da extensão pg_stat_statements para análise de queries

-- Criar extensão pg_stat_statements se não existir
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Ajustar parâmetros para coleta de estatísticas
ALTER SYSTEM SET pg_stat_statements.max TO 10000;
ALTER SYSTEM SET pg_stat_statements.track TO 'all';
ALTER SYSTEM SET track_activity_query_size TO 2048;

-- Resetar estatísticas
SELECT pg_stat_statements_reset();

-- Verificar se a extensão foi instalada
SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';
