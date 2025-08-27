#!/bin/bash
# performance_test.sh - Testes de performance

echo "⚡ TESTES DE PERFORMANCE"
echo "="*30

API_URL="http://localhost:8080"

# Obter token
TOKEN=$(curl -s -X POST $API_URL/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}' | jq -r '.token')

echo "🔥 Testando múltiplas requisições simultâneas..."

# Teste de carga simples
echo "Fazendo 10 requisições simultâneas..."
for i in {1..10}; do
    curl -s $API_URL/health > /dev/null &
done
wait

echo "✅ Teste de health check concluído"

# Teste de autenticação em massa
echo "Testando 5 logins simultâneos..."
for i in {1..5}; do
    curl -s -X POST $API_URL/auth/login \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"admin"}' > /dev/null &
done
wait

echo "✅ Teste de login concluído"

# Teste de endpoints protegidos
echo "Testando 5 requisições para endpoints protegidos..."
for i in {1..5}; do
    curl -s -X GET $API_URL/api/data \
        -H "Authorization: Bearer $TOKEN" > /dev/null &
done
wait

echo "✅ Teste de endpoints protegidos concluído"

echo "🎉 Todos os testes de performance concluídos!"
