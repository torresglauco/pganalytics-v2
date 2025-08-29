#!/bin/bash
echo "🚀 INICIANDO API DO PGANALYTICS"

echo "🔍 1. Verificando se API está definida no docker-compose..."
if grep -q "api:" docker-compose.yml 2>/dev/null; then
    echo "  ✅ Serviço API encontrado no docker-compose"
    echo "  🚀 Tentando iniciar via Docker..."
    
    if docker-compose up -d api; then
        echo "  ✅ API iniciada via Docker"
        
        echo "  ⏳ Aguardando inicialização (10 segundos)..."
        sleep 10
        
        # Verificar se subiu
        if curl -s http://localhost:8080/health >/dev/null 2>&1; then
            echo "  ✅ API respondendo na porta 8080"
        else
            echo "  ⚠️ API pode estar iniciando ainda, verifique logs:"
            echo "     docker-compose logs api"
        fi
    else
        echo "  ❌ Falha ao iniciar API via Docker"
        echo "  📋 Tentando método manual..."
    fi
else
    echo "  ⚪ Serviço API não encontrado no docker-compose"
    echo "  📋 Tentando iniciar manualmente..."
fi

echo ""
echo "🔧 2. Método alternativo: Executar manualmente..."
if [ -f "cmd/server/main.go" ]; then
    echo "  📄 main.go encontrado"
    echo "  🔄 Verificando dependências..."
    
    if go mod tidy; then
        echo "    ✅ Dependências OK"
        
        echo "  🚀 Iniciando API manualmente..."
        echo "    💡 Pressione Ctrl+C para parar"
        echo "    🌐 API estará disponível em: http://localhost:8080"
        echo ""
        
        # Iniciar em background para poder continuar
        go run cmd/server/main.go &
        API_PID=$!
        
        echo "  📊 API iniciada com PID: $API_PID"
        echo "  ⏳ Aguardando inicialização (5 segundos)..."
        sleep 5
        
        # Testar se subiu
        if curl -s http://localhost:8080/health >/dev/null 2>&1; then
            echo "  ✅ API respondendo!"
            echo "  🌐 Health: http://localhost:8080/health"
            echo "  📚 Swagger: http://localhost:8080/swagger/index.html"
            echo ""
            echo "  📋 Para parar a API: kill $API_PID"
        else
            echo "  ⚠️ API pode estar inicializando, teste manualmente:"
            echo "     curl http://localhost:8080/health"
        fi
    else
        echo "    ❌ Erro nas dependências Go"
    fi
else
    echo "  ❌ cmd/server/main.go não encontrado"
fi

echo ""
echo "📊 3. Status final dos serviços..."
echo "  🐳 Containers Docker:"
docker-compose ps | grep -E "postgres|api" || echo "    Apenas postgres rodando"

echo ""
echo "  🌐 Teste de conectividade:"
echo "    PostgreSQL: $(docker-compose exec postgres pg_isready -U pganalytics >/dev/null 2>&1 && echo '✅ OK' || echo '❌ Falha')"
echo "    API Health: $(curl -s http://localhost:8080/health >/dev/null 2>&1 && echo '✅ OK' || echo '❌ Falha')"

echo ""
echo "✅ Script de inicialização concluído!"
