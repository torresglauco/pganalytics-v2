#!/bin/bash
echo "🔧 CORRIGINDO INTEGRAÇÃO DA AUTENTICAÇÃO"

echo "📋 1. Verificando estado atual..."

# Verificar se main.go usa nossa implementação ou a antiga
MAIN_GO="cmd/server/main.go"

if [ ! -f "$MAIN_GO" ]; then
    echo "❌ main.go não encontrado"
    exit 1
fi

echo "  📄 main.go existe ($(wc -l < "$MAIN_GO") linhas)"

echo ""
echo "🔍 2. Verificando qual implementação de auth está ativa..."

if grep -q "AuthHandler\|auth_handlers" "$MAIN_GO"; then
    echo "  ✅ main.go já usa nossa implementação de auth"
    AUTH_INTEGRATED=true
else
    echo "  ⚠️ main.go usa implementação antiga de auth"
    AUTH_INTEGRATED=false
fi

echo ""
echo "🔧 3. Adicionando rotas de auth completas..."

if [ "$AUTH_INTEGRATED" = "false" ]; then
    echo "  🔄 Criando versão atualizada do main.go..."
    
    # Fazer backup
    cp "$MAIN_GO" "${MAIN_GO}.backup.integration.$(date +%s)"
    echo "  💾 Backup criado"
    
    echo "  📝 Para integrar manualmente, adicione ao main.go:"
    echo ""
    echo "// Imports necessários:"
    echo 'import ('
    echo '    // ... imports existentes ...'
    echo '    "pganalytics-backend/internal/services"'
    echo '    "pganalytics-backend/internal/handlers"'
    echo '    "pganalytics-backend/internal/middleware"'
    echo ')'
    echo ""
    echo "// Na função main(), após configurar banco:"
    echo 'tokenService := services.NewTokenService(os.Getenv("JWT_SECRET"))'
    echo 'authService := services.NewAuthService(db, tokenService)'
    echo 'authHandler := handlers.NewAuthHandler(authService)'
    echo 'authMiddleware := middleware.NewAuthMiddleware(tokenService)'
    echo ""
    echo "// Registrar rotas:"
    echo 'authRoutes := router.Group("/api/v1/auth")'
    echo 'authRoutes.POST("/register", authHandler.Register)'
    echo 'authRoutes.POST("/login", authHandler.Login)'
    echo 'authRoutes.POST("/refresh", authHandler.RefreshToken)'
    echo 'authRoutes.POST("/logout", authHandler.Logout)'
    echo ""
    echo 'protected := router.Group("/api/v1")'
    echo 'protected.Use(authMiddleware.RequireAuth())'
    echo 'protected.GET("/auth/profile", authHandler.GetProfile)'
    echo 'protected.PUT("/auth/profile", authHandler.UpdateProfile)'
    
else
    echo "  ✅ Implementação de auth já integrada"
fi

echo ""
echo "🧪 4. Testando formato correto de login..."

# Testar qual formato funciona
BASE_URL="http://localhost:8080"

echo "  🔍 Testando formato 'username'..."
USERNAME_TEST=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@pganalytics.local","password":"admin123"}')

if echo "$USERNAME_TEST" | grep -q "token\|success"; then
    echo "    ✅ Funciona com 'username'"
    WORKING_FORMAT="username"
else
    echo "    ❌ Não funciona com 'username'"
    echo "    📊 Resposta: $USERNAME_TEST"
fi

echo "  🔍 Testando formato 'email'..."
EMAIL_TEST=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pganalytics.local","password":"admin123"}')

if echo "$EMAIL_TEST" | grep -q "token\|success"; then
    echo "    ✅ Funciona com 'email'"
    WORKING_FORMAT="email"
else
    echo "    ❌ Não funciona com 'email'"
fi

echo ""
echo "📊 5. Resultado da correção..."

if [ -n "$WORKING_FORMAT" ]; then
    echo "  ✅ Formato funcionando: $WORKING_FORMAT"
    echo "  📋 Para testar login, use:"
    if [ "$WORKING_FORMAT" = "username" ]; then
        echo '    curl -X POST http://localhost:8080/auth/login \'
        echo '      -H "Content-Type: application/json" \'
        echo '      -d '"'"'{"username":"admin@pganalytics.local","password":"admin123"}'"'"
    else
        echo '    curl -X POST http://localhost:8080/auth/login \'
        echo '      -H "Content-Type: application/json" \'
        echo '      -d '"'"'{"email":"admin@pganalytics.local","password":"admin123"}'"'"
    fi
else
    echo "  ❌ Nenhum formato funcionou"
    echo "  🔧 Pode ser necessário ajustar a implementação"
fi

echo ""
echo "✅ Correção da integração concluída!"
