#!/bin/bash
echo "🔐 VERIFICANDO INTEGRAÇÃO DA AUTENTICAÇÃO"

echo "📊 1. Verificando arquivos de autenticação..."
echo "  📄 Models:"
[ -f "internal/models/user_models.go" ] && echo "    ✅ user_models.go" || echo "    ❌ user_models.go"

echo "  🔧 Services:"
[ -f "internal/services/token_service.go" ] && echo "    ✅ token_service.go" || echo "    ❌ token_service.go"
[ -f "internal/services/auth_service.go" ] && echo "    ✅ auth_service.go" || echo "    ❌ auth_service.go"

echo "  🌐 Handlers:"
[ -f "internal/handlers/auth_handlers.go" ] && echo "    ✅ auth_handlers.go" || echo "    ❌ auth_handlers.go"

echo "  🛡️ Middleware:"
[ -f "internal/middleware/auth_middleware.go" ] && echo "    ✅ auth_middleware.go" || echo "    ❌ auth_middleware.go"

echo ""
echo "🔍 2. Verificando se main.go usa autenticação..."
if grep -q "internal/services\|internal/handlers\|auth" cmd/server/main.go; then
    echo "  ✅ main.go importa módulos de auth"
    
    echo "  🔍 Imports encontrados:"
    grep -n "internal/" cmd/server/main.go | head -5 | sed 's/^/    /'
else
    echo "  ⚠️ main.go pode não estar usando módulos de auth completos"
fi

echo ""
echo "🌐 3. Verificando rotas de autenticação disponíveis..."

# Testar rotas que deveriam existir
auth_routes=("/auth/login" "/auth/register" "/auth/refresh" "/auth/logout" "/auth/profile")

for route in "${auth_routes[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" -X GET "http://localhost:8080$route" 2>/dev/null)
    if [ "$status" = "404" ]; then
        echo "  ❌ $route (HTTP $status) - não implementada"
    elif [ "$status" = "405" ]; then
        echo "  ✅ $route (HTTP $status) - existe mas método incorreto"
    elif [ "$status" = "400" ] || [ "$status" = "401" ]; then
        echo "  ✅ $route (HTTP $status) - existe e funcional"
    else
        echo "  ⚪ $route (HTTP $status)"
    fi
done

echo ""
echo "📊 4. Testando endpoints específicos..."

# Testar registro
echo "  📝 Testando registro de novo usuário..."
REGISTER_TEST=$(curl -s -X POST "http://localhost:8080/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}' 2>/dev/null)

if echo "$REGISTER_TEST" | grep -q "error\|Error\|404\|405"; then
    echo "    ⚠️ Endpoint /auth/register pode não estar implementado"
    echo "    📊 Resposta: $REGISTER_TEST"
else
    echo "    ✅ Endpoint /auth/register responde"
fi

# Testar profile (deve dar 401 sem token)
echo "  👤 Testando perfil (sem autenticação)..."
PROFILE_TEST=$(curl -s "http://localhost:8080/auth/profile" 2>/dev/null)
if echo "$PROFILE_TEST" | grep -q "401\|Unauthorized\|token"; then
    echo "    ✅ Endpoint /auth/profile protegido corretamente"
else
    echo "    ⚠️ Endpoint /auth/profile: $PROFILE_TEST"
fi

echo ""
echo "🔧 5. Recomendações..."

echo "  📋 Se alguns endpoints não existem, você pode:"
echo "    1. Verificar se main.go importa todos os handlers"
echo "    2. Adicionar rotas de auth manualmente"
echo "    3. Usar o exemplo em MAIN_GO_INTEGRATION.md"
echo "    4. Executar: bash update_main_go.sh"

echo ""
echo "✅ Verificação de integração concluída!"
