#!/bin/bash
echo "🔍 DIAGNÓSTICO DETALHADO E CORREÇÃO ESPECÍFICA"

echo "📊 1. Testando queries básicas..."

# Teste de conexão simples
echo "  🔍 Teste de SELECT simples:"
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT 1 as test;" 2>/dev/null | grep -q "1"; then
    echo "    ✅ SELECT básico funciona"
else
    echo "    ❌ SELECT básico falhou"
fi

# Teste de criação de tabela temporária
echo "  🔍 Teste de criação de tabela:"
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE TABLE IF NOT EXISTS temp_test (id SERIAL, name TEXT);
INSERT INTO temp_test (name) VALUES ('test');
SELECT COUNT(*) FROM temp_test;
DROP TABLE temp_test;
" >/dev/null 2>&1; then
    echo "    ✅ Criação/inserção/remoção de tabela funciona"
else
    echo "    ❌ Problemas com operações de tabela"
fi

echo ""
echo "📋 2. Verificando usuário pganalytics de forma simples..."

# Verificação simples do usuário
echo "  📊 Usuário atual:"
current_user=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "SELECT current_user;" 2>/dev/null | tr -d ' ')
echo "    👤 Usuário conectado: $current_user"

# Verificar se é superuser
is_super=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "SELECT usesuper FROM pg_user WHERE usename = current_user;" 2>/dev/null | tr -d ' ')
echo "    🔑 É superuser: $is_super"

echo ""
echo "🗄️ 3. Listando todas as tabelas existentes..."

tables=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;" 2>/dev/null | tr -d ' ')

if [ -n "$tables" ]; then
    echo "  📊 Tabelas encontradas:"
    echo "$tables" | while read table; do
        if [ -n "$table" ]; then
            echo "    ✅ $table"
        fi
    done
else
    echo "  ❌ Nenhuma tabela encontrada ou erro na consulta"
fi

echo ""
echo "🔍 4. Verificando se schema_migrations existe..."

schema_migrations_exists=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'schema_migrations'
);" 2>/dev/null | tr -d ' ')

echo "  📋 Tabela schema_migrations existe: $schema_migrations_exists"

if [ "$schema_migrations_exists" = "f" ]; then
    echo "  🔧 Criando tabela schema_migrations..."
    if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE TABLE schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);" >/dev/null 2>&1; then
        echo "    ✅ schema_migrations criada"
    else
        echo "    ❌ Falha ao criar schema_migrations"
    fi
fi

echo ""
echo "🔧 5. Verificando permissões necessárias..."

# Testar extensões
echo "  🔍 Testando criação de extensões:"
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" >/dev/null 2>&1; then
    echo "    ✅ Extensão uuid-ossp OK"
else
    echo "    ⚠️ Problema com extensão uuid-ossp"
fi

# Testar funções
echo "  🔍 Testando criação de funções:"
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE OR REPLACE FUNCTION test_function() RETURNS INTEGER AS \$\$
BEGIN
    RETURN 1;
END;
\$\$ LANGUAGE plpgsql;" >/dev/null 2>&1; then
    echo "    ✅ Criação de funções OK"
    # Limpar
    docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "DROP FUNCTION IF EXISTS test_function();" >/dev/null 2>&1
else
    echo "    ❌ Problema com criação de funções"
fi

echo ""
echo "📊 6. Resumo das capacidades do pganalytics..."

capabilities_ok=0
total_tests=5

# Teste 1: SELECT
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT 1;" >/dev/null 2>&1; then
    echo "  ✅ SELECT: OK"
    capabilities_ok=$((capabilities_ok + 1))
else
    echo "  ❌ SELECT: Falhou"
fi

# Teste 2: CREATE TABLE
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE TABLE IF NOT EXISTS test_cap (id INT); DROP TABLE IF EXISTS test_cap;" >/dev/null 2>&1; then
    echo "  ✅ CREATE TABLE: OK"
    capabilities_ok=$((capabilities_ok + 1))
else
    echo "  ❌ CREATE TABLE: Falhou"
fi

# Teste 3: INSERT/UPDATE/DELETE
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE TABLE IF NOT EXISTS test_dml (id SERIAL, name TEXT);
INSERT INTO test_dml (name) VALUES ('test');
UPDATE test_dml SET name = 'updated' WHERE id = 1;
DELETE FROM test_dml WHERE id = 1;
DROP TABLE test_dml;
" >/dev/null 2>&1; then
    echo "  ✅ DML (INSERT/UPDATE/DELETE): OK"
    capabilities_ok=$((capabilities_ok + 1))
else
    echo "  ❌ DML: Falhou"
fi

# Teste 4: CREATE INDEX
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE TABLE IF NOT EXISTS test_idx (id INT, name TEXT);
CREATE INDEX IF NOT EXISTS test_idx_name ON test_idx(name);
DROP INDEX IF EXISTS test_idx_name;
DROP TABLE IF EXISTS test_idx;
" >/dev/null 2>&1; then
    echo "  ✅ CREATE INDEX: OK"
    capabilities_ok=$((capabilities_ok + 1))
else
    echo "  ❌ CREATE INDEX: Falhou"
fi

# Teste 5: CREATE FUNCTION
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE OR REPLACE FUNCTION test_cap_func() RETURNS INT AS \$\$ BEGIN RETURN 1; END; \$\$ LANGUAGE plpgsql;
DROP FUNCTION IF EXISTS test_cap_func();
" >/dev/null 2>&1; then
    echo "  ✅ CREATE FUNCTION: OK"
    capabilities_ok=$((capabilities_ok + 1))
else
    echo "  ❌ CREATE FUNCTION: Falhou"
fi

echo ""
echo "📊 RESULTADO: $capabilities_ok/$total_tests testes passaram"

if [ $capabilities_ok -eq $total_tests ]; then
    echo "🎉 Todas as permissões estão funcionando!"
    echo "📋 Pode prosseguir com as migrações"
elif [ $capabilities_ok -ge 3 ]; then
    echo "⚠️ Permissões básicas funcionam, algumas avançadas podem falhar"
    echo "📋 Pode tentar executar as migrações"
else
    echo "❌ Muitas permissões falhando"
    echo "📋 Necessário corrigir permissões antes de continuar"
fi

echo ""
echo "✅ Diagnóstico concluído!"
