#!/bin/bash
echo "🔍 VERIFICANDO STATUS DA API"

echo "🐳 1. Status dos containers Docker..."
docker-compose ps

echo ""
echo "📋 2. Verificando docker-compose.yml..."
if [ -f "docker-compose.yml" ]; then
    echo "  📄 docker-compose.yml existe"
    echo "  🔍 Serviços definidos:"
    grep -E "^  [a-zA-Z]" docker-compose.yml | sed 's/://' | sed 's/^/    ✅ /'
    
    echo ""
    echo "  🔍 Verificando se API está definida:"
    if grep -q "api:" docker-compose.yml; then
        echo "    ✅ Serviço 'api' encontrado"
        
        echo "  🔍 Porta da API:"
        grep -A 5 -B 5 "8080" docker-compose.yml | head -10
    else
        echo "    ❌ Serviço 'api' não encontrado"
        echo "    💡 API precisa ser adicionada ao docker-compose.yml"
    fi
else
    echo "  ❌ docker-compose.yml não encontrado"
fi

echo ""
echo "🔧 3. Verificando cmd/server/main.go..."
if [ -f "cmd/server/main.go" ]; then
    echo "  ✅ main.go existe"
    echo "  🔍 Verificando porta configurada:"
    grep -n "8080\|PORT\|Listen\|Run" cmd/server/main.go | head -5 || echo "    ⚪ Porta não encontrada explicitamente"
else
    echo "  ❌ cmd/server/main.go não encontrado"
fi

echo ""
echo "🌐 4. Verificando se algo está rodando na porta 8080..."
if command -v lsof >/dev/null 2>&1; then
    lsof_result=$(lsof -i :8080 2>/dev/null)
    if [ -n "$lsof_result" ]; then
        echo "  🔍 Processo na porta 8080:"
        echo "$lsof_result"
    else
        echo "  ⚪ Nada rodando na porta 8080"
    fi
else
    echo "  ⚪ lsof não disponível para verificar porta"
fi

echo ""
echo "🔧 5. Tentativas de correção sugeridas..."
echo "  📋 Opções disponíveis:"
echo "    1. docker-compose up -d api     # Se API estiver no docker-compose"
echo "    2. go run cmd/server/main.go    # Rodar manualmente"
echo "    3. Adicionar API ao docker-compose.yml"
echo "    4. Verificar se main.go está configurado corretamente"

echo ""
echo "✅ Verificação concluída!"
