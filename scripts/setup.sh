#!/bin/bash
echo "⚙️  PG Analytics v2 - Setup Enterprise"
echo "====================================="

# Verificar dependências
command -v go >/dev/null 2>&1 || { echo "❌ Go não instalado"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker não instalado"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose não instalado"; exit 1; }

echo "✅ Dependências verificadas"

# Configurar .env
if [[ ! -f ".env" ]] && [[ -f ".env.example" ]]; then
    cp .env.example .env
    echo "✅ Arquivo .env criado"
    echo "⚠️  Configure as variáveis em .env"
fi

# Dependências Go
echo "📦 Instalando dependências Go..."
go mod download && go mod verify

# Ferramentas opcionais
echo "🛠️  Instalando ferramentas..."
go install github.com/cosmtrek/air@latest 2>/dev/null || echo "⚠️  Air não instalado"
go install github.com/swaggo/swag/cmd/swag@latest 2>/dev/null || echo "⚠️  Swag não instalado"
go install golang.org/x/vuln/cmd/govulncheck@latest 2>/dev/null || echo "⚠️  Govulncheck não instalado"

# Testar build
echo "🔨 Testando build..."
if go build -o /tmp/pganalytics-test main.go; then
    rm -f /tmp/pganalytics-test
    echo "✅ Build funcionando"
else
    echo "❌ Erro no build"
    exit 1
fi

# Gerar documentação
command -v swag >/dev/null && swag init -g main.go

echo ""
echo "🎉 SETUP CONCLUÍDO!"
echo "=================="
echo "📋 Próximos passos:"
echo "  1. Configure .env com suas credenciais"
echo "  2. make compose-bypass    # Iniciar sistema"
echo "  3. make status           # Verificar status"
echo "  4. make help            # Ver comandos"
echo ""
echo "🌐 Após iniciar, acesse:"
echo "  • http://localhost:8080/swagger/"
echo "  • http://localhost:3000 (Grafana)"
echo "  • http://localhost:9090 (Prometheus)"
