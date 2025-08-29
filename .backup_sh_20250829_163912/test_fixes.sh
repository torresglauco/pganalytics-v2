#!/bin/bash

echo "🧪 TESTANDO CORREÇÕES COMPLETAS"

# 1. Rebuild completo
echo "🔄 Rebuild completo..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Aguardar inicialização
echo "⏳ Aguardando inicialização (20s)..."
sleep 20

# 2. Testar health
echo ""
echo "🩺 Testando health check..."
HEALTH=$(curl -s http://localhost:8080/health)
echo "📊 Resposta: $HEALTH"

# 3. Testar login com todos os usuários
echo ""
echo "🔐 Testando login com TODOS os usuários..."

# Lista de usuários para testar
USERS=("admin" "admin@docker.local" "admin@pganalytics.local" "user" "test")

for USERNAME in "${USERS[@]}"; do
    echo ""
    echo "🔍 Testando: $USERNAME"
    
    LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/login \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$USERNAME\",\"password\":\"admin123\"}")
    
    if echo "$LOGIN_RESPONSE" | grep -q "token"; then
        echo "✅ $USERNAME: LOGIN OK"
        
        # Extrair token
        TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        
        # Testar rota protegida
        METRICS_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/metrics)
        
        if echo "$METRICS_RESPONSE" | grep -q "success"; then
            echo "✅ $USERNAME: METRICS OK"
        else
            echo "❌ $USERNAME: METRICS FALHOU"
            echo "📊 Resposta: $METRICS_RESPONSE"
        fi
    else
        echo "❌ $USERNAME: LOGIN FALHOU"
        echo "📊 Resposta: $LOGIN_RESPONSE"
    fi
done

# 4. Testar rotas API v1
echo ""
echo "🌐 Testando rotas API v1..."

# Login para pegar token
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin123"}')

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    # Testar rotas v1
    API_ROUTES=("/api/v1/auth/profile" "/api/v1/analytics/queries/slow" "/api/v1/analytics/tables/stats" "/api/v1/analytics/connections" "/api/v1/analytics/performance")
    
    for ROUTE in "${API_ROUTES[@]}"; do
        echo "🔍 Testando: $ROUTE"
        RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080$ROUTE")
        
        if [ ${#RESPONSE} -gt 10 ]; then
            echo "✅ $ROUTE: OK"
        else
            echo "❌ $ROUTE: FALHOU"
        fi
    done
fi

# 5. Testar segurança
echo ""
echo "🔒 Testando segurança..."
UNAUTHORIZED=$(curl -s http://localhost:8080/metrics)
if echo "$UNAUTHORIZED" | grep -q "Authorization header required"; then
    echo "✅ Segurança funcionando!"
else
    echo "❌ Problema de segurança!"
fi

# 6. Status final
echo ""
echo "📊 Status final dos containers..."
docker-compose ps

echo ""
echo "✅ TESTE DE CORREÇÕES CONCLUÍDO!"
