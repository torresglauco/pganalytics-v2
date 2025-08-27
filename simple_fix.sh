#!/bin/bash
# simple_fix.sh - Correção super simples

echo "⚡ CORREÇÃO RÁPIDA"
echo "=================="

# Remover import problemático temporariamente
echo "🔧 Removendo import problemático..."
sed -i.bak '/pganalytics-backend\/docs/d' cmd/server/main.go

# Instalar swag
echo "📦 Instalando swag..."
go install github.com/swaggo/swag/cmd/swag@latest

# Gerar docs
echo "📚 Gerando docs..."
swag init -g cmd/server/main.go

# Verificar
echo "🧪 Verificando..."
go vet ./...

echo "✅ PRONTO! Execute: make dev"
