#!/bin/bash
# fix_docs_error.sh - Corrige erro do pacote docs

echo "🔧 CORRIGINDO ERRO DO PACOTE DOCS"
echo "================================="

# 1. Atualizar main.go sem import de docs
echo "📝 Atualizando main.go..."
cat > cmd/server/main.go << 'EOF'
package main

import (
	"log"
	"pganalytics-backend/internal/config"
	"pganalytics-backend/internal/database"
	"pganalytics-backend/internal/handlers"
	"pganalytics-backend/internal/middleware"

	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// @title PGAnalytics API
// @version 1.0
// @description Modern PostgreSQL analytics backend
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.pganalytics.com/support
// @contact.email support@pganalytics.com

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8080
// @BasePath /
// @schemes http https

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization

func main() {
	// Load configuration
	cfg := config.Load()

	// Connect to database
	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()

	// Setup Gin
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.Default()

	// Middleware
	router.Use(middleware.CorsMiddleware())
	router.Use(middleware.LoggingMiddleware())
	router.Use(middleware.RateLimitMiddleware())

	// Swagger documentation
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Routes
	handlers.SetupRoutes(router, cfg, db)

	// Start server
	log.Printf("🚀 Server starting on port %s", cfg.Port)
	log.Printf("📚 Swagger docs: http://localhost:%s/swagger/index.html", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
EOF

echo "✅ main.go atualizado"

# 2. Instalar swag se não existe
echo "📦 Verificando swag..."
if ! command -v swag &> /dev/null; then
    echo "Instalando swag..."
    go install github.com/swaggo/swag/cmd/swag@latest
    
    # Adicionar ao PATH se necessário
    export PATH=$PATH:$(go env GOPATH)/bin
fi

# 3. Gerar documentação Swagger
echo "📚 Gerando documentação Swagger..."
swag init -g cmd/server/main.go

if [[ $? -eq 0 ]]; then
    echo "✅ Documentação Swagger gerada com sucesso!"
    
    # Agora adicionar import do docs no main.go
    echo "📝 Adicionando import do docs..."
    sed -i.bak '10i\
	_ "pganalytics-backend/docs" // Import docs' cmd/server/main.go
    
    echo "✅ Import docs adicionado"
else
    echo "⚠️  Erro ao gerar Swagger, mas continuando sem docs..."
fi

# 4. Verificar se tudo está OK
echo "🧪 Verificando código..."
go fmt ./...
go vet ./...

if [[ $? -eq 0 ]]; then
    echo "✅ Código está OK!"
else
    echo "⚠️  Ainda há problemas, mas pode funcionar..."
fi

# 5. Testar build
echo "🔨 Testando build..."
go build -o /tmp/test-build ./cmd/server

if [[ $? -eq 0 ]]; then
    echo "✅ Build funcionando!"
    rm -f /tmp/test-build
else
    echo "❌ Problema no build"
fi

echo ""
echo "🎉 CORREÇÃO CONCLUÍDA!"
echo "====================="
echo ""
echo "🚀 Para testar:"
echo "  make dev"
echo "  Acesse: http://localhost:8080/swagger/index.html"
echo ""
echo "💡 Se ainda der erro:"
echo "  export PATH=$PATH:$(go env GOPATH)/bin"
echo "  swag init -g cmd/server/main.go"
