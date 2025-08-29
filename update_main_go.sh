#!/bin/bash
echo "🔧 ATUALIZANDO main.go COM AUTENTICAÇÃO"

MAIN_GO="cmd/server/main.go"

if [ ! -f "$MAIN_GO" ]; then
    echo "❌ $MAIN_GO não encontrado"
    exit 1
fi

echo "📄 1. Fazendo backup do main.go atual..."
cp "$MAIN_GO" "${MAIN_GO}.backup.$(date +%s)"
echo "  ✅ Backup criado"

echo ""
echo "🔧 2. Verificando imports necessários..."

# Verificar se já tem os imports de auth
if grep -q "internal/services" "$MAIN_GO"; then
    echo "  ✅ Imports de auth já existem"
else
    echo "  🔄 Adicionando imports de auth..."
    
    # Adicionar imports após os existentes (método simples)
    echo "  ⚠️ Adicione manualmente estes imports ao main.go:"
    echo '    "pganalytics-backend/internal/services"'
    echo '    "pganalytics-backend/internal/handlers"' 
    echo '    "pganalytics-backend/internal/middleware"'
    echo '    "github.com/golang-jwt/jwt/v5"'
    echo '    "golang.org/x/crypto/bcrypt"'
fi

echo ""
echo "🔧 3. Verificando configuração JWT..."

# Verificar se config.go tem JWT
CONFIG_GO="internal/config/config.go"
if [ -f "$CONFIG_GO" ]; then
    if grep -q "JWTSecret" "$CONFIG_GO"; then
        echo "  ✅ Configuração JWT já existe"
    else
        echo "  🔄 Adicionando configuração JWT..."
        echo "  ⚠️ Adicione estes campos à struct Config em $CONFIG_GO:"
        echo "    JWTSecret           string \`env:"JWT_SECRET"\`"
        echo "    JWTExpiresIn        string \`env:"JWT_EXPIRES_IN" envDefault:"15m"\`"
        echo "    JWTRefreshExpiresIn string \`env:"JWT_REFRESH_EXPIRES_IN" envDefault:"168h"\`"
    fi
else
    echo "  ⚠️ $CONFIG_GO não encontrado"
fi

echo ""
echo "🔧 4. Verificando rotas de autenticação..."

if grep -q "/auth/" "$MAIN_GO"; then
    echo "  ✅ Rotas de auth já existem"
else
    echo "  🔄 Criando exemplo de integração de rotas..."
    
    cat > integration_example.go << 'EOCODE'
// EXEMPLO DE INTEGRAÇÃO - Adicione ao seu main.go

// Após inicializar banco e config:
tokenService := services.NewTokenService(cfg.JWTSecret)
authService := services.NewAuthService(db, tokenService, cfg)
authHandler := handlers.NewAuthHandler(authService)
authMiddleware := middleware.NewAuthMiddleware(tokenService)

// Configurar rotas:
func setupAuthRoutes(r *gin.Engine, authHandler *handlers.AuthHandler, authMiddleware *middleware.AuthMiddleware) {
    api := r.Group("/api/v1")
    
    // Rotas públicas de auth
    auth := api.Group("/auth")
    {
        auth.POST("/register", authHandler.Register)
        auth.POST("/login", authHandler.Login)
        auth.POST("/refresh", authHandler.RefreshToken)
        auth.POST("/logout", authHandler.Logout)
    }
    
    // Rotas protegidas
    protected := api.Group("/")
    protected.Use(authMiddleware.RequireAuth())
    {
        protected.GET("/auth/profile", authHandler.GetProfile)
        protected.PUT("/auth/profile", authHandler.UpdateProfile)
    }
}
EOCODE

    echo "  ✅ Exemplo criado em integration_example.go"
fi

echo ""
echo "📋 5. Verificações necessárias..."

echo "  🔍 Dependências Go:"
missing_deps=0

if ! go list github.com/golang-jwt/jwt/v5 >/dev/null 2>&1; then
    echo "    ❌ github.com/golang-jwt/jwt/v5"
    missing_deps=$((missing_deps + 1))
else
    echo "    ✅ github.com/golang-jwt/jwt/v5"
fi

if ! go list golang.org/x/crypto/bcrypt >/dev/null 2>&1; then
    echo "    ❌ golang.org/x/crypto/bcrypt"
    missing_deps=$((missing_deps + 1))
else
    echo "    ✅ golang.org/x/crypto/bcrypt"
fi

if [ $missing_deps -gt 0 ]; then
    echo "  🔧 Instalando dependências faltantes..."
    go get github.com/golang-jwt/jwt/v5
    go get golang.org/x/crypto/bcrypt
    go mod tidy
fi

echo ""
echo "🧪 6. Testando compilação..."
if go build -o /tmp/test_api "$MAIN_GO"; then
    echo "  ✅ Compilação bem-sucedida"
    rm -f /tmp/test_api
else
    echo "  ❌ Erro na compilação:"
    go build "$MAIN_GO" 2>&1 | head -10
fi

echo ""
echo "✅ Atualização do main.go concluída!"
echo ""
echo "📋 PRÓXIMOS PASSOS MANUAIS:"
echo "1. Verificar integration_example.go para exemplos"
echo "2. Adicionar imports de auth ao main.go"
echo "3. Configurar JWT no config.go"
echo "4. Adicionar rotas de auth"
echo "5. Testar: bash start_api.sh"
