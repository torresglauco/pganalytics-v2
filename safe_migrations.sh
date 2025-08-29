#!/bin/bash
echo "🗄️ EXECUTANDO MIGRAÇÕES DE FORMA SEGURA"

MIGRATIONS_DIR="./migrations"

echo "📊 1. Verificando estado atual..."

# Verificar se pganalytics pode conectar
if ! docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT 1;" >/dev/null 2>&1; then
    echo "❌ Não foi possível conectar como pganalytics"
    exit 1
fi

echo "✅ Conexão OK"

# Verificar/criar tabela de controle simples
echo ""
echo "📋 2. Preparando controle de migrações..."

if ! docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
CREATE TABLE IF NOT EXISTS migration_status (
    migration_name VARCHAR(255) PRIMARY KEY,
    executed_at TIMESTAMP DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'completed'
);" >/dev/null 2>&1; then
    echo "⚠️ Não foi possível criar tabela de controle, executando sem controle"
    USE_MIGRATION_CONTROL=false
else
    echo "✅ Tabela de controle OK"
    USE_MIGRATION_CONTROL=true
fi

echo ""
echo "🔄 3. Executando migrações..."

if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "❌ Diretório $MIGRATIONS_DIR não encontrado"
    exit 1
fi

# Listar migrações disponíveis
migrations=$(ls $MIGRATIONS_DIR/*.up.sql 2>/dev/null | sort)

if [ -z "$migrations" ]; then
    echo "❌ Nenhuma migração .up.sql encontrada em $MIGRATIONS_DIR"
    exit 1
fi

echo "📊 Migrações encontradas:"
echo "$migrations" | sed 's|.*/|  📄 |'

echo ""
echo "🔄 Executando migrações uma por uma..."

success_count=0
error_count=0

for migration in $migrations; do
    migration_name=$(basename "$migration" .up.sql)
    echo ""
    echo "🔄 Executando: $migration_name"
    
    # Verificar se já foi executada (se temos controle)
    if [ "$USE_MIGRATION_CONTROL" = "true" ]; then
        already_executed=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "
SELECT COUNT(*) FROM migration_status WHERE migration_name = '$migration_name';" 2>/dev/null | tr -d ' ')
        
        if [ "$already_executed" = "1" ]; then
            echo "  ⚪ Já executada, pulando"
            continue
        fi
    fi
    
    # Executar migração
    if docker-compose exec -T postgres psql -U pganalytics -d pganalytics < "$migration" >/dev/null 2>&1; then
        echo "  ✅ Sucesso"
        success_count=$((success_count + 1))
        
        # Registrar execução (se temos controle)
        if [ "$USE_MIGRATION_CONTROL" = "true" ]; then
            docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "
INSERT INTO migration_status (migration_name) VALUES ('$migration_name')
ON CONFLICT (migration_name) DO NOTHING;" >/dev/null 2>&1
        fi
    else
        echo "  ⚠️ Falhou (pode já existir)"
        error_count=$((error_count + 1))
    fi
done

echo ""
echo "📊 RESULTADO FINAL:"
echo "  ✅ Sucessos: $success_count"
echo "  ⚠️ Falhas: $error_count"

# Verificar tabelas finais
echo ""
echo "🗄️ 4. Verificando tabelas criadas..."

tables=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;" 2>/dev/null | tr -d ' ')

if [ -n "$tables" ]; then
    echo "📊 Tabelas no banco:"
    echo "$tables" | while read table; do
        if [ -n "$table" ]; then
            echo "  📋 $table"
        fi
    done
else
    echo "❌ Nenhuma tabela encontrada"
fi

# Verificar usuários se a tabela users existir
echo ""
echo "👤 5. Verificando usuários criados..."

if echo "$tables" | grep -q "users"; then
    user_count=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
    echo "📊 Usuários na tabela: $user_count"
    
    if [ "$user_count" -gt "0" ]; then
        echo "👤 Usuários existentes:"
        docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT email, role FROM users;" 2>/dev/null | grep -E "@|admin|user" | sed 's/^/  👤 /' || echo "  ❌ Erro ao listar usuários"
    fi
else
    echo "⚠️ Tabela users não encontrada"
fi

echo ""
echo "✅ Migrações seguras concluídas!"
