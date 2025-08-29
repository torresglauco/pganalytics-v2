#!/bin/bash
echo "🗄️ GESTOR COMPLETO DE MIGRAÇÕES"

MIGRATIONS_DIR="./migrations"
COMMAND=${1:-"help"}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

check_postgres() {
    if ! docker-compose exec postgres pg_isready -U pganalytics > /dev/null 2>&1; then
        echo -e "${RED}❌ PostgreSQL não está acessível${NC}"
        echo "Execute: docker-compose up -d postgres"
        exit 1
    fi
    echo -e "${GREEN}✅ PostgreSQL conectado${NC}"
}

migrate_up() {
    echo "🔄 Executando migrações UP..."
    check_postgres
    
    # Criar tabela de controle de migrações se não existir
    docker-compose exec -T postgres psql -U pganalytics -d pganalytics << 'EOF'
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
EOF
    
    for migration in $(ls $MIGRATIONS_DIR/*.up.sql | sort); do
        version=$(basename $migration .up.sql)
        echo "🔍 Verificando migração: $version"
        
        # Verificar se já foi executada
        executed=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c \
            "SELECT COUNT(*) FROM schema_migrations WHERE version = '$version';" | tr -d ' ')
        
        if [ "$executed" = "0" ]; then
            echo "🔄 Executando $version..."
            if docker-compose exec -T postgres psql -U pganalytics -d pganalytics < $migration; then
                # Marcar como executada
                docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c \
                    "INSERT INTO schema_migrations (version) VALUES ('$version');"
                print_status 0 "$version executada"
            else
                print_status 1 "$version falhou"
                exit 1
            fi
        else
            echo "⚪ $version já executada"
        fi
    done
    
    echo -e "${GREEN}✅ Todas as migrações UP executadas!${NC}"
}

migrate_down() {
    echo "🔄 Executando rollback de migrações..."
    check_postgres
    
    if [ -z "$2" ]; then
        echo "❌ Especifique quantas migrações fazer rollback"
        echo "Uso: $0 down <número>"
        exit 1
    fi
    
    count=$2
    echo "⚠️ Fazendo rollback de $count migração(ões)"
    read -p "Tem certeza? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        echo "Operação cancelada"
        exit 0
    fi
    
    # Obter últimas migrações executadas
    versions=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c \
        "SELECT version FROM schema_migrations ORDER BY executed_at DESC LIMIT $count;" | tr -d ' ')
    
    for version in $versions; do
        down_file="$MIGRATIONS_DIR/${version}.down.sql"
        if [ -f "$down_file" ]; then
            echo "🔄 Rollback $version..."
            if docker-compose exec -T postgres psql -U pganalytics -d pganalytics < $down_file; then
                # Remover da tabela de controle
                docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c \
                    "DELETE FROM schema_migrations WHERE version = '$version';"
                print_status 0 "Rollback $version"
            else
                print_status 1 "Rollback $version falhou"
                exit 1
            fi
        else
            echo "⚠️ Arquivo de rollback não encontrado: $down_file"
        fi
    done
}

migrate_status() {
    echo "📊 Status das migrações"
    check_postgres
    
    echo "🔍 Migrações disponíveis:"
    for migration in $(ls $MIGRATIONS_DIR/*.up.sql | sort); do
        version=$(basename $migration .up.sql)
        executed=$(docker-compose exec -T postgres psql -U pganalytics -d pganalytics -t -c \
            "SELECT executed_at FROM schema_migrations WHERE version = '$version';" | tr -d ' ')
        
        if [ -n "$executed" ]; then
            echo -e "  ${GREEN}✅ $version${NC} (executada em $executed)"
        else
            echo -e "  ${YELLOW}⏳ $version${NC} (pendente)"
        fi
    done
}

migrate_reset() {
    echo "🚨 RESET COMPLETO DO BANCO"
    echo "⚠️ Isso vai APAGAR TODOS OS DADOS!"
    read -p "Tem ABSOLUTA certeza? Digite 'CONFIRMO': " confirm
    
    if [ "$confirm" != "CONFIRMO" ]; then
        echo "Operação cancelada"
        exit 0
    fi
    
    check_postgres
    
    # Fazer rollback de todas as migrações
    echo "🔄 Fazendo rollback completo..."
    for migration in $(ls $MIGRATIONS_DIR/*.down.sql | sort -r); do
        echo "🔄 Executando $(basename $migration)..."
        docker-compose exec -T postgres psql -U pganalytics -d pganalytics < $migration 2>/dev/null || true
    done
    
    # Remover tabela de controle
    docker-compose exec -T postgres psql -U pganalytics -d pganalytics -c \
        "DROP TABLE IF EXISTS schema_migrations;" 2>/dev/null || true
    
    print_status 0 "Reset completo executado"
}

case $COMMAND in
    "up")
        migrate_up
        ;;
    "down")
        migrate_down $@
        ;;
    "status")
        migrate_status
        ;;
    "reset")
        migrate_reset
        ;;
    "help"|*)
        echo "🗄️ Gestor de Migrações PostgreSQL"
        echo ""
        echo "Uso: $0 <comando> [opções]"
        echo ""
        echo "Comandos:"
        echo "  up              Executar todas as migrações pendentes"
        echo "  down <número>   Fazer rollback de N migrações"
        echo "  status          Mostrar status das migrações"
        echo "  reset           Reset completo do banco (CUIDADO!)"
        echo "  help            Mostrar esta ajuda"
        echo ""
        echo "Exemplos:"
        echo "  $0 up                    # Executar todas as migrações"
        echo "  $0 down 3                # Rollback das últimas 3 migrações"
        echo "  $0 status                # Ver status"
        echo "  $0 reset                 # Reset completo"
        ;;
esac
