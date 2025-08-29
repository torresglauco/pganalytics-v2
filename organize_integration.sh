#!/bin/bash
echo "🔧 ORGANIZANDO ARQUIVOS PARA INTEGRAÇÃO"

echo "📁 1. Movendo arquivos Go para estrutura correta..."

# Verificar se arquivos existem e mover
if [ -f "user_models.go" ]; then
    mv user_models.go internal/models/
    echo "  ✅ user_models.go → internal/models/"
else
    echo "  ⚪ user_models.go não encontrado"
fi

if [ -f "token_service.go" ]; then
    mv token_service.go internal/services/
    echo "  ✅ token_service.go → internal/services/"
else
    echo "  ⚪ token_service.go não encontrado"
fi

if [ -f "auth_service.go" ]; then
    mv auth_service.go internal/services/
    echo "  ✅ auth_service.go → internal/services/"
else
    echo "  ⚪ auth_service.go não encontrado"
fi

if [ -f "auth_handlers.go" ]; then
    mv auth_handlers.go internal/handlers/
    echo "  ✅ auth_handlers.go → internal/handlers/"
else
    echo "  ⚪ auth_handlers.go não encontrado"
fi

if [ -f "auth_middleware.go" ]; then
    mv auth_middleware.go internal/middleware/
    echo "  ✅ auth_middleware.go → internal/middleware/"
else
    echo "  ⚪ auth_middleware.go não encontrado"
fi

echo ""
echo "📦 2. Verificando dependências Go..."
echo "  🔄 Instalando dependências de autenticação..."
go get github.com/golang-jwt/jwt/v5
go get github.com/google/uuid
go get golang.org/x/crypto/bcrypt
go get github.com/go-playground/validator/v10

echo "  🔄 Organizando módulos..."
go mod tidy

echo ""
echo "📊 3. Verificando estrutura final..."
echo "  📁 Estrutura de internal/:"
ls -la internal/*/

echo ""
echo "🔧 4. Verificando arquivos de configuração..."
echo "  📄 .env existe: $([ -f .env ] && echo 'SIM' || echo 'NÃO')"
echo "  📄 docker-compose.yml existe: $([ -f docker-compose.yml ] && echo 'SIM' || echo 'NÃO')"
echo "  📄 cmd/server/main.go existe: $([ -f cmd/server/main.go ] && echo 'SIM' || echo 'NÃO')"

echo ""
echo "🧪 5. Testando compilação..."
if go build -o /tmp/test_build ./cmd/server; then
    echo "  ✅ Compilação bem-sucedida"
    rm -f /tmp/test_build
else
    echo "  ❌ Erro na compilação:"
    go build ./cmd/server 2>&1 | head -5
fi

echo ""
echo "📋 6. Status do ambiente Docker..."
echo "  🐳 Containers ativos:"
docker-compose ps | grep -E "postgres|api" || echo "    Nenhum container ativo"

echo ""
echo "✅ ORGANIZAÇÃO CONCLUÍDA!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Verificar se cmd/server/main.go precisa de atualização"
echo "2. Adicionar rotas de autenticação"
echo "3. Configurar JWT no config"
echo "4. Testar API completa"
echo ""
echo "🧪 Para testar autenticação:"
echo "   bash test_auth_system.sh"
echo ""
echo "🌐 Para acessar Swagger:"
echo "   http://localhost:8080/swagger/index.html"
