#!/bin/bash
echo "🔧 CORRIGINDO PERMISSÕES DO POSTGRESQL"

echo "🔍 1. Verificando conexão como superuser..."
if docker-compose exec postgres psql -U postgres -d pganalytics -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ Conexão como postgres (superuser) OK"
    
    echo ""
    echo "🔧 2. Concedendo permissões ao usuário pganalytics..."
    
    # Conceder permissões necessárias
    docker-compose exec postgres psql -U postgres -d pganalytics << 'EOF'
-- Conceder permissões na database
GRANT ALL PRIVILEGES ON DATABASE pganalytics TO pganalytics;

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

\q
EOF

    echo "✅ Permissões concedidas"
    
    echo ""
    echo "🧪 3. Testando permissões..."
    if docker-compose exec postgres psql -U pganalytics -d pganalytics -c "CREATE TABLE test_permissions (id INTEGER); DROP TABLE test_permissions;" >/dev/null 2>&1; then
        echo "✅ Teste de permissões bem-sucedido"
    else
        echo "❌ Ainda há problemas de permissão"
        exit 1
    fi
    
else
    echo "❌ Não foi possível conectar como superuser"
    echo "💡 Verifique se o PostgreSQL está rodando:"
    echo "   docker-compose up -d postgres"
    exit 1
fi

echo ""
echo "✅ Permissões corrigidas!"
echo "📋 Agora você pode executar as migrações normalmente"
