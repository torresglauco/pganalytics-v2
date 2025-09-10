#!/bin/bash
# Script para aplicar as correções de métricas ao main_enhanced.c

echo "🔧 Aplicando PATCH de correção de métricas"
echo "========================================"

# Verificar se estamos no diretório correto
if [ ! -f "main_enhanced.c" ]; then
    echo "❌ Erro: Execute este script no diretório pganalytics-v2/monitoring/c-collector/"
    exit 1
fi

echo "✅ Arquivo main_enhanced.c encontrado"

# Fazer backup
echo "📦 Criando backup..."
cp main_enhanced.c main_enhanced.c.backup-$(date +%Y%m%d-%H%M%S)
echo "✅ Backup criado"

# Verificar qual implementação está sendo usada
echo "🔍 Analisando implementação atual..."

if grep -q "collect_all_metrics" main_enhanced.c; then
    echo "✅ Função collect_all_metrics encontrada"
else
    echo "❌ Função collect_all_metrics não encontrada"
fi

if grep -q "pg_stat_statements" main_enhanced.c; then
    echo "✅ pg_stat_statements mencionado no código"
else
    echo "❌ pg_stat_statements NÃO implementado"
fi

if grep -q "check_extension_exists" main_enhanced.c; then
    echo "✅ Verificação de extensões implementada"
else
    echo "❌ Verificação de extensões FALTANDO"
fi

echo ""
echo "📋 INSTRUÇÕES MANUAIS DE APLICAÇÃO:"
echo ""
echo "1. 🔧 Adicionar as funções do arquivo 'metrics_implementation_fix.c'"
echo "   ao final do main_enhanced.c"
echo ""
echo "2. 🔄 Substituir a chamada:"
echo "   collect_all_metrics(conn, &metrics, tenant_name);"
echo "   POR:"
echo "   collect_all_metrics_fixed(conn, &metrics, tenant_name);"
echo ""
echo "3. 📊 Atualizar a exportação de métricas usando:"
echo "   export_metrics_prometheus_format()"
echo ""
echo "4. 🏗️  Recompilar:"
echo "   make clean && make"
echo "   OU"
echo "   docker-compose build pg-collector"
echo ""
echo "5. 🚀 Reiniciar:"
echo "   docker-compose restart pg-collector"
echo ""
echo "6. 🧪 Testar:"
echo "   curl http://localhost:9090/metrics"
echo "   ./test_metrics_fix.sh"
echo ""

# Verificar se pg_stat_statements está habilitado no PostgreSQL
echo "🔍 Para verificar se pg_stat_statements está habilitado:"
echo "   docker exec -it pganalytics-postgres psql -U postgres -c \"\dx\""
echo "   docker exec -it pganalytics-postgres psql -U postgres -c \"SELECT * FROM pg_stat_statements LIMIT 1\""
echo ""

echo "📧 Para habilitar pg_stat_statements se necessário:"
echo "   1. Adicionar ao postgresql.conf: shared_preload_libraries = 'pg_stat_statements'"
echo "   2. Reiniciar PostgreSQL"
echo "   3. Executar: CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
echo ""

echo "🎉 PATCH preparado! Execute as instruções manuais acima."
