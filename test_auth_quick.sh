#!/bin/bash

echo "🧪 TESTE RÁPIDO DE AUTENTICAÇÃO"
echo "=" * 40

echo "🔍 1. Verificando se API está rodando..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo "  ✅ API está rodando"
else
    echo "  ❌ API não está rodando, iniciando..."
    nohup go run main.go > api.log 2>&1 &
    sleep 3
    echo "  🔄 API iniciada"
fi

echo ""
echo "🔍 2. Verificando usuários no banco..."
export PGPASSWORD="pganalytics123"
echo "  📊 Usuários cadastrados:"
psql -h localhost -U pganalytics -d pganalytics -c "SELECT username, email, role, is_active FROM users;" 2>/dev/null || echo "  ❌ Erro ao consultar usuários"

echo ""
echo "🧪 3. Testando login com diferentes credenciais..."

echo "  🔍 Teste 1: admin@pganalytics.local + admin123"
RESPONSE1=$(curl -s -X POST http://localhost:8080/auth/login   -H "Content-Type: application/json"   -d '{"username":"admin@pganalytics.local","password":"admin123"}')
echo "    📊 Resposta: $RESPONSE1"

echo ""
echo "  🔍 Teste 2: admin@pganalytics.local + password"
RESPONSE2=$(curl -s -X POST http://localhost:8080/auth/login   -H "Content-Type: application/json"   -d '{"username":"admin@pganalytics.local","password":"password"}')
echo "    📊 Resposta: $RESPONSE2"

echo ""
echo "  🔍 Teste 3: admin + admin123"
RESPONSE3=$(curl -s -X POST http://localhost:8080/auth/login   -H "Content-Type: application/json"   -d '{"username":"admin","password":"admin123"}')
echo "    📊 Resposta: $RESPONSE3"

echo ""
echo "📋 4. Análise dos resultados:"
if echo "$RESPONSE1" | grep -q "token"; then
    echo "  ✅ Login 1 funcionou!"
    TOKEN=$(echo "$RESPONSE1" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "  🔑 Token obtido, testando rota protegida..."
    
    PROTECTED=$(curl -s -X GET http://localhost:8080/metrics       -H "Authorization: Bearer $TOKEN")
    echo "  📊 Rota protegida: $PROTECTED"
    
elif echo "$RESPONSE2" | grep -q "token"; then
    echo "  ✅ Login 2 funcionou!"
elif echo "$RESPONSE3" | grep -q "token"; then
    echo "  ✅ Login 3 funcionou!"
else
    echo "  ❌ Nenhum login funcionou"
    echo "  🔍 Verificando logs da API..."
    tail -10 api.log 2>/dev/null || echo "    ❌ Arquivo de log não encontrado"
fi

echo ""
echo "✅ Teste concluído!"
