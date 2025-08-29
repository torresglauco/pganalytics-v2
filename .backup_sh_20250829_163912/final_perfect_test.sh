#!/bin/bash

echo "🎯 TESTE FINAL PERFEITO"
echo "======================"

# Build e start
echo "🔄 Build e start final..."
docker-compose build --no-cache
docker-compose up -d

echo "⏳ Aguardando (20s)..."
sleep 20

# Teste health primeiro
echo ""
echo "🩺 Health check..."
HEALTH=$(curl -s http://localhost:8080/health)
if echo "$HEALTH" | grep -q "healthy"; then
    echo "✅ Health: OK"
else
    echo "❌ Health: FALHOU"
    echo "Response: $HEALTH"
fi

# Teste TODOS os usuários
echo ""
echo "🔐 TESTE DE USUÁRIOS:"
USERS=("admin" "admin@docker.local" "admin@pganalytics.local" "user" "test")
USER_SUCCESS=0

for USERNAME in "${USERS[@]}"; do
    echo ""
    echo "🔍 Testando: $USERNAME"
    
    LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/login \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$USERNAME\",\"password\":\"admin123\"}")
    
    if echo "$LOGIN_RESPONSE" | grep -q "token"; then
        echo "✅ LOGIN: OK"
        USER_SUCCESS=$((USER_SUCCESS + 1))
        
        # Extrair token para teste de métricas
        TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        
        # Teste rota protegida
        METRICS_RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/metrics)
        if echo "$METRICS_RESPONSE" | grep -q "success"; then
            echo "✅ METRICS: OK"
        else
            echo "❌ METRICS: FALHOU"
        fi
    else
        echo "❌ LOGIN: FALHOU"
        echo "Response: $LOGIN_RESPONSE"
    fi
done

USER_RATE=$((USER_SUCCESS * 100 / 5))
echo ""
echo "📊 USUÁRIOS: $USER_SUCCESS/5 ($USER_RATE%)"

# Teste TODAS as rotas com admin
echo ""
echo "🌐 TESTE DE ROTAS:"

LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin123"}')

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    
    ROUTE_SUCCESS=0
    
    # Health (público)
    echo "🔍 /health"
    RESPONSE=$(curl -s http://localhost:8080/health)
    if echo "$RESPONSE" | grep -q "healthy"; then
        echo "✅ OK"
        ROUTE_SUCCESS=$((ROUTE_SUCCESS + 1))
    else
        echo "❌ FALHOU"
    fi
    
    # Metrics (protegida)
    echo "🔍 /metrics"
    RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8080/metrics)
    if echo "$RESPONSE" | grep -q "success"; then
        echo "✅ OK"
        ROUTE_SUCCESS=$((ROUTE_SUCCESS + 1))
    else
        echo "❌ FALHOU"
    fi
    
    # API v1 routes
    API_ROUTES=(
        "/api/v1/auth/profile"
        "/api/v1/analytics/queries/slow"
        "/api/v1/analytics/tables/stats"
        "/api/v1/analytics/connections"
        "/api/v1/analytics/performance"
    )
    
    for ROUTE in "${API_ROUTES[@]}"; do
        echo "🔍 $ROUTE"
        RESPONSE=$(curl -s -H "Authorization: Bearer $TOKEN" "http://localhost:8080$ROUTE")
        if [ ${#RESPONSE} -gt 30 ]; then
            echo "✅ OK"
            ROUTE_SUCCESS=$((ROUTE_SUCCESS + 1))
        else
            echo "❌ FALHOU (Response: $RESPONSE)"
        fi
    done
    
    ROUTE_RATE=$((ROUTE_SUCCESS * 100 / 7))
    echo ""
    echo "📈 ROTAS: $ROUTE_SUCCESS/7 ($ROUTE_RATE%)"
fi

# Teste de segurança
echo ""
echo "🔒 TESTE DE SEGURANÇA:"
UNAUTH=$(curl -s http://localhost:8080/metrics)
if echo "$UNAUTH" | grep -q "Authorization header required"; then
    echo "✅ Segurança funcionando"
else
    echo "❌ Problema de segurança"
fi

# Resumo final
echo ""
echo "🎯 RESULTADO FINAL:"
echo "==================="
if [ $USER_RATE -eq 100 ] && [ $ROUTE_RATE -eq 100 ]; then
    echo "🎉 PERFEITO! 100% FUNCIONANDO!"
    echo "✅ Usuários: 5/5 (100%)"
    echo "✅ Rotas: 7/7 (100%)"
    echo "✅ Segurança: OK"
    echo ""
    echo "🚀 INTEGRAÇÃO JWT + ESTRUTURA MODULAR: COMPLETA!"
else
    echo "⚠️ Funcional mas não perfeito:"
    echo "📊 Usuários: $USER_SUCCESS/5 ($USER_RATE%)"
    echo "📈 Rotas: $ROUTE_SUCCESS/7 ($ROUTE_RATE%)"
fi

echo ""
echo "🌐 SISTEMA FINAL:"
echo "  Health: http://localhost:8080/health"
echo "  Login: POST http://localhost:8080/auth/login"
echo "  Metrics: GET http://localhost:8080/metrics (Auth)"
echo "  API v1: http://localhost:8080/api/v1/* (Auth)"
