#!/bin/bash
echo "🚀 Configurando PGAnalytics Backend..."

# Gerar go.sum se não existir
if [ ! -f "go.sum" ]; then
    echo "📦 Gerando go.sum..."
    go mod tidy
fi

# Limpar containers anteriores
echo "🧹 Limpando containers anteriores..."
docker-compose down -v 2>/dev/null || true

# Iniciar ambiente
echo "🔥 Iniciando ambiente..."
docker-compose up --build

echo "✅ Setup completo!"
