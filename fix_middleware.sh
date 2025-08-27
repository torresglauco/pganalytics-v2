#!/bin/bash
# fix_middleware.sh - Corrige o middleware de autenticação

echo "🔧 Corrigindo middleware de autenticação..."

# Backup do arquivo original
cp internal/middleware/middleware.go internal/middleware/middleware.go.backup

# Aplicar correção
cp middleware.go-FIXED internal/middleware/middleware.go

echo "✅ Middleware corrigido!"

# Reiniciar container
echo "🔄 Reiniciando container..."
docker-compose restart api

echo "⏳ Aguardando container reiniciar..."
sleep 5

echo "🧪 Testando correção..."
TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}' | jq -r '.token')

echo "Token: $TOKEN"

RESULT=$(curl -s -X GET http://localhost:8080/api/data \
    -H "Authorization: Bearer $TOKEN")

echo "Resultado do teste:"
echo "$RESULT" | jq .

if [[ "$RESULT" == *"analytics data"* ]]; then
    echo "✅ CORREÇÃO FUNCIONOU! Autenticação OK!"
else
    echo "❌ Ainda há problemas. Verifique os logs:"
    echo "docker-compose logs api"
fi
