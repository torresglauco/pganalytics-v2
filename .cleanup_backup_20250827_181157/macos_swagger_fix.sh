#!/bin/bash
echo "🔧 CORREÇÃO SWAGGER PARA macOS - Estrutura Real"

echo "🔍 1. Descobrindo estrutura do projeto..."

# Encontra o main.go
MAIN_GO=$(find . -name "main.go" -type f | head -1)
if [ -n "$MAIN_GO" ]; then
    echo "✅ main.go encontrado em: $MAIN_GO"
    MAIN_DIR=$(dirname "$MAIN_GO")
else
    echo "❌ main.go não encontrado. Listando arquivos .go:"
    find . -name "*.go" -type f | head -10
    echo ""
    echo "🔧 Criando main.go básico..."
    mkdir -p cmd
    cat > cmd/main.go << 'EOFMAIN'
package main

import (
    "log"
    "net/http"
    
    "github.com/gin-gonic/gin"
    swaggerFiles "github.com/swaggo/files"
    ginSwagger "github.com/swaggo/gin-swagger"
    
    _ "pganalytics/docs"
)

// @title PG Analytics API
// @version 1.0
// @description PostgreSQL Analytics API
// @host localhost:8080
// @BasePath /api/v1
func main() {
    r := gin.Default()
    
    // Health endpoint
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "ok"})
    })
    
    // Swagger endpoint
    r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))
    
    log.Println("Server starting on :8080")
    r.Run(":8080")
}
EOFMAIN
    MAIN_GO="cmd/main.go"
fi

echo ""
echo "🧹 2. Limpando documentação anterior..."
docker-compose down 2>/dev/null || true
rm -rf docs/

echo ""
echo "📝 3. Gerando documentação com estrutura correta..."
mkdir -p docs

# Tenta gerar com swag
if command -v swag >/dev/null 2>&1; then
    echo "✅ Gerando com swag init -g $MAIN_GO..."
    if swag init -g "$MAIN_GO" -o docs/ --parseDependency --parseInternal 2>/dev/null; then
        echo "✅ Documentação gerada com sucesso"
    else
        echo "⚠️ swag falhou, usando método manual"
        rm -rf docs/docs.go 2>/dev/null
    fi
fi

# Cria docs.go manual se necessário
if [ ! -f docs/docs.go ]; then
    echo "📝 4. Criando docs.go manual para macOS..."
    cat > docs/docs.go << 'EOFDOCS'
package docs

import "github.com/swaggo/swag"

const docTemplate = `{
    "swagger": "2.0",
    "info": {
        "description": "PostgreSQL Analytics API",
        "title": "PG Analytics API",
        "contact": {},
        "version": "1.0"
    },
    "host": "localhost:8080",
    "basePath": "/api/v1",
    "paths": {
        "/health": {
            "get": {
                "description": "Health check endpoint",
                "produces": ["application/json"],
                "tags": ["health"],
                "summary": "Health check",
                "responses": {
                    "200": {
                        "description": "OK",
                        "schema": {
                            "type": "object",
                            "properties": {
                                "status": {
                                    "type": "string"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}`

var SwaggerInfo = &swag.Spec{
    Version:          "1.0",
    Host:             "localhost:8080",
    BasePath:         "/api/v1",
    Schemes:          []string{},
    Title:            "PG Analytics API",
    Description:      "PostgreSQL Analytics API",
    InfoInstanceName: "swagger",
    SwaggerTemplate:  docTemplate,
}

func init() {
    swag.Register(SwaggerInfo.InstanceName(), SwaggerInfo)
}
EOFDOCS
fi

echo ""
echo "🔧 5. Verificando sintaxe (macOS)..."
if gofmt -e docs/docs.go >/dev/null 2>&1; then
    echo "✅ Sintaxe válida"
else
    echo "❌ Erro de sintaxe:"
    gofmt -e docs/docs.go 2>&1 | head -5
fi

echo ""
echo "📦 6. Verificando/Criando go.mod..."
if [ ! -f go.mod ]; then
    echo "📝 Criando go.mod..."
    go mod init pganalytics
    echo "✅ go.mod criado"
fi

echo "📋 Adicionando dependências necessárias..."
go mod tidy 2>/dev/null || true

echo ""
echo "🔨 7. Testando build..."
BUILD_TARGET=$(dirname "$MAIN_GO")
if go build -o /tmp/test_app "./$BUILD_TARGET"; then
    echo "✅ Build bem-sucedido!"
    rm -f /tmp/test_app
else
    echo "❌ Erro no build:"
    go build "./$BUILD_TARGET" 2>&1 | head -10
    
    echo ""
    echo "🔧 Tentando corrigir dependências..."
    go get github.com/gin-gonic/gin
    go get github.com/swaggo/files
    go get github.com/swaggo/gin-swagger
    go get github.com/swaggo/swag
    go mod tidy
    
    if go build -o /tmp/test_app "./$BUILD_TARGET"; then
        echo "✅ Build corrigido!"
        rm -f /tmp/test_app
    else
        echo "❌ Build ainda falha"
    fi
fi

echo ""
echo "🚀 8. Iniciando ambiente..."
if [ -f docker-compose.yml ]; then
    docker-compose up -d
    echo "⏳ Aguardando 5 segundos..."
    sleep 5
    
    echo "🧪 Testando endpoints:"
    curl -s http://localhost:8080/health 2>/dev/null | head -c 100 || echo "Health não disponível"
    echo ""
    curl -s -I http://localhost:8080/swagger/index.html 2>/dev/null | head -1 || echo "Swagger não disponível"
else
    echo "⚠️ docker-compose.yml não encontrado"
    echo "📋 Para testar localmente: go run $MAIN_GO"
fi

echo ""
echo "✅ CORREÇÃO CONCLUÍDA!"
echo "🌐 Swagger: http://localhost:8080/swagger/index.html"
echo "🏥 Health: http://localhost:8080/health"
