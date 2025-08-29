#!/bin/bash
echo "🗄️ EXECUTANDO MIGRAÇÕES COMO POSTGRES (SUPERUSER)"

MIGRATIONS_DIR="./migrations"

echo "🔍 1. Verificando acesso como postgres..."
if ! docker-compose exec -T postgres psql -U postgres -d pganalytics -c "SELECT 1;" >/dev/null 2>&1; then
    echo "❌ Não foi possível conectar como postgres"
    exit 1
fi
echo "✅ Conexão postgres OK"

echo ""
echo "📋 2. Criando tabela de controle de migrações..."
docker-compose exec -T postgres psql -U postgres -d pganalytics -c "
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);" >/dev/null 2>&1

echo "✅ Tabela de controle criada"

echo ""
echo "🔄 3. Executando migrações como postgres..."

if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "❌ Diretório $MIGRATIONS_DIR não encontrado"
    exit 1
fi

success_count=0
skip_count=0
error_count=0

for migration in $(ls $MIGRATIONS_DIR/*.up.sql 2>/dev/null | sort); do
    migration_name=$(basename "$migration" .up.sql)
    echo ""
    echo "🔄 Processando: $migration_name"
    
    # Verificar se já foi executada
    already_executed=$(docker-compose exec -T postgres psql -U postgres -d pganalytics -t -c "
SELECT COUNT(*) FROM schema_migrations WHERE version = '$migration_name';" 2>/dev/null | tr -d ' ')
    
    if [ "$already_executed" = "1" ]; then
        echo "  ⚪ Já executada, pulando"
        skip_count=$((skip_count + 1))
        continue
    fi
    
    # Executar migração
    echo "  🔄 Executando..."
    if docker-compose exec -T postgres psql -U postgres -d pganalytics < "$migration" >/dev/null 2>&1; then
        echo "  ✅ Sucesso"
        success_count=$((success_count + 1))
        
        # Registrar execução
        docker-compose exec -T postgres psql -U postgres -d pganalytics -c "
INSERT INTO schema_migrations (version) VALUES ('$migration_name');" >/dev/null 2>&1
    else
        echo "  ⚠️ Falhou (pode já existir ou ter dependências)"
        error_count=$((error_count + 1))
    fi
done

echo ""
echo "📊 RESULTADO FINAL:"
echo "  ✅ Executadas: $success_count"
echo "  ⚪ Puladas: $skip_count"  
echo "  ⚠️ Falharam: $error_count"

echo ""
echo "🔧 4. Ajustando propriedade das tabelas para pganalytics..."

# Transferir propriedade das tabelas para pganalytics
tables=$(docker-compose exec -T postgres psql -U postgres -d pganalytics -t -c "
SELECT tablename FROM pg_tables WHERE schemaname = 'public';" 2>/dev/null | tr -d ' ')

if [ -n "$tables" ]; then
    echo "  🔄 Transferindo propriedade das tabelas..."
    echo "$tables" | while read table; do
        if [ -n "$table" ]; then
            docker-compose exec -T postgres psql -U postgres -d pganalytics -c "
ALTER TABLE $table OWNER TO pganalytics;" >/dev/null 2>&1
            echo "    ✅ $table → pganalytics"
        fi
    done
else
    echo "  ⚠️ Nenhuma tabela encontrada"
fi

echo ""
echo "👤 5. Verificando usuários criados..."

if echo "$tables" | grep -q "users"; then
    user_count=$(docker-compose exec -T postgres psql -U postgres -d pganalytics -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ')
    echo "  📊 Usuários cadastrados: $user_count"
    
    if [ "$user_count" -gt "0" ]; then
        echo "  👤 Lista de usuários:"
        docker-compose exec -T postgres psql -U postgres -d pganalytics -c "
SELECT email, role, email_verified FROM users ORDER BY role, email;" 2>/dev/null
    fi
else
    echo "  ⚠️ Tabela users não foi criada"
fi

echo ""
echo "🗄️ 6. Listando todas as tabelas criadas..."
docker-compose exec -T postgres psql -U postgres -d pganalytics -c "
SELECT schemaname, tablename, tableowner 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;" 2>/dev/null

echo ""
echo "✅ Migrações como postgres concluídas!"
echo "📋 Agora pganalytics deve ter acesso completo às tabelas"
