#!/bin/bash
echo "🔍 DESCOBRINDO ESTRUTURA REAL DO PROJETO"

echo "📂 Estrutura atual do diretório:"
find . -name "*.go" -type f | head -20

echo ""
echo "📋 Arquivos principais:"
echo "- main.go: $(find . -name "main.go" -type f | head -5)"
echo "- go.mod: $(find . -name "go.mod" -type f | head -3)"
echo "- docker-compose.yml: $([ -f docker-compose.yml ] && echo 'SIM' || echo 'NÃO')"

echo ""
echo "📂 Conteúdo do diretório atual:"
ls -la

echo ""
echo "🔍 Verificando docs/docs.go (versão macOS):"
if [ -f docs/docs.go ]; then
    echo "📏 Tamanho: $(wc -c < docs/docs.go) bytes"
    echo "📝 Linhas: $(wc -l < docs/docs.go)"
    echo ""
    echo "📋 Linha 40 (hexdump para ver caracteres especiais):"
    sed -n '40p' docs/docs.go | hexdump -C | head -3
    echo ""
    echo "📋 Linhas 39-42:"
    sed -n '39,42p' docs/docs.go | nl
else
    echo "❌ docs/docs.go não existe"
fi

echo ""
echo "📦 Verificando go.mod para entender o módulo:"
if [ -f go.mod ]; then
    echo "📋 go.mod encontrado:"
    head -5 go.mod
else
    echo "❌ go.mod não encontrado"
fi

echo ""
echo "🔧 Sugestões baseadas na estrutura encontrada:"
if [ -f main.go ]; then
    echo "✅ Usar: swag init -g main.go"
elif [ -f cmd/main.go ]; then
    echo "✅ Usar: swag init -g cmd/main.go"
elif find . -name "main.go" | head -1 >/dev/null; then
    main_path=$(find . -name "main.go" | head -1)
    echo "✅ Usar: swag init -g $main_path"
else
    echo "❌ Nenhum main.go encontrado"
fi
