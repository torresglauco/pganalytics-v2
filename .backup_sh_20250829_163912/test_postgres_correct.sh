#!/bin/bash

echo "🐳 TESTE CORRETO DO POSTGRESQL VIA CONTAINER"
echo "=" * 50

echo "🔍 1. Identificando container PostgreSQL correto..."
POSTGRES_CONTAINERS=$(docker ps --format "{{.Names}}" | grep postgres)
echo "  📋 Containers com 'postgres' no nome:"
echo "$POSTGRES_CONTAINERS"

# Tentar identificar o container correto
POSTGRES_CONTAINER=""
for container in $POSTGRES_CONTAINERS; do
    echo "  🔍 Testando container: $container"
    if docker exec $container which psql >/dev/null 2>&1; then
        echo "    ✅ $container tem psql"
        POSTGRES_CONTAINER=$container
        break
    else
        echo "    ❌ $container não tem psql"
    fi
done

if [ -z "$POSTGRES_CONTAINER" ]; then
    echo "  ⚠️ Tentando containers alternativos..."
    # Tentar todos os containers para encontrar o PostgreSQL
    ALL_CONTAINERS=$(docker ps --format "{{.Names}}")
    for container in $ALL_CONTAINERS; do
        if docker exec $container psql --version >/dev/null 2>&1; then
            echo "    ✅ PostgreSQL encontrado em: $container"
            POSTGRES_CONTAINER=$container
            break
        fi
    done
fi

if [ ! -z "$POSTGRES_CONTAINER" ]; then
    echo "  🎯 Container PostgreSQL: $POSTGRES_CONTAINER"
    
    echo ""
    echo "🔍 2. Testando conectividade..."
    
    # Teste básico
    echo "  📋 Teste 1: Versão PostgreSQL"
    docker exec $POSTGRES_CONTAINER psql --version && echo "    ✅ PostgreSQL disponível"
    
    # Teste de conexão como postgres
    echo "  📋 Teste 2: Conexão como superuser"
    docker exec $POSTGRES_CONTAINER psql -U postgres -c "SELECT version();" >/dev/null 2>&1 && echo "    ✅ Conexão postgres OK"
    
    # Teste database pganalytics
    echo "  📋 Teste 3: Database pganalytics"
    docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -c "SELECT current_database();" >/dev/null 2>&1 && echo "    ✅ Database pganalytics OK"
    
    # Listar usuários do banco
    echo "  📋 Teste 4: Usuários no banco pganalytics"
    docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -c "SELECT role_name FROM information_schema.enabled_roles;" 2>/dev/null
    
    # Verificar tabelas
    echo ""
    echo "  📋 Teste 5: Tabelas existentes"
    docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -c "\dt" 2>/dev/null
    
    # Verificar usuários na tabela users
    echo ""
    echo "  📋 Teste 6: Dados na tabela users"
    docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -c "SELECT id, username, email, role, is_active FROM users;" 2>/dev/null || echo "    ⚠️ Tabela users não acessível ou vazia"
    
    # Contar usuários
    USER_COUNT=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
    echo "  📊 Total de usuários: $USER_COUNT"
    
    if [ "$USER_COUNT" -gt 0 ]; then
        echo "  ✅ Usuários encontrados no banco!"
        
        # Verificar usuário admin específico
        echo ""
        echo "  🔍 Verificando usuário admin..."
        ADMIN_EXISTS=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -t -c "SELECT COUNT(*) FROM users WHERE username LIKE '%admin%' OR email LIKE '%admin%';" 2>/dev/null | tr -d ' ')
        echo "  📊 Usuários admin encontrados: $ADMIN_EXISTS"
        
        if [ "$ADMIN_EXISTS" -gt 0 ]; then
            echo "  📋 Detalhes dos usuários admin:"
            docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -c "SELECT username, email, role, is_active FROM users WHERE username LIKE '%admin%' OR email LIKE '%admin%';" 2>/dev/null
        fi
    else
        echo "  ⚠️ Nenhum usuário na tabela, criando usuário admin..."
        
        # Criar usuário admin
        docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -c "
        INSERT INTO users (username, email, password_hash, role, is_active, created_at, updated_at) 
        VALUES (
            'admin@pganalytics.local', 
            'admin@pganalytics.local',
            '\\$2a\\$10\\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
            'admin',
            true,
            NOW(),
            NOW()
        ) ON CONFLICT (email) DO NOTHING;
        " 2>/dev/null && echo "  ✅ Usuário admin criado com sucesso!"
        
        # Verificar criação
        NEW_COUNT=$(docker exec $POSTGRES_CONTAINER psql -U postgres -d pganalytics -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
        echo "  📊 Usuários após criação: $NEW_COUNT"
    fi
    
else
    echo "  ❌ Nenhum container PostgreSQL encontrado com psql"
    echo "  📋 Containers disponíveis:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
fi

echo ""
echo "🔧 3. Informações de conexão para a API..."
echo "  📝 Host: localhost"
echo "  📝 Port: 5432"
echo "  📝 User: postgres (ou pganalytics)"
echo "  📝 Database: pganalytics"
echo "  📝 Password: pganalytics123"

echo ""
echo "✅ Teste do PostgreSQL concluído!"
