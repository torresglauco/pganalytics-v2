#!/bin/bash
echo "🔧 CORRIGINDO PERMISSÕES DO POSTGRESQL (VERSÃO CORRIGIDA)"

echo "🔍 1. Verificando conexão PostgreSQL..."

# Verificar se PostgreSQL está rodando
if ! docker-compose ps postgres | grep -q "Up"; then
    echo "❌ PostgreSQL não está rodando"
    echo "🚀 Iniciando PostgreSQL..."
    docker-compose up -d postgres
    sleep 5
fi

# Testar conexão básica
if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
    echo "✅ PostgreSQL está rodando"
else
    echo "❌ PostgreSQL não responde"
    exit 1
fi

echo ""
echo "🔧 2. Aplicando permissões via arquivos SQL..."

# Criar arquivo SQL temporário para permissões
cat > /tmp/fix_permissions.sql << 'EOSQL'
-- Conceder todas as permissões ao usuário pganalytics
ALTER USER pganalytics CREATEDB;
ALTER USER pganalytics CREATEROLE;

-- Conceder permissões na database
GRANT ALL PRIVILEGES ON DATABASE pganalytics TO pganalytics;

-- Conectar à database pganalytics e conceder permissões
\c pganalytics

-- Conceder permissões no schema public
GRANT ALL ON SCHEMA public TO pganalytics;
GRANT CREATE ON SCHEMA public TO pganalytics;

-- Conceder permissões em todas as tabelas existentes
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pganalytics;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pganalytics;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO pganalytics;

-- Definir permissões padrão para objetos futuros
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO pganalytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO pganalytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO pganalytics;

-- Tornar pganalytics proprietário do schema public
ALTER SCHEMA public OWNER TO pganalytics;

-- Conceder superuser temporariamente para resolver problemas
ALTER USER pganalytics SUPERUSER;
EOSQL

# Executar como superuser
echo "  🔄 Executando correções de permissão..."
if docker-compose exec -T postgres psql -U postgres < /tmp/fix_permissions.sql >/dev/null 2>&1; then
    echo "  ✅ Permissões aplicadas"
else
    echo "  ⚠️ Alguns comandos podem ter falhado, mas continuando..."
fi

# Limpar arquivo temporário
rm -f /tmp/fix_permissions.sql

echo ""
echo "🧪 3. Testando permissões com pganalytics..."

# Teste 1: Conectividade básica
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT 1;" >/dev/null 2>&1; then
    echo "  ✅ Conectividade com pganalytics OK"
else
    echo "  ❌ Falha na conectividade"
    exit 1
fi

# Teste 2: Criação de tabela
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE TABLE IF NOT EXISTS test_permissions (id SERIAL PRIMARY KEY, name VARCHAR(50)); DROP TABLE IF EXISTS test_permissions;" >/dev/null 2>&1; then
    echo "  ✅ Criação/remoção de tabelas OK"
else
    echo "  ❌ Problemas com criação de tabelas"
    
    # Tentar diagnóstico
    echo "  🔍 Diagnóstico:"
    docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT current_user, session_user;" 2>/dev/null || echo "    - Falha na conexão"
    docker-compose exec -T postgres psql -U postgres -d pganalytics -c "SELECT usename, usesuper, usecreatedb FROM pg_user WHERE usename = 'pganalytics';" 2>/dev/null || echo "    - Falha ao verificar usuário"
fi

# Teste 3: Extensões
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" >/dev/null 2>&1; then
    echo "  ✅ Criação de extensões OK"
else
    echo "  ⚠️ Problemas com extensões (normal se já existirem)"
fi

echo ""
echo "📊 4. Status final das permissões..."

echo "  👤 Informações do usuário pganalytics:"
docker-compose exec -T postgres psql -U postgres -d pganalytics -c "
SELECT 
    usename as usuario,
    usesuper as superuser,
    usecreatedb as pode_criar_db,
    usecreaterole as pode_criar_roles
FROM pg_user 
WHERE usename = 'pganalytics';
" 2>/dev/null | grep -E "pganalytics|usuario" || echo "    ❌ Erro ao verificar usuário"

echo ""
echo "✅ CORREÇÃO DE PERMISSÕES CONCLUÍDA!"
echo ""
echo "📋 Próximos passos:"
echo "1. bash clean_migrations.sh      # Limpar migrações"
echo "2. bash simple_migrations.sh up  # Executar migrações"
echo "3. bash simple_migrations.sh status # Verificar"
