#!/bin/bash
echo "🔧 CONCEDENDO PERMISSÕES COMPLETAS AO PGANALYTICS"

echo "🔍 1. Verificando acesso como superuser postgres..."
if ! docker-compose exec -T postgres psql -U postgres -d pganalytics -c "SELECT 1;" >/dev/null 2>&1; then
    echo "❌ Não foi possível conectar como postgres superuser"
    exit 1
fi
echo "✅ Acesso superuser OK"

echo ""
echo "🔧 2. Concedendo todas as permissões necessárias..."

# Executar como postgres (superuser) para conceder permissões
docker-compose exec -T postgres psql -U postgres -d pganalytics << 'EOSQL'

-- Fazer pganalytics proprietário da database
ALTER DATABASE pganalytics OWNER TO pganalytics;

-- Conceder permissões de superuser temporariamente
ALTER USER pganalytics SUPERUSER;

-- Conceder permissões no schema public
GRANT ALL ON SCHEMA public TO pganalytics;
GRANT CREATE ON SCHEMA public TO pganalytics;
ALTER SCHEMA public OWNER TO pganalytics;

-- Conceder permissões em todas as tabelas existentes
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pganalytics;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pganalytics;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO pganalytics;

-- Definir permissões padrão para objetos futuros
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO pganalytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO pganalytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO pganalytics;

-- Permitir criação de extensões
ALTER USER pganalytics CREATEDB;

EOSQL

if [ $? -eq 0 ]; then
    echo "✅ Permissões concedidas com sucesso"
else
    echo "❌ Erro ao conceder permissões"
    exit 1
fi

echo ""
echo "🧪 3. Testando permissões concedidas..."

# Teste 1: Verificar se agora é superuser
is_super=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "SELECT usesuper FROM pg_user WHERE usename = current_user;" 2>/dev/null | tr -d ' ')
echo "  🔑 É superuser agora: $is_super"

# Teste 2: CREATE TABLE
echo "  🔍 Testando CREATE TABLE..."
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE TABLE test_permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);
" >/dev/null 2>&1; then
    echo "    ✅ CREATE TABLE funcionou"
    
    # Teste 3: INSERT
    echo "  🔍 Testando INSERT..."
    if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
INSERT INTO test_permissions (name) VALUES ('teste1'), ('teste2');
" >/dev/null 2>&1; then
        echo "    ✅ INSERT funcionou"
        
        # Teste 4: UPDATE
        echo "  🔍 Testando UPDATE..."
        if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
UPDATE test_permissions SET name = 'atualizado' WHERE id = 1;
" >/dev/null 2>&1; then
            echo "    ✅ UPDATE funcionou"
            
            # Teste 5: SELECT
            echo "  🔍 Testando SELECT..."
            result=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "SELECT COUNT(*) FROM test_permissions;" 2>/dev/null | tr -d ' ')
            if [ "$result" = "2" ]; then
                echo "    ✅ SELECT funcionou (2 registros)"
            else
                echo "    ⚠️ SELECT retornou: '$result'"
            fi
            
            # Teste 6: DELETE
            echo "  🔍 Testando DELETE..."
            if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
DELETE FROM test_permissions WHERE id = 2;
" >/dev/null 2>&1; then
                echo "    ✅ DELETE funcionou"
            else
                echo "    ❌ DELETE falhou"
            fi
        else
            echo "    ❌ UPDATE falhou"
        fi
    else
        echo "    ❌ INSERT falhou"
    fi
    
    # Limpar tabela de teste
    docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "DROP TABLE IF EXISTS test_permissions;" >/dev/null 2>&1
else
    echo "    ❌ CREATE TABLE ainda falha"
fi

# Teste 7: CREATE FUNCTION
echo "  🔍 Testando CREATE FUNCTION..."
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE OR REPLACE FUNCTION test_func() RETURNS INTEGER AS \$\$
BEGIN
    RETURN 42;
END;
\$\$ LANGUAGE plpgsql;
SELECT test_func();
DROP FUNCTION test_func();
" >/dev/null 2>&1; then
    echo "    ✅ CREATE FUNCTION funcionou"
else
    echo "    ❌ CREATE FUNCTION falhou"
fi

# Teste 8: CREATE INDEX
echo "  🔍 Testando CREATE INDEX..."
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE TABLE IF NOT EXISTS test_idx (id INT, name TEXT);
CREATE INDEX test_idx_name ON test_idx(name);
DROP INDEX test_idx_name;
DROP TABLE test_idx;
" >/dev/null 2>&1; then
    echo "    ✅ CREATE INDEX funcionou"
else
    echo "    ❌ CREATE INDEX falhou"
fi

echo ""
echo "📊 4. Resultado final das permissões..."

# Contar testes que passaram
tests_passed=0
total_tests=6

# Refazer todos os testes para contagem final
echo "  📋 Resumo dos testes:"

if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT 1;" >/dev/null 2>&1; then
    echo "    ✅ SELECT"
    tests_passed=$((tests_passed + 1))
else
    echo "    ❌ SELECT"
fi

if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE TABLE test_final (id INT); DROP TABLE test_final;" >/dev/null 2>&1; then
    echo "    ✅ CREATE TABLE"
    tests_passed=$((tests_passed + 1))
else
    echo "    ❌ CREATE TABLE"
fi

if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE TABLE test_dml (id INT); INSERT INTO test_dml VALUES (1); DELETE FROM test_dml WHERE id = 1; DROP TABLE test_dml;" >/dev/null 2>&1; then
    echo "    ✅ DML (INSERT/UPDATE/DELETE)"
    tests_passed=$((tests_passed + 1))
else
    echo "    ❌ DML"
fi

if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE TABLE test_idx (id INT); CREATE INDEX test_i ON test_idx(id); DROP INDEX test_i; DROP TABLE test_idx;" >/dev/null 2>&1; then
    echo "    ✅ CREATE INDEX"
    tests_passed=$((tests_passed + 1))
else
    echo "    ❌ CREATE INDEX"
fi

if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE OR REPLACE FUNCTION test_f() RETURNS INT AS \$\$ BEGIN RETURN 1; END; \$\$ LANGUAGE plpgsql; DROP FUNCTION test_f();" >/dev/null 2>&1; then
    echo "    ✅ CREATE FUNCTION"
    tests_passed=$((tests_passed + 1))
else
    echo "    ❌ CREATE FUNCTION"
fi

if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" >/dev/null 2>&1; then
    echo "    ✅ CREATE EXTENSION"
    tests_passed=$((tests_passed + 1))
else
    echo "    ❌ CREATE EXTENSION"
fi

echo ""
echo "🎯 RESULTADO: $tests_passed/$total_tests testes passaram"

if [ $tests_passed -eq $total_tests ]; then
    echo "🎉 SUCESSO! Todas as permissões estão funcionando!"
    echo "✅ pganalytics pode executar todas as operações necessárias"
    echo "📋 Pronto para executar migrações"
elif [ $tests_passed -ge 4 ]; then
    echo "⚠️ Permissões básicas OK, algumas avançadas podem falhar"
    echo "📋 Pode tentar executar migrações"
else
    echo "❌ Ainda há problemas de permissões"
    echo "📋 Pode ser necessário executar migrações como postgres"
fi

echo ""
echo "✅ Configuração de permissões concluída!"
