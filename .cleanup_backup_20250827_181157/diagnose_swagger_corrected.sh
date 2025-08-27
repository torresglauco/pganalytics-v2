#!/bin/bash
echo "🔍 Diagnóstico do erro Swagger docs.go..."

echo "📊 Status dos arquivos:"
echo "- docs/ existe: $([ -d docs ] && echo 'SIM' || echo 'NÃO')"
echo "- docs/docs.go existe: $([ -f docs/docs.go ] && echo 'SIM' || echo 'NÃO')"
echo "- docs/swagger.json existe: $([ -f docs/swagger.json ] && echo 'SIM' || echo 'NÃO')"

if [ -f docs/docs.go ]; then
    echo ""
    echo "🔍 Analisando docs/docs.go..."
    echo "📏 Tamanho: $(wc -c < docs/docs.go) bytes"
    echo "📝 Linhas: $(wc -l < docs/docs.go)"
    
    echo ""
    echo "🚨 Problemas detectados:"
    
    # Verifica quebras de linha em strings
    if grep -n '".*$' docs/docs.go | grep -v '".*".*$' > /dev/null; then
        echo "❌ Strings com quebras de linha detectadas:"
        grep -n '".*$' docs/docs.go | grep -v '".*".*$' | head -5
    fi
    
    # Verifica caracteres de escape problemáticos
    if grep -n '\\\\' docs/docs.go > /dev/null; then
        echo "❌ Caracteres de escape duplicados detectados:"
        grep -n '\\\\' docs/docs.go | head -3
    fi
    
    # Verifica caracteres inválidos (ASCII)
    if file docs/docs.go | grep -q "UTF-8.*BOM\|UTF-16\|UTF-32"; then
        echo "❌ Encoding não-ASCII detectado"
    fi
    
    echo ""
    echo "📋 Teste de sintaxe Go:"
    echo "--- gofmt check ---"
    if gofmt -e docs/docs.go > /dev/null 2>&1; then
        echo "✅ Sintaxe gofmt válida"
    else
        echo "❌ Erro de sintaxe gofmt:"
        gofmt -e docs/docs.go 2>&1 | head -5
    fi
    
    echo "--- go build check ---"
    if go build -o /tmp/testbuild docs/docs.go 2>/dev/null; then
        echo "✅ Build isolado bem-sucedido"
        rm -f /tmp/testbuild
    else
        echo "❌ Erro no build isolado:"
        go build docs/docs.go 2>&1 | head -5
    fi
fi

echo ""
echo "🔧 Comandos de correção sugeridos:"
echo "1. ./emergency_swagger_fix_corrected.sh  # Correção automática"
echo "2. rm -rf docs && swag init -g cmd/main.go -o docs/  # Regeneração"
echo "3. gofmt -w docs/docs.go  # Formatar código"
echo "4. go mod tidy && go build ./cmd  # Teste final"

echo ""
echo "📋 Verificação dos erros no log do Docker:"
if docker-compose logs api 2>/dev/null | tail -10 | grep -q "docs.go"; then
    echo "❌ Erros do docs.go no log do Docker:"
    docker-compose logs api 2>/dev/null | grep "docs.go" | tail -5
else
    echo "ℹ️ Nenhum erro específico do docs.go nos logs recentes"
fi
