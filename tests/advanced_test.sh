#!/bin/bash
# advanced_test.sh - Testes avançados da API

echo "🚀 TESTES AVANÇADOS PGANALYTICS API"
echo "="*50

API_URL="http://localhost:8080"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função para teste com validação
test_endpoint() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local headers="$4"
    local data="$5"
    local expected_status="$6"
    
    echo -e "${YELLOW}Testando: $name${NC}"
    
    if [[ "$method" == "GET" ]]; then
        response=$(curl -s -w "%{http_code}" -o /tmp/response.json $headers "$API_URL$endpoint")
    else
        response=$(curl -s -w "%{http_code}" -o /tmp/response.json -X $method $headers -d "$data" "$API_URL$endpoint")
    fi
    
    status_code="${response: -3}"
    
    if [[ "$status_code" == "$expected_status" ]]; then
        echo -e "${GREEN}✅ $name - Status: $status_code${NC}"
        cat /tmp/response.json | jq . 2>/dev/null || cat /tmp/response.json
    else
        echo -e "${RED}❌ $name - Expected: $expected_status, Got: $status_code${NC}"
        cat /tmp/response.json
    fi
    echo ""
}

# 1. Health Check
test_endpoint "Health Check" "GET" "/health" "" "" "200"

# 2. Login válido
echo -e "${YELLOW}=== AUTHENTICATION TESTS ===${NC}"
login_data='{"username":"admin","password":"admin"}'
test_endpoint "Login válido" "POST" "/auth/login" "-H 'Content-Type: application/json'" "$login_data" "200"

# Extrair token para próximos testes
TOKEN=$(curl -s -X POST $API_URL/auth/login -H "Content-Type: application/json" -d "$login_data" | jq -r '.token')
echo -e "${GREEN}Token extraído: ${TOKEN:0:50}...${NC}"
echo ""

# 3. Login inválido
invalid_login='{"username":"wrong","password":"wrong"}'
test_endpoint "Login inválido" "POST" "/auth/login" "-H 'Content-Type: application/json'" "$invalid_login" "401"

# 4. Endpoints protegidos
echo -e "${YELLOW}=== PROTECTED ENDPOINTS TESTS ===${NC}"
auth_header="-H 'Authorization: Bearer $TOKEN'"

test_endpoint "GET /api/data com token" "GET" "/api/data" "$auth_header" "" "200"

# 5. Teste sem token
test_endpoint "GET /api/data sem token" "GET" "/api/data" "" "" "401"

# 6. Teste com token inválido
invalid_auth_header="-H 'Authorization: Bearer invalid_token'"
test_endpoint "GET /api/data token inválido" "GET" "/api/data" "$invalid_auth_header" "" "401"

# 7. POST de métricas
echo -e "${YELLOW}=== METRICS TESTS ===${NC}"
metrics_data='{
    "database": "production_db",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
    "metrics": {
        "queries_per_second": 450.2,
        "avg_response_time": 12.5,
        "active_connections": 25,
        "cache_hit_ratio": 0.95
    },
    "top_queries": [
        {"query": "SELECT * FROM users WHERE active = true", "time": 2.1, "calls": 1500},
        {"query": "SELECT * FROM orders WHERE date > NOW() - INTERVAL 1 DAY", "time": 5.8, "calls": 800}
    ]
}'

test_endpoint "POST métricas válidas" "POST" "/api/metrics" "$auth_header -H 'Content-Type: application/json'" "$metrics_data" "200"

# 8. POST métricas sem token
test_endpoint "POST métricas sem token" "POST" "/api/metrics" "-H 'Content-Type: application/json'" "$metrics_data" "401"

# 9. POST métricas dados inválidos
invalid_metrics='{"invalid": "data"'
test_endpoint "POST métricas inválidas" "POST" "/api/metrics" "$auth_header -H 'Content-Type: application/json'" "$invalid_metrics" "400"

echo -e "${GREEN}🎉 TESTES AVANÇADOS CONCLUÍDOS!${NC}"

# Limpar arquivo temporário
rm -f /tmp/response.json
