#!/bin/bash
echo "🚀 INSTALAÇÃO COMPLETA DO SISTEMA PGANALYTICS V2"

# Configuração
PROJECT_ROOT="."
MIGRATIONS_DIR="$PROJECT_ROOT/migrations"
INTERNAL_DIR="$PROJECT_ROOT/internal"

echo "📁 1. Criando estrutura de diretórios..."

# Criar todos os diretórios necessários
mkdir -p "$INTERNAL_DIR/models"
mkdir -p "$INTERNAL_DIR/services" 
mkdir -p "$INTERNAL_DIR/handlers"
mkdir -p "$INTERNAL_DIR/middleware"
mkdir -p "$MIGRATIONS_DIR"

echo "📄 2. Organizando arquivos Go..."

# Mover arquivos Go para estrutura correta
echo "  📦 Movendo models..."
[ -f "user_models.go" ] && mv user_models.go "$INTERNAL_DIR/models/" && echo "    ✅ user_models.go"

echo "  🔧 Movendo services..."
[ -f "token_service.go" ] && mv token_service.go "$INTERNAL_DIR/services/" && echo "    ✅ token_service.go"
[ -f "auth_service.go" ] && mv auth_service.go "$INTERNAL_DIR/services/" && echo "    ✅ auth_service.go"

echo "  🌐 Movendo handlers..."
[ -f "auth_handlers.go" ] && mv auth_handlers.go "$INTERNAL_DIR/handlers/" && echo "    ✅ auth_handlers.go"

echo "  🛡️ Movendo middleware..."
[ -f "auth_middleware.go" ] && mv auth_middleware.go "$INTERNAL_DIR/middleware/" && echo "    ✅ auth_middleware.go"

echo ""
echo "🗄️ 3. Organizando migrações SQL..."

# Mover todas as migrações para o diretório correto
migrated_count=0
for file in *.up.sql *.down.sql; do
    if [ -f "$file" ]; then
        mv "$file" "$MIGRATIONS_DIR/"
        migrated_count=$((migrated_count + 1))
        echo "  ✅ $file"
    fi
done

echo "  📊 Total: $migrated_count arquivos de migração movidos"

echo ""
echo "🔧 4. Organizando scripts de gestão..."

# Tornar scripts executáveis
chmod +x migrations.sh 2>/dev/null && echo "  ✅ migrations.sh (gestor de migrações)"
chmod +x create_migration.sh 2>/dev/null && echo "  ✅ create_migration.sh (criar novas migrações)"
chmod +x test_auth_system.sh 2>/dev/null && echo "  ✅ test_auth_system.sh (testes de autenticação)"

echo ""
echo "📦 5. Instalando dependências Go..."

# Instalar todas as dependências necessárias
echo "  🔄 Atualizando dependências..."
go get github.com/golang-jwt/jwt/v5
go get github.com/google/uuid
go get golang.org/x/crypto/bcrypt
go get github.com/go-playground/validator/v10
go get github.com/lib/pq  # Driver PostgreSQL

echo "  🔄 Limpando módulos..."
go mod tidy

echo ""
echo "🔧 6. Configurando ambiente..."

# Verificar e criar .env
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "  ✅ .env criado a partir do .env.example"
    else
        echo "  ⚠️ .env.example não encontrado"
    fi
fi

# Adicionar configurações JWT se não existirem
if ! grep -q "JWT_SECRET" .env 2>/dev/null; then
    echo "" >> .env
    echo "# JWT Configuration" >> .env
    echo "JWT_SECRET=your-super-secret-jwt-key-change-in-production-$(openssl rand -hex 32)" >> .env
    echo "JWT_EXPIRES_IN=15m" >> .env
    echo "JWT_REFRESH_EXPIRES_IN=168h" >> .env
    echo "  ✅ Configurações JWT adicionadas ao .env"
fi

echo ""
echo "🐳 7. Verificando ambiente Docker..."

if command -v docker-compose >/dev/null 2>&1; then
    echo "  ✅ Docker Compose disponível"
    
    if docker-compose ps postgres 2>/dev/null | grep -q "Up"; then
        echo "  ✅ PostgreSQL já está rodando"
    else
        echo "  🔄 Iniciando PostgreSQL..."
        docker-compose up -d postgres
        echo "  ⏳ Aguardando PostgreSQL inicializar..."
        sleep 5
    fi
else
    echo "  ❌ Docker Compose não encontrado"
    echo "  📋 Instale Docker e Docker Compose antes de continuar"
fi

echo ""
echo "🗄️ 8. Executando migrações do banco..."

if [ -f "./migrations.sh" ]; then
    echo "  🔄 Executando migrações com gestor..."
    bash ./migrations.sh up
else
    echo "  ⚠️ migrations.sh não encontrado, executando método manual..."
    if docker-compose exec postgres pg_isready -U pganalytics >/dev/null 2>&1; then
        for migration in $(ls $MIGRATIONS_DIR/*.up.sql | sort); do
            echo "  🔄 Executando $(basename $migration)..."
            docker-compose exec -T postgres psql -U pganalytics -d pganalytics < $migration
        done
    else
        echo "  ❌ PostgreSQL não está acessível"
        echo "  📋 Execute manualmente: bash migrations.sh up"
    fi
fi

echo ""
echo "📊 9. Verificando instalação..."

# Verificar estrutura criada
echo "  📁 Estrutura de diretórios:"
echo "    $([ -d "$INTERNAL_DIR/models" ] && echo "✅" || echo "❌") internal/models/"
echo "    $([ -d "$INTERNAL_DIR/services" ] && echo "✅" || echo "❌") internal/services/"
echo "    $([ -d "$INTERNAL_DIR/handlers" ] && echo "✅" || echo "❌") internal/handlers/"
echo "    $([ -d "$INTERNAL_DIR/middleware" ] && echo "✅" || echo "❌") internal/middleware/"
echo "    $([ -d "$MIGRATIONS_DIR" ] && echo "✅" || echo "❌") migrations/"

# Verificar arquivos Go
echo "  📄 Arquivos Go:"
echo "    $([ -f "$INTERNAL_DIR/models/user_models.go" ] && echo "✅" || echo "❌") Models"
echo "    $([ -f "$INTERNAL_DIR/services/token_service.go" ] && echo "✅" || echo "❌") Token Service"
echo "    $([ -f "$INTERNAL_DIR/services/auth_service.go" ] && echo "✅" || echo "❌") Auth Service"
echo "    $([ -f "$INTERNAL_DIR/handlers/auth_handlers.go" ] && echo "✅" || echo "❌") Auth Handlers"
echo "    $([ -f "$INTERNAL_DIR/middleware/auth_middleware.go" ] && echo "✅" || echo "❌") Auth Middleware"

# Verificar migrações
migration_count=$(ls $MIGRATIONS_DIR/*.up.sql 2>/dev/null | wc -l)
echo "  🗄️ Migrações: $migration_count arquivos .up.sql"

echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "📋 ESTRUTURA FINAL DO PROJETO:"
echo "pganalytics-v2/"
echo "├── internal/"
echo "│   ├── models/         # Models do sistema"
echo "│   ├── services/       # Serviços (auth, token)"
echo "│   ├── handlers/       # Handlers HTTP"
echo "│   └── middleware/     # Middleware de autenticação"
echo "├── migrations/         # Migrações SQL completas"
echo "├── cmd/server/         # Aplicação principal"
echo "├── docs/               # Documentação Swagger"
echo "├── tests/              # Testes automatizados"
echo "└── docker/             # Recursos Docker"
echo ""
echo "🎯 PRÓXIMOS PASSOS:"
echo "1. 🔧 Integrar auth com cmd/server/main.go"
echo "2. 📚 Atualizar documentação Swagger"
echo "3. 🧪 Executar testes: bash test_auth_system.sh"
echo "4. 🌐 Testar API: http://localhost:8080/swagger/index.html"
echo ""
echo "👤 USUÁRIOS PADRÃO CRIADOS:"
echo "  🔐 Admin: admin@pganalytics.local / admin123"
echo "  👤 User:  user@pganalytics.local / admin123"
echo "  👁️ ReadOnly: readonly@pganalytics.local / admin123"
echo ""
echo "🛠️ COMANDOS ÚTEIS:"
echo "  bash migrations.sh status     # Ver status das migrações"
echo "  bash migrations.sh up         # Executar migrações pendentes"
echo "  bash create_migration.sh nome # Criar nova migração"
echo "  bash test_auth_system.sh      # Testar autenticação"
echo ""
echo "✅ Sistema pronto para desenvolvimento!"
