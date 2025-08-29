#!/bin/bash
echo "🔍 VERIFICANDO ESTADO ATUAL DO BANCO"

echo "📊 1. Status do Docker Compose..."
docker-compose ps

echo ""
echo "🗄️ 2. Verificando conexões PostgreSQL..."

echo "  🔍 Conexão como postgres (superuser):"
if docker-compose exec -T postgres psql -U postgres -d pganalytics -c "SELECT version();" >/dev/null 2>&1; then
    echo "    ✅ Superuser OK"
else
    echo "    ❌ Superuser falhou"
fi

echo "  🔍 Conexão como pganalytics:"
if docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT current_user;" >/dev/null 2>&1; then
    echo "    ✅ pganalytics OK"
else
    echo "    ❌ pganalytics falhou"
fi

echo ""
echo "📋 3. Listando tabelas existentes..."
echo "  Como postgres:"
docker-compose exec -T postgres psql -U postgres -d pganalytics -c "\dt" 2>/dev/null | grep -E "List of relations|public|No relations" || echo "    Erro ao listar"

echo "  Como pganalytics:"
docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "\dt" 2>/dev/null | grep -E "List of relations|public|No relations" || echo "    Erro ao listar"

echo ""
echo "👤 4. Informações do usuário pganalytics..."
docker-compose exec -T postgres psql -U postgres -d pganalytics -c "
SELECT 
    usename,
    usesuper as superuser,
    usecreatedb as createdb,
    usecreaterole as createrole
FROM pg_user 
WHERE usename = 'pganalytics';
" 2>/dev/null || echo "Erro ao verificar usuário"

echo ""
echo "🔧 5. Verificando permissões no schema public..."
docker-compose exec -T postgres psql -U postgres -d pganalytics -c "
SELECT 
    schemaname,
    schemaowner,
    has_schema_privilege('pganalytics', schemaname, 'CREATE') as can_create
FROM pg_tables 
WHERE schemaname = 'public' 
LIMIT 1;
" 2>/dev/null || echo "Erro ao verificar permissões"

echo ""
echo "✅ Verificação concluída!"
