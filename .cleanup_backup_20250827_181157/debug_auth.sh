#!/bin/bash
# debug_auth.sh - Debug específico para autenticação

echo "🔍 DEBUG - AUTENTICAÇÃO"
echo "="*30

API_URL="http://localhost:8080"

# 1. Fazer login e capturar resposta completa
echo "1. Fazendo login..."
LOGIN_RESPONSE=$(curl -s -X POST $API_URL/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}')

echo "Login response:"
echo "$LOGIN_RESPONSE" | jq .

# 2. Extrair token
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
echo ""
echo "Token extraído: $TOKEN"

# 3. Testar endpoint protegido com debug
echo ""
echo "2. Testando endpoint protegido..."
echo "Header que será enviado: Authorization: Bearer $TOKEN"

RESPONSE=$(curl -s -v -X GET $API_URL/api/data \
    -H "Authorization: Bearer $TOKEN" 2>&1)

echo "Response completa:"
echo "$RESPONSE"

# 4. Verificar logs do container
echo ""
echo "3. Logs do container API (últimas 20 linhas):"
docker-compose logs --tail=20 api

echo ""
echo "🔍 Debug concluído!"
