#!/bin/bash
# database_test.sh - Testes do banco de dados

echo "🗄️  TESTANDO BANCO DE DADOS"
echo "="*30

# Testar conectividade
echo "1. Testando conectividade..."
docker-compose exec -T postgres pg_isready -U postgres
if [[ $? -eq 0 ]]; then
    echo "✅ PostgreSQL está funcionando"
else
    echo "❌ PostgreSQL não está respondendo"
    exit 1
fi

# Testar usuário pganalytics
echo ""
echo "2. Testando usuário pganalytics..."
USER_EXISTS=$(docker-compose exec -T postgres psql -U postgres -d pganalytics -tAc "SELECT 1 FROM pg_roles WHERE rolname='pganalytics'")
if [[ "$USER_EXISTS" == "1" ]]; then
    echo "✅ Usuário pganalytics existe"
else
    echo "❌ Usuário pganalytics não existe"
fi

# Testar tabelas
echo ""
echo "3. Testando tabelas..."
TABLES=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -tAc "\dt")
if [[ "$TABLES" == *"metrics"* ]]; then
    echo "✅ Tabela metrics existe"
else
    echo "❌ Tabela metrics não existe"
fi

if [[ "$TABLES" == *"query_stats"* ]]; then
    echo "✅ Tabela query_stats existe"
else
    echo "❌ Tabela query_stats não existe"
fi

# Testar inserção
echo ""
echo "4. Testando inserção de dados..."
docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c \
    "INSERT INTO metrics (metric_name, metric_value, tags) VALUES ('test_metric', 123.45, 'test=true');"

if [[ $? -eq 0 ]]; then
    echo "✅ Inserção funcionando"
else
    echo "❌ Problema na inserção"
fi

# Testar consulta
echo ""
echo "5. Testando consulta..."
RESULT=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -tAc \
    "SELECT COUNT(*) FROM metrics WHERE metric_name='test_metric';")

if [[ "$RESULT" -gt "0" ]]; then
    echo "✅ Consulta funcionando - $RESULT registros encontrados"
else
    echo "❌ Problema na consulta"
fi

echo ""
echo "🎉 Testes do banco de dados concluídos!"
