#!/bin/bash

echo "🔧 CORRIGINDO DEPENDÊNCIAS E PROBLEMAS"
echo "=" * 50

echo "📦 1. Instalando dependências Go necessárias..."
echo "  🔍 Verificando go.mod atual..."
if [ -f "go.mod" ]; then
    echo "  📄 go.mod existe, verificando dependências..."
    cat go.mod
    echo ""
else
    echo "  ❌ go.mod não encontrado"
fi

echo "  📦 Instalando dependências específicas..."
go get github.com/lib/pq && echo "  ✅ github.com/lib/pq instalado" || echo "  ❌ Erro ao instalar lib/pq"
go get github.com/golang-jwt/jwt/v5 && echo "  ✅ jwt/v5 instalado" || echo "  ❌ Erro ao instalar jwt"
go get golang.org/x/crypto/bcrypt && echo "  ✅ bcrypt instalado" || echo "  ❌ Erro ao instalar bcrypt"
go get github.com/gin-gonic/gin && echo "  ✅ gin instalado" || echo "  ❌ Erro ao instalar gin"
go get github.com/swaggo/files && echo "  ✅ swaggo/files instalado" || echo "  ❌ Erro ao instalar swaggo"
go get github.com/swaggo/gin-swagger && echo "  ✅ gin-swagger instalado" || echo "  ❌ Erro ao instalar gin-swagger"

echo ""
echo "🔧 2. Limpando e atualizando módulos..."
go mod tidy && echo "  ✅ go mod tidy executado" || echo "  ❌ Erro no go mod tidy"

echo ""
echo "📄 3. Verificando main.go criado..."
if [ -f "main.go" ]; then
    echo "  ✅ main.go existe ($(wc -l < main.go) linhas)"
    echo "  🔍 Verificando imports..."
    grep -n "import" main.go -A 10 | head -15
else
    echo "  ❌ main.go não encontrado"
fi

echo ""
echo "🔍 4. Verificando se PostgreSQL está acessível..."
# Testar conexão direta com Docker
if command -v docker >/dev/null 2>&1; then
    echo "  🐳 Testando conexão com PostgreSQL via Docker..."
    
    # Verificar se container PostgreSQL está rodando
    POSTGRES_CONTAINER=$(docker ps --format "table {{.Names}}" | grep -i postgres | head -1)
    if [ ! -z "$POSTGRES_CONTAINER" ]; then
        echo "  ✅ Container PostgreSQL encontrado: $POSTGRES_CONTAINER"
        
        # Testar conexão via docker exec
        echo "  🔍 Testando conexão com banco..."
        docker exec $POSTGRES_CONTAINER psql -U pganalytics -d pganalytics -c "SELECT COUNT(*) FROM users;" 2>/dev/null && echo "  ✅ Banco acessível" || echo "  ⚠️ Erro ao acessar banco"
        
        echo "  🔍 Listando usuários existentes..."
        docker exec $POSTGRES_CONTAINER psql -U pganalytics -d pganalytics -c "SELECT username, email, role FROM users LIMIT 5;" 2>/dev/null || echo "  ⚠️ Erro ao listar usuários"
    else
        echo "  ⚠️ Container PostgreSQL não encontrado"
        echo "  🔄 Iniciando containers..."
        docker-compose up -d && echo "  ✅ Containers iniciados" || echo "  ❌ Erro ao iniciar containers"
        sleep 5
    fi
else
    echo "  ⚠️ Docker não disponível"
fi

echo ""
echo "🚀 5. Tentando iniciar a API..."
# Matar processos anteriores
pkill -f "go run main.go" 2>/dev/null
sleep 2

echo "  🔄 Iniciando API em background..."
nohup go run main.go > api_fixed.log 2>&1 &
API_PID=$!
echo "  🔍 API iniciada com PID: $API_PID"

# Aguardar alguns segundos
sleep 5

echo "  🔍 Verificando se API está respondendo..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "  ✅ API está respondendo!"
    
    echo "  🧪 Testando login..."
    LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/login       -H "Content-Type: application/json"       -d '{"username":"admin@pganalytics.local","password":"admin123"}')
    
    echo "  📊 Resposta do login: $LOGIN_RESPONSE"
    
    if echo "$LOGIN_RESPONSE" | grep -q "token"; then
        echo "  ✅ Login funcionando!"
    else
        echo "  ❌ Login ainda com problemas"
        echo "  📄 Verificando logs:"
        tail -10 api_fixed.log
    fi
else
    echo "  ❌ API não está respondendo"
    echo "  📄 Logs da API:"
    cat api_fixed.log
fi

echo ""
echo "📊 6. Status final das dependências..."
echo "  🔍 go.mod atualizado:"
head -20 go.mod

echo ""
echo "✅ Correção de dependências concluída!"
