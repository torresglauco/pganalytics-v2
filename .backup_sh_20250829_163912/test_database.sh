#!/bin/bash

echo "🗄️ TESTE ESPECÍFICO DO BANCO DE DADOS"
echo "=" * 45

echo "🔍 1. Verificando containers Docker..."
if command -v docker >/dev/null 2>&1; then
    echo "  🐳 Docker disponível"
    echo "  📋 Containers em execução:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -v NAMES
    
    echo ""
    echo "  🔍 Procurando container PostgreSQL..."
    POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "(postgres|pg)" | head -1)
    
    if [ ! -z "$POSTGRES_CONTAINER" ]; then
        echo "  ✅ Container PostgreSQL encontrado: $POSTGRES_CONTAINER"
    else
        echo "  ⚠️ Container PostgreSQL não encontrado"
        echo "  🔄 Verificando docker-compose..."
        if [ -f "docker-compose.yml" ]; then
            echo "  📄 docker-compose.yml existe, iniciando containers..."
            docker-compose up -d
            sleep 10
            POSTGRES_CONTAINER=$(docker ps --format "{{.Names}}" | grep -E "(postgres|pg)" | head -1)
        fi
    fi
else
    echo "  ❌ Docker não disponível"
fi

echo ""
echo "🔍 2. Testando conectividade do banco..."
if [ ! -z "$POSTGRES_CONTAINER" ]; then
    echo "  🔧 Testando conexão via Docker..."
    
    # Teste básico de conexão
    echo "  📋 Teste 1: Conexão básica"
    docker exec $POSTGRES_CONTAINER psql -U postgres -c "SELECT version();" 2>/dev/null && echo "    ✅ PostgreSQL respondendo" || echo "    ❌ PostgreSQL não responde"
    
    # Teste de database específico
    echo "  📋 Teste 2: Database pganalytics"
    docker exec $POSTGRES_CONTAINER psql -U pganalytics -d pganalytics -c "SELECT current_database();" 2>/dev/null && echo "    ✅ Database pganalytics acessível" || echo "    ❌ Database pganalytics inacessível"
    
    # Teste de tabelas
    echo "  📋 Teste 3: Tabela users"
    TABLES_RESULT=$(docker exec $POSTGRES_CONTAINER psql -U pganalytics -d pganalytics -c "\dt" 2>/dev/null)
    echo "$TABLES_RESULT" | grep -q "users" && echo "    ✅ Tabela users existe" || echo "    ❌ Tabela users não existe"
    
    # Contar usuários
    echo "  📋 Teste 4: Usuários cadastrados"
    USER_COUNT=$(docker exec $POSTGRES_CONTAINER psql -U pganalytics -d pganalytics -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
    if [ ! -z "$USER_COUNT" ] && [ "$USER_COUNT" -gt 0 ]; then
        echo "    ✅ $USER_COUNT usuário(s) encontrado(s)"
        
        echo "  📋 Listando usuários existentes:"
        docker exec $POSTGRES_CONTAINER psql -U pganalytics -d pganalytics -c "SELECT id, username, email, role, is_active FROM users;" 2>/dev/null
    else
        echo "    ⚠️ Nenhum usuário encontrado"
        echo "    🔧 Criando usuário admin..."
        
        # Criar usuário admin
        docker exec $POSTGRES_CONTAINER psql -U pganalytics -d pganalytics -c "
        INSERT INTO users (username, email, password_hash, role, is_active, created_at, updated_at) 
        VALUES (
            'admin@pganalytics.local', 
            'admin@pganalytics.local',
            '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
            'admin',
            true,
            NOW(),
            NOW()
        ) ON CONFLICT (email) DO NOTHING;
        " 2>/dev/null && echo "    ✅ Usuário admin criado" || echo "    ❌ Erro ao criar usuário"
        
        # Verificar criação
        NEW_USER_COUNT=$(docker exec $POSTGRES_CONTAINER psql -U pganalytics -d pganalytics -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
        echo "    📊 Usuários após criação: $NEW_USER_COUNT"
    fi
else
    echo "  ❌ Não foi possível testar o banco (container não encontrado)"
fi

echo ""
echo "🔧 3. Criando string de conexão para testes..."
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="pganalytics"
DB_PASSWORD="pganalytics123"
DB_NAME="pganalytics"

CONNECTION_STRING="host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWORD dbname=$DB_NAME sslmode=disable"
echo "  📝 String de conexão: $CONNECTION_STRING"

echo ""
echo "🧪 4. Testando conexão do Go com o banco..."
if [ -f "main.go" ]; then
    echo "  🔍 Verificando se main.go tem a string de conexão correta..."
    grep -n "host=" main.go && echo "    ✅ String de conexão encontrada" || echo "    ❌ String de conexão não encontrada"
else
    echo "  ❌ main.go não encontrado"
fi

echo ""
echo "✅ Teste do banco de dados concluído!"
