#!/bin/bash
# test_api.sh - Testes básicos da API

echo "🧪 TESTANDO PGANALYTICS API"
echo "="*50

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://localhost:8080"

echo -e "${YELLOW}1. Testando Health Check...${NC}"
HEALTH=$(curl -s $API_URL/health)
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Health Check OK${NC}"
    echo "$HEALTH" | jq .
else
    echo -e "${RED}❌ Health Check FAILED${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}2. Testando Login...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST $API_URL/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}')

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Login OK${NC}"
    echo "$LOGIN_RESPONSE" | jq .
    
    # Extrair token
    TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
    echo -e "${GREEN}Token: $TOKEN${NC}"
else
    echo -e "${RED}❌ Login FAILED${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}3. Testando endpoint protegido /api/data...${NC}"
DATA_RESPONSE=$(curl -s -X GET $API_URL/api/data \
    -H "Authorization: Bearer $TOKEN")

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Protected endpoint OK${NC}"
    echo "$DATA_RESPONSE" | jq .
else
    echo -e "${RED}❌ Protected endpoint FAILED${NC}"
fi

echo ""
echo -e "${YELLOW}4. Testando POST de métricas...${NC}"
METRICS_RESPONSE=$(curl -s -X POST $API_URL/api/metrics \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "database": "test_db",
        "queries": [
            {"query": "SELECT * FROM users", "time": 2.5},
            {"query": "SELECT * FROM orders", "time": 1.8}
        ],
        "connections": {"active": 10, "idle": 5}
    }')

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Metrics POST OK${NC}"
    echo "$METRICS_RESPONSE" | jq .
else
    echo -e "${RED}❌ Metrics POST FAILED${NC}"
fi

echo ""
echo -e "${YELLOW}5. Testando autenticação inválida...${NC}"
INVALID_AUTH=$(curl -s -X GET $API_URL/api/data \
    -H "Authorization: Bearer invalid_token")

if [[ "$INVALID_AUTH" == *"Invalid token"* ]]; then
    echo -e "${GREEN}✅ Auth validation OK${NC}"
    echo "$INVALID_AUTH" | jq .
else
    echo -e "${RED}❌ Auth validation FAILED${NC}"
fi

echo ""
echo -e "${GREEN}🎉 TODOS OS TESTES CONCLUÍDOS!${NC}"
