#!/bin/bash
echo "🔧 CORREÇÃO COMPLETA DO SWAGGER - Instalação + Correção"

echo "📦 1. Instalando swag..."
go install github.com/swaggo/swag/cmd/swag@latest

# Verifica se PATH está correto
export PATH=$PATH:$(go env GOPATH)/bin

echo "✅ swag instalado. Versão:"
swag --version 2>/dev/null || echo "⚠️ swag pode precisar de PATH atualizado"

echo ""
echo "🔍 2. Analisando problema específico nas linhas 40-41..."
if [ -f docs/docs.go ]; then
    echo "📋 Linhas 38-45 (contexto do erro):"
    sed -n '38,45p' docs/docs.go
    echo ""
    echo "📋 Linha 40 específica:"
    sed -n '40p' docs/docs.go | cat -A
    echo ""
    echo "📋 Linha 41 específica:"
    sed -n '41p' docs/docs.go | cat -A
fi

echo ""
echo "🧹 3. Limpando e regenerando documentação..."
docker-compose down 2>/dev/null

# Backup do arquivo atual
if [ -f docs/docs.go ]; then
    cp docs/docs.go docs/docs.go.backup.$(date +%s)
fi

# Remove documentação corrompida
rm -rf docs/

echo ""
echo "📝 4. Gerando nova documentação com swag..."
mkdir -p docs

# Gera documentação nova
if command -v swag >/dev/null 2>&1; then
    echo "✅ Usando swag para gerar docs..."
    swag init -g cmd/main.go -o docs/ --parseDependency --parseInternal
    
    if [ -f docs/docs.go ]; then
        echo "✅ docs.go gerado com sucesso"
        
        # Testa sintaxe
        if gofmt -e docs/docs.go >/dev/null 2>&1; then
            echo "✅ Sintaxe válida"
        else
            echo "❌ Problema de sintaxe detectado, usando fallback manual"
            rm -f docs/docs.go
        fi
    else
        echo "❌ swag falhou, usando método manual"
    fi
else
    echo "⚠️ swag não disponível, usando método manual"
fi

# Fallback: criar docs.go manual se não existir
if [ ! -f docs/docs.go ]; then
    echo "📝 5. Criando docs.go manual..."
    cat > docs/docs.go << 'EOF'
package docs

import "github.com/swaggo/swag"

const docTemplate = `{
    "swagger": "2.0",
    "info": {
        "description": "PostgreSQL Analytics API - Sistema de análise de desempenho PostgreSQL",
        "title": "PG Analytics API",
        "contact": {},
        "version": "1.0"
    },
    "host": "localhost:8080",
    "basePath": "/api/v1",
    "paths": {
        "/health": {
            "get": {
                "description": "Endpoint de verificação de saúde da aplicação",
                "produces": ["application/json"],
                "tags": ["health"],
                "summary": "Health Check",
                "responses": {
                    "200": {
                        "description": "OK",
                        "schema": {
                            "type": "object",
                            "properties": {
                                "status": {"type": "string"},
                                "timestamp": {"type": "string"}
                            }
                        }
                    }
                }
            }
        },
        "/auth/login": {
            "post": {
                "description": "Autenticação de usuário no sistema",
                "produces": ["application/json"],
                "tags": ["auth"],
                "summary": "Login de usuário",
                "parameters": [{
                    "description": "Credenciais de login",
                    "name": "credentials",
                    "in": "body",
                    "required": true,
                    "schema": {
                        "type": "object",
                        "properties": {
                            "email": {"type": "string"},
                            "password": {"type": "string"}
                        }
                    }
                }],
                "responses": {
                    "200": {
                        "description": "Login bem-sucedido",
                        "schema": {
                            "type": "object",
                            "properties": {
                                "token": {"type": "string"},
                                "user": {"type": "object"}
                            }
                        }
                    },
                    "401": {
                        "description": "Credenciais inválidas"
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
    Description:      "PostgreSQL Analytics API - Sistema de análise de desempenho PostgreSQL",
    InfoInstanceName: "swagger",
    SwaggerTemplate:  docTemplate,
}

func init() {
    swag.Register(SwaggerInfo.InstanceName(), SwaggerInfo)
}
EOF
fi

echo ""
echo "🔧 6. Verificando sintaxe final..."
if gofmt -e docs/docs.go >/dev/null 2>&1; then
    echo "✅ Sintaxe do docs.go válida"
else
    echo "❌ Ainda há problemas de sintaxe:"
    gofmt -e docs/docs.go 2>&1 | head -5
    exit 1
fi

echo ""
echo "🔨 7. Testando build..."
if go build -o /tmp/test_pganalytics ./cmd; then
    echo "✅ Build bem-sucedido!"
    rm -f /tmp/test_pganalytics
else
    echo "❌ Erro no build:"
    go build ./cmd 2>&1 | head -10
    exit 1
fi

echo ""
echo "🚀 8. Iniciando ambiente..."
docker-compose up -d

echo ""
echo "⏳ 9. Aguardando inicialização (10 segundos)..."
sleep 10

echo ""
echo "🧪 10. Testando endpoints:"
echo "🏥 Health check:"
curl -s http://localhost:8080/health | head -c 200 || echo "❌ Health não disponível"

echo ""
echo "📚 Swagger UI:"
curl -s -I http://localhost:8080/swagger/index.html | head -1 || echo "❌ Swagger não disponível"

echo ""
echo "📊 Status dos containers:"
docker-compose ps

echo ""
echo "✅ CORREÇÃO COMPLETA!"
echo "🌐 Acesse: http://localhost:8080/swagger/index.html"
echo "🏥 Health: http://localhost:8080/health"
echo ""
echo "📋 Se ainda houver problemas, verifique:"
echo "- docker-compose logs api"
echo "- ls -la docs/"
echo "- cat docs/docs.go | head -50"
