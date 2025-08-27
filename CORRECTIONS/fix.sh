#!/bin/bash
echo "🔧 Aplicando correções..."

# 1. Gerar go.sum localmente
echo "📦 Gerando go.sum..."
go mod tidy

# 2. Limpar Docker completamente
echo "🧹 Limpando Docker..."
docker-compose down -v
docker system prune -f

# 3. Rebuild completo
echo "🔨 Rebuild completo..."
docker-compose build --no-cache

# 4. Iniciar ambiente
echo "🚀 Iniciando ambiente..."
docker-compose up

echo "✅ Correções aplicadas!"
