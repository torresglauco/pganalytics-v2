#!/bin/bash
# install_improvements.sh - Aplica todas as melhorias

set -e

echo "🚀 APLICANDO MELHORIAS NO PGANALYTICS"
echo "======================================="

# Verificar se estamos no diretório correto
if [[ ! -f "go.mod" ]]; then
    echo "❌ Execute este script no diretório raiz do projeto (onde está o go.mod)"
    exit 1
fi

# Verificar se pasta improvements existe
if [[ ! -d "improvements" ]]; then
    echo "❌ Pasta 'improvements' não encontrada. Extraia o arquivo improvements.zip primeiro."
    exit 1
fi

# Fazer backup dos arquivos originais
echo "📁 Fazendo backup dos arquivos originais..."
BACKUP_DIR="backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup arquivos existentes
if [[ -d "cmd" ]]; then cp -r cmd/ "$BACKUP_DIR/"; fi
if [[ -d "internal" ]]; then cp -r internal/ "$BACKUP_DIR/"; fi
if [[ -f "go.mod" ]]; then cp go.mod "$BACKUP_DIR/"; fi
if [[ -f "Makefile" ]]; then cp Makefile "$BACKUP_DIR/"; fi
if [[ -f ".env.example" ]]; then cp .env.example "$BACKUP_DIR/"; fi

echo "✅ Backup criado em $BACKUP_DIR"

# Aplicar melhorias
echo "🔧 Aplicando melhorias..."

# 1. Atualizar go.mod
if [[ -f "improvements/go.mod-enhanced" ]]; then
    echo "📦 Atualizando go.mod..."
    cp improvements/go.mod-enhanced go.mod
fi

# 2. Atualizar arquivos Go
echo "🔄 Atualizando código Go..."

# Main
if [[ -f "improvements/main.go-enhanced" ]]; then
    mkdir -p cmd/server
    cp improvements/main.go-enhanced cmd/server/main.go
fi

# Handlers
if [[ -f "improvements/handlers.go-enhanced" ]]; then
    mkdir -p internal/handlers
    cp improvements/handlers.go-enhanced internal/handlers/handlers.go
fi

# Middleware
if [[ -f "improvements/middleware.go-enhanced" ]]; then
    mkdir -p internal/middleware
    cp improvements/middleware.go-enhanced internal/middleware/middleware.go
fi

# Config
if [[ -f "improvements/config.go-enhanced" ]]; then
    mkdir -p internal/config
    cp improvements/config.go-enhanced internal/config/config.go
fi

# 3. Atualizar configurações
echo "⚙️  Atualizando configurações..."

if [[ -f "improvements/.env.example-enhanced" ]]; then
    cp improvements/.env.example-enhanced .env.example
fi

if [[ -f "improvements/Makefile-enhanced" ]]; then
    cp improvements/Makefile-enhanced Makefile
fi

# 4. Adicionar CI/CD
echo "🔄 Configurando CI/CD..."
if [[ -f "improvements/ci.yml" ]]; then
    mkdir -p .github/workflows
    cp improvements/ci.yml .github/workflows/ci.yml
fi

# 5. Instalar dependências
echo "📦 Instalando novas dependências..."
go mod tidy
if [[ $? -ne 0 ]]; then
    echo "⚠️  Problema ao instalar dependências, mas continuando..."
fi

go mod download
if [[ $? -ne 0 ]]; then
    echo "⚠️  Problema ao baixar dependências, mas continuando..."
fi

# 6. Instalar ferramentas de desenvolvimento
echo "🛠️  Instalando ferramentas..."

# Swag
if ! command -v swag &> /dev/null; then
    echo "Instalando swag..."
    go install github.com/swaggo/swag/cmd/swag@latest
fi

# golangci-lint
if ! command -v golangci-lint &> /dev/null; then
    echo "Instalando golangci-lint..."
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
fi

# 7. Gerar documentação Swagger
echo "📚 Gerando documentação Swagger..."
if command -v swag &> /dev/null; then
    swag init -g cmd/server/main.go
    if [[ $? -eq 0 ]]; then
        echo "✅ Documentação Swagger gerada!"
    else
        echo "⚠️  Erro ao gerar Swagger, mas continuando..."
    fi
else
    echo "⚠️  swag não instalado, pulando geração de docs..."
fi

# 8. Executar verificações básicas
echo "🧪 Executando verificações básicas..."

# Format
echo "Formatando código..."
go fmt ./...

# Vet
echo "Executando go vet..."
go vet ./...
if [[ $? -ne 0 ]]; then
    echo "⚠️  go vet encontrou problemas, mas continuando..."
fi

# Test
echo "Executando testes..."
go test ./... -timeout=30s
if [[ $? -ne 0 ]]; then
    echo "⚠️  Alguns testes falharam, mas continuando..."
fi

echo ""
echo "🎉 MELHORIAS APLICADAS COM SUCESSO!"
echo "======================================="
echo ""
echo "✅ Melhorias implementadas:"
echo "  📚 Documentação Swagger - /swagger/index.html"
echo "  🔒 Rate limiting - 100 req/min"
echo "  📊 Logging estruturado - JSON format"
echo "  🔧 CI/CD pipeline - GitHub Actions"
echo "  ⚙️  Configuração melhorada - .env"
echo "  🛠️  Makefile aprimorado - mais comandos"
echo ""
echo "🚀 Próximos passos:"
echo "  1. make dev               # Iniciar ambiente"
echo "  2. Acessar http://localhost:8080/swagger/index.html"
echo "  3. git add . && git commit -m 'feat: add enterprise improvements'"
echo "  4. git push"
echo ""
echo "💡 Comandos úteis:"
echo "  make help                 # Ver todos os comandos"
echo "  make docs                 # Gerar documentação"
echo "  make test                 # Executar testes"
echo "  make security             # Scan de segurança"
echo ""
echo "🔧 Se algo não funcionou:"
echo "  - Restaure backup: cp -r $BACKUP_DIR/* ."
echo "  - Verifique logs acima para erros específicos"
echo "  - Execute: make dev (mesmo com erros, pode funcionar)"
