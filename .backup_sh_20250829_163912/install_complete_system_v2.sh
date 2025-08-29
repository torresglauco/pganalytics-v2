#!/bin/bash
echo "🚀 INSTALAÇÃO COMPLETA DO SISTEMA PGANALYTICS V2"

# Configuração
PROJECT_ROOT="."
MIGRATIONS_DIR="$PROJECT_ROOT/migrations"
INTERNAL_DIR="$PROJECT_ROOT/internal"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

echo "📁 1. Criando estrutura de diretórios..."

# Criar todos os diretórios necessários
mkdir -p "$INTERNAL_DIR/models"
mkdir -p "$INTERNAL_DIR/services" 
mkdir -p "$INTERNAL_DIR/handlers"
mkdir -p "$INTERNAL_DIR/middleware"
mkdir -p "$MIGRATIONS_DIR"

print_status 0 "Estrutura de diretórios criada"

echo ""
echo "📄 2. Organizando arquivos Go..."

# Função para mover arquivo Go se existir
move_go_file() {
    local file="$1"
    local dest_dir="$2"
    local desc="$3"
    
    if [ -f "$file" ]; then
        mv "$file" "$dest_dir/"
        print_status 0 "$desc"
        return 0
    else
        echo -e "${YELLOW}⚪ $desc (arquivo não encontrado)${NC}"
        return 1
    fi
}

# Mover arquivos Go
move_go_file "user_models.go" "$INTERNAL_DIR/models" "Models (user_models.go)"
move_go_file "token_service.go" "$INTERNAL_DIR/services" "Token Service"
move_go_file "auth_service.go" "$INTERNAL_DIR/services" "Auth Service"
move_go_file "auth_handlers.go" "$INTERNAL_DIR/handlers" "Auth Handlers"
move_go_file "auth_middleware.go" "$INTERNAL_DIR/middleware" "Auth Middleware"

echo ""
echo "🗄️ 3. Organizando migrações SQL..."

# Garantir que diretório migrations existe
mkdir -p "$MIGRATIONS_DIR"

# Mover TODOS os arquivos SQL para migrations/
sql_moved=0
sql_skipped=0

echo "  📊 Verificando arquivos SQL no diretório atual..."

for file in *.up.sql *.down.sql; do
    if [ -f "$file" ]; then
        # Verificar se já existe no destino
        if [ -f "$MIGRATIONS_DIR/$file" ]; then
            echo -e "    ${YELLOW}⚪ $file (já existe em migrations/)${NC}"
            sql_skipped=$((sql_skipped + 1))
        else
            mv "$file" "$MIGRATIONS_DIR/"
            echo "    ✅ $file → migrations/"
            sql_moved=$((sql_moved + 1))
        fi
    fi
done

# Verificar se há outros arquivos .sql
other_sql=0
for file in *.sql; do
    if [ -f "$file" ] && [[ "$file" != *.up.sql ]] && [[ "$file" != *.down.sql ]]; then
        echo -e "    ${YELLOW}⚠️ $file (não é migração padrão)${NC}"
        other_sql=$((other_sql + 1))
    fi
done

echo "  📊 Arquivos SQL movidos: $sql_moved"
echo "  📊 Arquivos já existentes: $sql_skipped"
[ $other_sql -gt 0 ] && echo "  📊 Outros arquivos SQL: $other_sql"

# Verificar conteúdo final do diretório migrations
echo ""
echo "  📁 Conteúdo final de migrations/:"
migration_files=$(ls "$MIGRATIONS_DIR"/*.sql 2>/dev/null | wc -l)
if [ $migration_files -gt 0 ]; then
    echo "    📊 Total: $migration_files arquivos SQL"
    echo "    📋 Arquivos:"
    ls "$MIGRATIONS_DIR"/*.up.sql 2>/dev/null | sort | sed 's|.*/|      ✅ |' || echo "      (nenhum .up.sql)"
else
    echo -e "    ${RED}❌ Nenhum arquivo SQL encontrado${NC}"
    echo "    💡 Baixe os arquivos de migração primeiro"
fi

echo ""
echo "🔧 4. Configurando scripts executáveis..."

# Tornar scripts executáveis
chmod +x migrations.sh 2>/dev/null && echo "  ✅ migrations.sh" || echo "  ⚪ migrations.sh (não encontrado)"
chmod +x create_migration.sh 2>/dev/null && echo "  ✅ create_migration.sh" || echo "  ⚪ create_migration.sh (não encontrado)"
chmod +x test_auth_system.sh 2>/dev/null && echo "  ✅ test_auth_system.sh" || echo "  ⚪ test_auth_system.sh (não encontrado)"
chmod +x organize_sql.sh 2>/dev/null && echo "  ✅ organize_sql.sh" || echo "  ⚪ organize_sql.sh (não encontrado)"

echo ""
echo "📦 5. Instalando dependências Go..."

if command -v go >/dev/null 2>&1; then
    echo "  🔄 Instalando dependências..."
    go get github.com/golang-jwt/jwt/v5
    go get github.com/google/uuid
    go get golang.org/x/crypto/bcrypt
    go get github.com/go-playground/validator/v10
    go get github.com/lib/pq
    
    echo "  🔄 Organizando módulos..."
    go mod tidy
    
    print_status 0 "Dependências Go instaladas"
else
    echo -e "${YELLOW}⚠️ Go não encontrado. Instale Go para continuar${NC}"
fi

echo ""
echo "🔧 6. Configurando ambiente..."

# Verificar .env
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_status 0 ".env criado a partir do .env.example"
    else
        echo -e "${YELLOW}⚠️ .env.example não encontrado${NC}"
        # Criar .env básico
        cat > .env << 'EOF'
# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_USER=pganalytics
DB_PASSWORD=pganalytics123
DB_NAME=pganalytics

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=168h

# Application
APP_PORT=8080
APP_ENV=development
EOF
        print_status 0 ".env básico criado"
    fi
else
    echo -e "${GREEN}✅ .env já existe${NC}"
fi

# Verificar configurações JWT no .env
if ! grep -q "JWT_SECRET" .env 2>/dev/null; then
    echo "" >> .env
    echo "# JWT Configuration" >> .env
    echo "JWT_SECRET=your-super-secret-jwt-key-change-in-production-$(openssl rand -hex 16 2>/dev/null || echo "$(date +%s)")" >> .env
    echo "JWT_EXPIRES_IN=15m" >> .env
    echo "JWT_REFRESH_EXPIRES_IN=168h" >> .env
    print_status 0 "Configurações JWT adicionadas"
fi

echo ""
echo "🐳 7. Verificando ambiente Docker..."

if command -v docker-compose >/dev/null 2>&1; then
    print_status 0 "Docker Compose disponível"
    
    if docker-compose ps postgres 2>/dev/null | grep -q "Up"; then
        print_status 0 "PostgreSQL já está rodando"
    elif [ -f "docker-compose.yml" ]; then
        echo "  🔄 Iniciando PostgreSQL..."
        docker-compose up -d postgres
        echo "  ⏳ Aguardando PostgreSQL (10 segundos)..."
        sleep 10
        
        if docker-compose ps postgres 2>/dev/null | grep -q "Up"; then
            print_status 0 "PostgreSQL iniciado"
        else
            echo -e "${YELLOW}⚠️ PostgreSQL pode não ter iniciado corretamente${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ docker-compose.yml não encontrado${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Docker Compose não encontrado${NC}"
fi

echo ""
echo "🗄️ 8. Executando migrações..."

if [ -f "./migrations.sh" ] && [ $migration_files -gt 0 ]; then
    echo "  🔄 Executando migrações com gestor avançado..."
    if bash ./migrations.sh up; then
        print_status 0 "Migrações executadas"
    else
        echo -e "${YELLOW}⚠️ Algumas migrações podem ter falhado${NC}"
    fi
elif [ $migration_files -gt 0 ]; then
    echo "  🔄 Executando migrações manualmente..."
    if docker-compose exec postgres pg_isready -U pganalytics >/dev/null 2>&1; then
        for migration in $(ls $MIGRATIONS_DIR/*.up.sql | sort); do
            echo "    🔄 $(basename $migration)..."
            docker-compose exec -T postgres psql -U pganalytics -d pganalytics < $migration
        done
        print_status 0 "Migrações manuais executadas"
    else
        echo -e "${YELLOW}⚠️ PostgreSQL não acessível. Execute: bash migrations.sh up${NC}"
    fi
else
    echo -e "${RED}❌ Nenhuma migração encontrada${NC}"
    echo -e "    💡 Certifique-se de que os arquivos .sql estão disponíveis"
fi

echo ""
echo "📊 9. Verificação final..."

# Verificar estrutura
echo "  📁 Estrutura de diretórios:"
[ -d "$INTERNAL_DIR/models" ] && echo "    ✅ internal/models/" || echo "    ❌ internal/models/"
[ -d "$INTERNAL_DIR/services" ] && echo "    ✅ internal/services/" || echo "    ❌ internal/services/"
[ -d "$INTERNAL_DIR/handlers" ] && echo "    ✅ internal/handlers/" || echo "    ❌ internal/handlers/"
[ -d "$INTERNAL_DIR/middleware" ] && echo "    ✅ internal/middleware/" || echo "    ❌ internal/middleware/"
[ -d "$MIGRATIONS_DIR" ] && echo "    ✅ migrations/" || echo "    ❌ migrations/"

# Verificar arquivos críticos
echo "  📄 Arquivos Go essenciais:"
[ -f "$INTERNAL_DIR/models/user_models.go" ] && echo "    ✅ Models" || echo "    ❌ Models"
[ -f "$INTERNAL_DIR/services/auth_service.go" ] && echo "    ✅ Auth Service" || echo "    ❌ Auth Service"
[ -f "$INTERNAL_DIR/handlers/auth_handlers.go" ] && echo "    ✅ Auth Handlers" || echo "    ❌ Auth Handlers"

# Verificar migrações
up_migrations=$(ls $MIGRATIONS_DIR/*.up.sql 2>/dev/null | wc -l)
down_migrations=$(ls $MIGRATIONS_DIR/*.down.sql 2>/dev/null | wc -l)
echo "  🗄️ Migrações: $up_migrations UP, $down_migrations DOWN"

echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. 🔧 Integrar autenticação com cmd/server/main.go"
echo "2. 📚 Atualizar documentação Swagger"
echo "3. 🧪 Testar sistema: bash test_auth_system.sh"
echo "4. 🌐 Acessar: http://localhost:8080/swagger/index.html"
echo ""
echo "👤 USUÁRIOS PADRÃO:"
echo "  🔐 admin@pganalytics.local / admin123"
echo "  👤 user@pganalytics.local / admin123"
echo "  👁️ readonly@pganalytics.local / admin123"
echo ""
echo "🛠️ COMANDOS ÚTEIS:"
echo "  bash migrations.sh status        # Status das migrações"
echo "  bash migrations.sh up            # Executar migrações"
echo "  bash organize_sql.sh             # Organizar arquivos SQL"
echo "  bash create_migration.sh <nome>  # Nova migração"
echo ""
echo "✅ Sistema pronto para integração!"
