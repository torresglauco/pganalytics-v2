#!/bin/bash
echo "🚨 CORREÇÃO DE EMERGÊNCIA DO SWAGGER (COMANDOS CORRETOS)"

# Para o container se estiver rodando
docker-compose down 2>/dev/null || true

# Remove arquivos corrompidos
echo "🧹 Limpando arquivos corrompidos..."
rm -rf docs/
rm -f docs.go

# Cria estrutura docs
mkdir -p docs

echo "📝 Criando docs.go manual (método seguro)..."

# Cria um docs.go básico que funciona
cat > docs/docs.go << 'EOFMANUAL'
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
                        "description": "OK"
                    }
                }
            }
        },
        "/auth/login": {
            "post": {
                "description": "Login user",
                "produces": ["application/json"],
                "tags": ["auth"],
                "summary": "Login",
                "responses": {
                    "200": {
                        "description": "OK"
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
EOFMANUAL

echo "📄 Criando swagger.json..."
cat > docs/swagger.json << 'EOFJSON'
{
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
                        "description": "OK"
                    }
                }
            }
        }
    }
}
EOFJSON

echo "🔧 Verificando sintaxe com gofmt..."
if gofmt -e docs/docs.go > /dev/null 2>&1; then
    echo "✅ docs.go sintaxe OK"
else
    echo "❌ Erro de sintaxe detectado:"
    gofmt -e docs/docs.go 2>&1
fi

echo "🔍 Verificando com go vet..."
if go vet ./docs/... 2>/dev/null; then
    echo "✅ go vet passou"
else
    echo "⚠️ go vet encontrou problemas (mas pode ser normal para docs)"
fi

echo "🔨 Testando build..."
if go build -o /tmp/test ./cmd 2>/dev/null; then
    echo "✅ Build bem-sucedido!"
    rm -f /tmp/test
    echo "🚀 Iniciando containers..."
    docker-compose up -d
    
    echo ""
    echo "⏳ Aguardando inicialização..."
    sleep 5
    
    echo "🧪 Testando endpoints:"
    echo "Health: $(curl -s http://localhost:8080/health 2>/dev/null || echo 'Não disponível ainda')"
    echo "Swagger: $(curl -s -I http://localhost:8080/swagger/index.html 2>/dev/null | head -1 || echo 'Não disponível ainda')"
else
    echo "❌ Erro no build:"
    go build ./cmd 2>&1 | head -10
fi

echo ""
echo "🌐 Acesse: http://localhost:8080/swagger/index.html"
echo "🏥 Health: http://localhost:8080/health"
