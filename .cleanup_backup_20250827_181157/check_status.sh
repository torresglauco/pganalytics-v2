#!/bin/bash
# check_status.sh - Verifica o que realmente temos

echo "🔍 VERIFICANDO STATUS REAL DO PROJETO"
echo "====================================="

echo "1. 🏗️  Estrutura do projeto:"
echo "cmd/server/main.go: $(test -f cmd/server/main.go && echo '✅ Existe' || echo '❌ Não existe')"
echo "internal/: $(test -d internal && echo '✅ Existe' || echo '❌ Não existe')"
echo "docs/: $(test -d docs && echo '✅ Existe' || echo '❌ Não existe')"

echo ""
echo "2. 📦 Dependências:"
go list -m github.com/gin-gonic/gin 2>/dev/null && echo "✅ Gin instalado" || echo "❌ Gin não encontrado"
go list -m github.com/swaggo/gin-swagger 2>/dev/null && echo "✅ Gin-Swagger instalado" || echo "❌ Gin-Swagger não encontrado"

echo ""
echo "3. 🛠️  Ferramentas:"
command -v swag &>/dev/null && echo "✅ swag disponível" || echo "❌ swag não encontrado"

echo ""
echo "4. 📚 Documentação Swagger:"
if [[ -f "docs/swagger.json" ]]; then
    echo "✅ swagger.json gerado"
elif [[ -f "docs/swagger.yaml" ]]; then
    echo "✅ swagger.yaml gerado"
else
    echo "❌ Documentação Swagger não gerada"
fi

echo ""
echo "5. 🧪 Testando endpoints:"
if curl -s http://localhost:8080/health &>/dev/null; then
    echo "✅ API está rodando"
    
    echo "  Health: $(curl -s http://localhost:8080/health | jq -r '.status // "❌"')"
    
    # Testar Swagger
    if curl -s http://localhost:8080/swagger/index.html | grep -q "Swagger"; then
        echo "  ✅ Swagger UI funcionando"
    else
        echo "  ❌ Swagger UI não funcionando"
    fi
else
    echo "❌ API não está rodando (execute 'make run' ou 'make dev')"
fi

echo ""
echo "6. 📋 Resumo do que temos:"
echo "================================"

# Verificar conteúdo do main.go
if [[ -f "cmd/server/main.go" ]]; then
    if grep -q "@Summary" cmd/server/main.go; then
        echo "✅ Anotações Swagger detalhadas"
    else
        echo "⚠️  Anotações Swagger básicas apenas"
    fi
    
    if grep -q "AuthMiddleware" cmd/server/main.go; then
        echo "✅ Middleware de autenticação"
    else
        echo "❌ Sem middleware de autenticação"
    fi
    
    if grep -q "/api/metrics" cmd/server/main.go; then
        echo "✅ Endpoints completos"
    else
        echo "⚠️  Endpoints básicos apenas"
    fi
fi

echo ""
echo "🎯 CONCLUSÃO:"
echo "============="
echo "Temos uma API BÁSICA funcionando, mas não todas as funcionalidades prometidas."
echo "Para ter TUDO funcionando, precisa executar as melhorias completas."
