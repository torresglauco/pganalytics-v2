#!/bin/bash
echo "🧪 TESTE DO SISTEMA DE AUTENTICAÇÃO"

BASE_URL="http://localhost:8080/api/v1"
HEALTH_URL="http://localhost:8080/health"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Função para extrair JSON
extract_json() {
    echo $1 | jq -r $2 2>/dev/null || echo ""
}

echo "🏥 1. Testando Health Check..."
HEALTH_RESPONSE=$(curl -s $HEALTH_URL)
if echo "$HEALTH_RESPONSE" | jq -e '.status == "ok"' >/dev/null 2>&1; then
    print_status 0 "API está funcionando"
else
    print_status 1 "API não está respondendo corretamente"
    echo "$HEALTH_RESPONSE"
    exit 1
fi

echo ""
echo "👤 2. Testando Registro de Usuário..."

REGISTER_DATA='{
    "email": "test@example.com",
    "password": "testpassword123",
    "name": "Test User",
    "role": "user"
}'

REGISTER_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$REGISTER_DATA" \
    "$BASE_URL/auth/register")

REGISTER_STATUS=$(echo "$REGISTER_RESPONSE" | jq -r '.user.email // empty')
if [ -n "$REGISTER_STATUS" ]; then
    print_status 0 "Registro de usuário"
    ACCESS_TOKEN=$(extract_json "$REGISTER_RESPONSE" ".access_token")
    REFRESH_TOKEN=$(extract_json "$REGISTER_RESPONSE" ".refresh_token")
    echo "   📧 Email: $(extract_json "$REGISTER_RESPONSE" ".user.email")"
    echo "   👤 Nome: $(extract_json "$REGISTER_RESPONSE" ".user.name")" 
    echo "   🔑 Role: $(extract_json "$REGISTER_RESPONSE" ".user.role")"
else
    print_status 1 "Registro de usuário"
    echo "$REGISTER_RESPONSE"
fi

echo ""
echo "🔐 3. Testando Login..."

LOGIN_DATA='{
    "email": "admin@pganalytics.local",
    "password": "admin123"
}'

LOGIN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$LOGIN_DATA" \
    "$BASE_URL/auth/login")

LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | jq -r '.user.email // empty')
if [ -n "$LOGIN_STATUS" ]; then
    print_status 0 "Login de usuário"
    ADMIN_TOKEN=$(extract_json "$LOGIN_RESPONSE" ".access_token")
    ADMIN_REFRESH=$(extract_json "$LOGIN_RESPONSE" ".refresh_token")
    echo "   👑 Role: $(extract_json "$LOGIN_RESPONSE" ".user.role")"
else
    print_status 1 "Login de usuário"
    echo "$LOGIN_RESPONSE"
fi

echo ""
echo "📋 4. Testando Perfil do Usuário..."

if [ -n "$ADMIN_TOKEN" ]; then
    PROFILE_RESPONSE=$(curl -s -X GET \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        "$BASE_URL/auth/profile")
    
    PROFILE_EMAIL=$(extract_json "$PROFILE_RESPONSE" ".email")
    if [ -n "$PROFILE_EMAIL" ]; then
        print_status 0 "Obter perfil"
        echo "   📧 Email: $PROFILE_EMAIL"
        echo "   👤 Nome: $(extract_json "$PROFILE_RESPONSE" ".name")"
    else
        print_status 1 "Obter perfil"
        echo "$PROFILE_RESPONSE"
    fi
else
    print_status 1 "Obter perfil (token não disponível)"
fi

echo ""
echo "🔄 5. Testando Refresh Token..."

if [ -n "$ADMIN_REFRESH" ]; then
    REFRESH_DATA="{"refresh_token": "$ADMIN_REFRESH"}"
    
    REFRESH_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$REFRESH_DATA" \
        "$BASE_URL/auth/refresh")
    
    NEW_TOKEN=$(extract_json "$REFRESH_RESPONSE" ".access_token")
    if [ -n "$NEW_TOKEN" ]; then
        print_status 0 "Refresh token"
        echo "   🆕 Novo token gerado"
    else
        print_status 1 "Refresh token"
        echo "$REFRESH_RESPONSE"
    fi
else
    print_status 1 "Refresh token (refresh token não disponível)"
fi

echo ""
echo "✏️ 6. Testando Atualização de Perfil..."

if [ -n "$ADMIN_TOKEN" ]; then
    UPDATE_DATA='{
        "name": "Admin Updated"
    }'
    
    UPDATE_RESPONSE=$(curl -s -X PUT \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -d "$UPDATE_DATA" \
        "$BASE_URL/auth/profile")
    
    UPDATED_NAME=$(extract_json "$UPDATE_RESPONSE" ".name")
    if [ "$UPDATED_NAME" = "Admin Updated" ]; then
        print_status 0 "Atualizar perfil"
        echo "   ✏️ Nome atualizado para: $UPDATED_NAME"
    else
        print_status 1 "Atualizar perfil"
        echo "$UPDATE_RESPONSE"
    fi
else
    print_status 1 "Atualizar perfil (token não disponível)"
fi

echo ""
echo "🚫 7. Testando Acesso Não Autorizado..."

UNAUTH_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/profile")
UNAUTH_ERROR=$(extract_json "$UNAUTH_RESPONSE" ".error")

if [ "$UNAUTH_ERROR" = "Unauthorized" ]; then
    print_status 0 "Proteção de rota funcionando"
else
    print_status 1 "Proteção de rota"
    echo "$UNAUTH_RESPONSE"
fi

echo ""
echo "🔐 8. Testando Middleware de Autorização..."

# Testar com token inválido
INVALID_RESPONSE=$(curl -s -X GET \
    -H "Authorization: Bearer invalid-token" \
    "$BASE_URL/auth/profile")

INVALID_ERROR=$(extract_json "$INVALID_RESPONSE" ".error")
if [ "$INVALID_ERROR" = "Unauthorized" ]; then
    print_status 0 "Validação de token"
else
    print_status 1 "Validação de token"
    echo "$INVALID_RESPONSE"
fi

echo ""
echo "🚪 9. Testando Logout..."

if [ -n "$ADMIN_REFRESH" ]; then
    LOGOUT_DATA="{"refresh_token": "$ADMIN_REFRESH"}"
    
    LOGOUT_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$LOGOUT_DATA" \
        "$BASE_URL/auth/logout")
    
    LOGOUT_SUCCESS=$(extract_json "$LOGOUT_RESPONSE" ".success")
    if [ "$LOGOUT_SUCCESS" = "true" ]; then
        print_status 0 "Logout"
    else
        print_status 1 "Logout"
        echo "$LOGOUT_RESPONSE"
    fi
else
    print_status 1 "Logout (refresh token não disponível)"
fi

echo ""
echo "📊 RESUMO DOS TESTES"
echo "===================="
echo "🔐 Sistema de Autenticação: JWT com Access + Refresh Tokens"
echo "👤 Usuários: Registro, Login, Perfil, Atualização"
echo "🛡️ Segurança: Middleware de autenticação e autorização"
echo "🚪 Sessões: Login, Logout, Refresh automático"
echo ""
echo "✅ Testes concluídos!"
echo ""
echo "📚 Para testar via Swagger: http://localhost:8080/swagger/index.html"
echo "👑 Admin login: admin@pganalytics.local / admin123"
echo "👤 User login: user@pganalytics.local / admin123"
