#!/bin/bash
echo "🗄️ MIGRADOR SIMPLES (SEM TABELA DE CONTROLE)"

MIGRATIONS_DIR="./migrations"
COMMAND=${1:-"up"}

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_postgres() {
    if ! docker-compose exec postgres pg_isready -U pganalytics > /dev/null 2>&1; then
        echo -e "${RED}❌ PostgreSQL não está acessível${NC}"
        echo "Execute: docker-compose up -d postgres"
        exit 1
    fi
    echo -e "${GREEN}✅ PostgreSQL conectado${NC}"
}

migrate_up_simple() {
    echo "🔄 Executando todas as migrações UP (método simples)..."
    check_postgres
    
    if [ ! -d "$MIGRATIONS_DIR" ]; then
        echo -e "${RED}❌ Diretório $MIGRATIONS_DIR não encontrado${NC}"
        exit 1
    fi
    
    # Executar todas as migrações UP em ordem
    for migration in $(ls $MIGRATIONS_DIR/*.up.sql 2>/dev/null | sort); do
        echo "🔄 Executando $(basename $migration)..."
        
        if docker-compose exec -T postgres psql -U pganalytics -d pganalytics < $migration 2>/dev/null; then
            echo -e "${GREEN}  ✅ $(basename $migration)${NC}"
        else
            echo -e "${YELLOW}  ⚠️ $(basename $migration) (pode já existir)${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Migrações concluídas!${NC}"
}

migrate_status_simple() {
    echo "📊 Verificando estado do banco..."
    check_postgres
    
    echo "🔍 Tabelas existentes:"
    docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "\dt" 2>/dev/null | grep -E "^ " | sed 's/^/  ✅ /' || echo "  ❌ Nenhuma tabela encontrada"
    
    echo ""
    echo "👤 Usuários existentes:"
    docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c "SELECT email, role FROM users;" 2>/dev/null | grep -E "@" | sed 's/^/  👤 /' || echo "  ❌ Tabela users não existe ou está vazia"
}

case $COMMAND in
    "up")
        migrate_up_simple
        ;;
    "status")
        migrate_status_simple
        ;;
    *)
        echo "🗄️ Migrador Simples"
        echo "Uso: $0 [up|status]"
        echo ""
        echo "  up      - Executar todas as migrações"
        echo "  status  - Ver estado do banco"
        ;;
esac
