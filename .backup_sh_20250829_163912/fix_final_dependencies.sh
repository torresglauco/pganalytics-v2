#!/bin/bash

echo "🔧 CORRIGINDO DEPENDÊNCIAS FINAIS"

# 1. Adicionar dependência CORS que estava faltando
echo "📦 Atualizando go.mod..."
go get github.com/gin-contrib/cors

# 2. Limpar módulos e baixar novamente
echo "🧹 Limpando cache de módulos..."
go mod tidy
go mod download

# 3. Verificar se todas as dependências estão corretas
echo "✅ Verificando dependências..."
go mod verify

echo "✅ DEPENDÊNCIAS CORRIGIDAS!"
