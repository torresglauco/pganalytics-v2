#!/bin/bash
echo "🔐 INSTALAÇÃO DO SISTEMA DE AUTENTICAÇÃO COMPLETO"

# Configuração
PROJECT_ROOT="."
MIGRATIONS_DIR="$PROJECT_ROOT/migrations"
INTERNAL_DIR="$PROJECT_ROOT/internal"

echo "📁 1. Criando estrutura de diretórios..."

# Criar diretórios necessários
mkdir -p "$INTERNAL_DIR/models"
mkdir -p "$INTERNAL_DIR/services" 
mkdir -p "$INTERNAL_DIR/handlers"
mkdir -p "$INTERNAL_DIR/middleware"

echo "📄 2. Copiando arquivos Go..."

# Mover arquivos Go para diretórios corretos
if [ -f "user_models.go" ]; then
    mv user_models.go "$INTERNAL_DIR/models/"
    echo "  ✅ Models copiados"
fi

if [ -f "token_service.go" ]; then
    mv token_service.go "$INTERNAL_DIR/services/"
    echo "  ✅ Token Service copiado"
fi

if [ -f "auth_service.go" ]; then
    mv auth_service.go "$INTERNAL_DIR/services/"
    echo "  ✅ Auth Service copiado"
fi

if [ -f "auth_handlers.go" ]; then
    mv auth_handlers.go "$INTERNAL_DIR/handlers/"
    echo "  ✅ Auth Handlers copiados"
fi

if [ -f "auth_middleware.go" ]; then
    mv auth_middleware.go "$INTERNAL_DIR/middleware/"
    echo "  ✅ Auth Middleware copiado"
fi

echo "📊 3. Instalando migrações do banco..."

# Mover arquivos de migração
for file in *.up.sql; do
    if [ -f "$file" ]; then
        mv "$file" "$MIGRATIONS_DIR/"
        echo "  ✅ Migração $file instalada"
    fi
done

echo "📦 4. Instalando dependências Go..."

# Adicionar dependências necessárias ao go.mod
go get github.com/golang-jwt/jwt/v5
go get github.com/google/uuid
go get golang.org/x/crypto/bcrypt
go get github.com/go-playground/validator/v10

echo "📝 5. Atualizando go.mod..."
go mod tidy

echo "🗄️ 6. Executando migrações do banco..."

# Verificar se o banco está rodando
if docker-compose ps postgres | grep -q "Up"; then
    echo "  ✅ PostgreSQL está rodando"
    
    # Executar migrações em ordem
    for migration in $(ls $MIGRATIONS_DIR/*.up.sql | sort); do
        echo "  🔄 Executando $(basename $migration)..."
        docker-compose exec -T postgres psql -U pganalytics -d pganalytics < $migration
    done
    
    echo "  ✅ Migrações executadas"
else
    echo "  ⚠️ PostgreSQL não está rodando. Execute:"
    echo "     docker-compose up -d postgres"
    echo "     Depois execute: bash run_migrations.sh"
fi

echo "🔧 7. Atualizando configurações..."

# Verificar se .env existe
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "  ✅ Arquivo .env criado"
fi

# Adicionar configurações JWT se não existirem
if ! grep -q "JWT_SECRET" .env; then
    echo "" >> .env
    echo "# JWT Configuration" >> .env
    echo "JWT_SECRET=your-super-secret-jwt-key-change-in-production" >> .env
    echo "JWT_EXPIRES_IN=15m" >> .env
    echo "JWT_REFRESH_EXPIRES_IN=168h" >> .env
    echo "  ✅ Configurações JWT adicionadas ao .env"
fi

echo ""
echo "✅ INSTALAÇÃO CONCLUÍDA!"
echo ""
echo "📋 Próximos passos:"
echo "1. 🔧 Atualizar internal/config/config.go para incluir JWT configs"
echo "2. 🚀 Atualizar cmd/server/main.go para usar novos handlers"
echo "3. 📚 Atualizar documentação Swagger"
echo "4. 🧪 Executar testes: bash test_auth_system.sh"
echo ""
echo "👤 Usuários padrão criados:"
echo "  Admin: admin@pganalytics.local / admin123"
echo "  User:  user@pganalytics.local / admin123"
