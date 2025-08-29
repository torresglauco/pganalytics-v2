#!/bin/bash
echo "🗄️ EXECUTANDO MIGRAÇÕES DO BANCO"

MIGRATIONS_DIR="./migrations"

if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo "❌ Diretório de migrações não encontrado: $MIGRATIONS_DIR"
    exit 1
fi

echo "🔍 Verificando conexão com PostgreSQL..."
if ! docker-compose exec postgres pg_isready -U pganalytics > /dev/null 2>&1; then
    echo "❌ PostgreSQL não está acessível"
    echo "Execute: docker-compose up -d postgres"
    exit 1
fi

echo "✅ PostgreSQL está rodando"
echo ""

for migration in $(ls $MIGRATIONS_DIR/*.up.sql | sort); do
    echo "🔄 Executando $(basename $migration)..."
    if docker-compose exec -T postgres psql -U pganalytics -d pganalytics < $migration; then
        echo "  ✅ $(basename $migration) executada com sucesso"
    else
        echo "  ⚠️ $(basename $migration) pode ter falhado (normal se já executada)"
    fi
done

echo ""
echo "✅ Migrações concluídas!"
