# 🔍 COMANDOS PARA VERIFICAR O PROBLEMA ATUAL

# 1. Ver o erro específico no docs.go
echo "=== VERIFICANDO docs/docs.go ==="
if [ -f docs/docs.go ]; then
    echo "📄 Arquivo existe. Linhas com problema:"
    sed -n '38,45p' docs/docs.go
    echo ""
    echo "🔍 Teste de sintaxe:"
    gofmt -e docs/docs.go 2>&1 | head -5
else
    echo "❌ docs/docs.go não existe"
fi

# 2. Ver logs do Docker atual
echo ""
echo "=== LOGS DO DOCKER ==="
docker-compose logs api 2>/dev/null | tail -10

# 3. Status dos containers
echo ""
echo "=== STATUS DOS CONTAINERS ==="
docker-compose ps

# 4. Verificar se swag está disponível
echo ""
echo "=== VERIFICAR SWAG ==="
which swag || echo "❌ swag não instalado"
swag --version 2>/dev/null || echo "❌ swag não funcional"
