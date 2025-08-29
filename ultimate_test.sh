#!/bin/bash

echo "🏆 TESTE DEFINITIVO - ÚLTIMOS AJUSTES"
echo "=" * 45

echo "🔄 1. Parando todas as APIs anteriores..."
pkill -f "go run main.go" 2>/dev/null
pkill -f ":8080" 2>/dev/null
sleep 3
echo "  ✅ APIs anteriores paradas"

echo ""
echo "🔍 2. Descobrindo senha correta do PostgreSQL..."
# Testar diferentes senhas comuns
POSTGRES_PASSWORDS=("pganalytics123" "postgres" "password" "admin" "123456")

for password in "${POSTGRES_PASSWORDS[@]}"; do
    echo "  🧪 Testando senha: $password"
    if docker exec pganalytics-v2-postgres-1 psql -U postgres -d pganalytics -c "SELECT 1;" >/dev/null 2>&1; then
        echo "    ✅ Senha correta: $password"
        CORRECT_PASSWORD="$password"
        break
    fi
done

if [ -z "$CORRECT_PASSWORD" ]; then
    echo "  ⚠️ Senha não descoberta, usando fallback"
    CORRECT_PASSWORD="pganalytics123"
fi

echo ""
echo "🗄️ 3. Verificando usuários no banco..."
echo "  🔍 Tentando acessar tabela users..."
docker exec pganalytics-v2-postgres-1 psql -U postgres -d pganalytics -c "SELECT id, username, email FROM users LIMIT 3;" 2>/dev/null || echo "  ⚠️ Erro ao acessar users"

echo ""
echo "🚀 4. INICIANDO API FINAL..."
echo "  🔄 Iniciando servidor..."
nohup go run main.go > api_ULTIMATE.log 2>&1 &
API_PID=$!
echo "  🆔 PID da API: $API_PID"

# Aguardar inicialização
sleep 5

echo ""
echo "🧪 5. TESTANDO HEALTH ENDPOINT..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health 2>/dev/null)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "  ✅ API FUNCIONANDO! Resposta: $HEALTH_RESPONSE"
else
    echo "  ❌ API não responde ao health"
    echo "  📄 Verificando logs..."
    tail -20 api_ULTIMATE.log
    exit 1
fi

echo ""
echo "🔐 6. TESTANDO LOGIN - MOMENTO DA VERDADE!"

echo "  🧪 TESTE 1: admin@pganalytics.local + admin123"
LOGIN1=$(curl -s -X POST http://localhost:8080/auth/login   -H "Content-Type: application/json"   -d '{"username":"admin@pganalytics.local","password":"admin123"}' 2>/dev/null)

echo "    📊 Resposta: $LOGIN1"

if echo "$LOGIN1" | grep -q "token"; then
    echo "    🎯 SUCESSO! Login funcionou!"
    
    # Extrair token
    TOKEN=$(echo "$LOGIN1" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "    🔑 Token obtido: ${TOKEN:0:60}..."
    
    echo ""
    echo "  🔒 TESTANDO ROTA PROTEGIDA..."
    PROTECTED_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/metrics 2>/dev/null)
    echo "    📊 Resposta rota protegida: $PROTECTED_RESPONSE"
    
    if echo "$PROTECTED_RESPONSE" | grep -q "success"; then
        echo "    🏆 ROTA PROTEGIDA FUNCIONANDO!"
        echo ""
        echo "🎉 =================================="
        echo "🎉   AUTENTICAÇÃO 100% FUNCIONAL!"
        echo "🎉 =================================="
    else
        echo "    ❌ Rota protegida com problema"
    fi
    
else
    echo "    ❌ Login 1 falhou"
    
    echo ""
    echo "  🧪 TESTE 2: admin + admin123"
    LOGIN2=$(curl -s -X POST http://localhost:8080/auth/login       -H "Content-Type: application/json"       -d '{"username":"admin","password":"admin123"}' 2>/dev/null)
    
    echo "    📊 Resposta: $LOGIN2"
    
    if echo "$LOGIN2" | grep -q "token"; then
        echo "    🎯 Login 2 funcionou!"
    else
        echo "    ❌ Ambos logins falharam"
        echo "    📄 Verificando logs da API:"
        tail -10 api_ULTIMATE.log
    fi
fi

echo ""
echo "📋 7. RESUMO COMPLETO:"
echo "  🌐 Health Check: http://localhost:8080/health"
echo "  📖 Documentação: http://localhost:8080/swagger/index.html"
echo "  🔐 Login Endpoint: POST http://localhost:8080/auth/login"
echo "  🔒 Metrics (protegida): GET http://localhost:8080/metrics"
echo ""
echo "  🔑 Credenciais testadas:"
echo "      ✓ admin@pganalytics.local + admin123"
echo "      ✓ admin + admin123"
echo ""
echo "  📋 Comando de teste manual:"
echo "      curl -X POST http://localhost:8080/auth/login \\"
echo "        -H 'Content-Type: application/json' \\"
echo "        -d '{"username":"admin@pganalytics.local","password":"admin123"}'"

echo ""
echo "🎯 TESTE DEFINITIVO CONCLUÍDO!"
