#!/bin/bash

echo "🧹 LIMPEZA COMPLETA DE CONFLITOS"

# 1. Listar arquivos que podem estar causando conflitos
echo "🔍 Identificando arquivos conflitantes..."
find internal/ -name "*.go" -exec grep -l "UserCreate\|AuthResponse\|UserLogin\|UserUpdate" {} \; 2>/dev/null || true

# 2. Remover diretórios problemáticos da estrutura original
echo "🗑️ Removendo estrutura conflitante..."
rm -rf internal/services/ 2>/dev/null || true
rm -rf internal/repositories/ 2>/dev/null || true
rm -rf internal/database/ 2>/dev/null || true
rm -rf internal/config/ 2>/dev/null || true

# 3. Manter apenas nossa estrutura funcional
echo "📁 Mantendo apenas estrutura funcional..."
mkdir -p internal/handlers
mkdir -p internal/middleware  
mkdir -p internal/models

# 4. Verificar se ficou apenas nossa implementação
echo "✅ Verificando estrutura final..."
find internal/ -name "*.go" -exec basename {} \;

# 5. Listar dependências no go.mod que podem estar sobrando
echo "📦 Verificando dependências..."
grep -E "(uuid|gorm|postgres)" go.mod || echo "✅ Sem dependências problemáticas"

echo "✅ LIMPEZA DE CONFLITOS CONCLUÍDA!"
