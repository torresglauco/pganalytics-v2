#!/bin/bash
echo "🔧 TESTANDO LOGIN COM FORMATO CORRETO"

BASE_URL="http://localhost:8080"

echo "🔍 1. Testando login com 'username' (formato atual)..."

# Testar com username em vez de email
ADMIN_LOGIN_USERNAME=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin@pganalytics.local","password":"admin123"}')

echo "  📊 Resposta com username: $ADMIN_LOGIN_USERNAME"

if echo "$ADMIN_LOGIN_USERNAME" | grep -q "token\|success"; then
    echo "  ✅ Login funcionou com 'username'"
    
    # Extrair token se existir
    TOKEN=$(echo "$ADMIN_LOGIN_USERNAME" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        echo "  🎫 Token extraído: ${TOKEN:0:50}..."
        
        echo ""
        echo "🔒 2. Testando endpoints protegidos com token..."
        
        # Testar metrics com token
        METRICS_WITH_TOKEN=$(curl -s -X POST "$BASE_URL/api/metrics" \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $TOKEN" \
          -d '{"metric":"test","value":123}')
        echo "  📈 Metrics com token: $METRICS_WITH_TOKEN"
        
        # Testar data com token
        DATA_WITH_TOKEN=$(curl -s "$BASE_URL/api/data" \
          -H "Authorization: Bearer $TOKEN")
        echo "  📊 Data com token: $DATA_WITH_TOKEN"
    fi
else
    echo "  ❌ Login ainda falha com username"
fi

echo ""
echo "🔍 3. Testando outros formatos de login..."

# Testar apenas com email (sem username)
EMAIL_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pganalytics.local","password":"admin123"}')
echo "  📧 Login com email: $EMAIL_LOGIN"

# Testar com user simples (se for username mesmo)
USER_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
echo "  👤 Login com 'admin': $USER_LOGIN"

echo ""
echo "✅ Teste de formatos de login concluído!"
