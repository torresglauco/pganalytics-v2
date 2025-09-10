#!/bin/bash
# Script para executar todas as migrações do schema multi-tenant

echo "🚀 Iniciando setup do schema multi-tenant PostgreSQL Analytics..."

# Definir variáveis de conexão
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-pganalytics_central}
DB_USER=${DB_USER:-postgres}

echo "Conectando em: $DB_HOST:$DB_PORT/$DB_NAME"

# Executar migrações em ordem
echo "📊 Executando migrações..."

psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 001_create_extensions.sql
if [ $? -ne 0 ]; then echo "❌ Erro na migração 001"; exit 1; fi

psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 002_create_core_tables.sql
if [ $? -ne 0 ]; then echo "❌ Erro na migração 002"; exit 1; fi

psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 003_create_clusters_databases.sql
if [ $? -ne 0 ]; then echo "❌ Erro na migração 003"; exit 1; fi

psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 004_create_partitioned_tables.sql
if [ $? -ne 0 ]; then echo "❌ Erro na migração 004"; exit 1; fi

psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 005_create_table_metrics.sql
if [ $? -ne 0 ]; then echo "❌ Erro na migração 005"; exit 1; fi

psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 006_create_index_metrics.sql
if [ $? -ne 0 ]; then echo "❌ Erro na migração 006"; exit 1; fi

psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 007_create_views_functions.sql
if [ $? -ne 0 ]; then echo "❌ Erro na migração 007"; exit 1; fi

psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 008_create_security.sql
if [ $? -ne 0 ]; then echo "❌ Erro na migração 008"; exit 1; fi

echo "✅ Todas as migrações executadas com sucesso!"

echo "🧪 Executando testes do sistema..."
psql -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -f 009_test_system.sql
if [ $? -eq 0 ]; then
    echo "✅ Todos os testes passaram! Sistema multi-tenant pronto para uso."
else
    echo "❌ Alguns testes falharam. Verifique os logs."
fi

echo "🎯 Schema multi-tenant implementado com sucesso!"
echo "📋 Próximo passo: Implementar o Coletor C Remoto (Semana 2)"
