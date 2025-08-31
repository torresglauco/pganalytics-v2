# 🏆 PG Analytics v2 - Enterprise Makefile
# ========================================

.PHONY: help build run test clean

APP_NAME=pganalytics
VERSION=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')

help: ## 📋 Mostrar ajuda
	@echo "🏆 PG Analytics v2 - Comandos Enterprise"
	@echo "========================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# 🔨 BUILD E EXECUÇÃO
build: ## 🔨 Build da aplicação
	@echo "🔨 Building $(APP_NAME) v$(VERSION)..."
	go build -ldflags "-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME)" -o bin/$(APP_NAME) main.go

run: ## 🚀 Executar aplicação
	@echo "🚀 Iniciando $(APP_NAME)..."
	go run main.go

dev: ## 🛠️ Desenvolvimento com live reload
	@echo "🛠️  Modo desenvolvimento..."
	air

# 🧪 TESTES
test: ## 🧪 Testes unitários
	@echo "🧪 Executando testes..."
	go test -v ./...

test-api: ## 🌐 Testes de API
	@echo "🌐 Testando API..."
	chmod +x tests/test_api.sh && ./tests/test_api.sh

test-all: ## 🎯 Todos os testes
	@echo "🎯 Executando todos os testes..."
	make test && make test-api

# 🐳 DOCKER COMPOSE - SETUPS
compose-bypass: ## 🔄 Setup bypass (recomendado)
	@echo "🔄 Iniciando setup bypass..."
	docker-compose -f docker/compose/bypass.yml up -d

compose-monitoring: ## 📊 Setup monitoramento completo
	@echo "📊 Iniciando monitoramento..."
	docker-compose -f docker/compose/monitoring.yml up -d

compose-otel: ## 🔍 Setup OpenTelemetry
	@echo "🔍 Iniciando OpenTelemetry..."
	docker-compose -f docker/compose/otel.yml up -d

compose-prod: ## 🚀 Setup produção
	@echo "🚀 Iniciando produção..."
	docker-compose -f docker/compose/production.yml up -d

compose-down: ## ⏹️ Parar todos os serviços
	@echo "⏹️  Parando serviços..."
	@for file in docker/compose/*.yml; do docker-compose -f "$$file" down 2>/dev/null || true; done
	@docker-compose down 2>/dev/null || true

# 🛠️ UTILITÁRIOS
status: ## 📊 Status do sistema
	@./scripts/system_status.sh

security-check: ## 🔒 Verificação de segurança
	@./scripts/security_check.sh

setup: ## ⚙️ Setup inicial
	@./scripts/setup.sh

logs: ## 📝 Ver logs
	@docker-compose logs -f

# 🧹 LIMPEZA
clean: ## 🧹 Limpeza básica
	@echo "🧹 Limpando arquivos temporários..."
	@rm -rf bin/ tmp/ *.log coverage.out air_tmp/

clean-docker: ## 🐳 Limpeza Docker completa
	@echo "🐳 Limpeza Docker completa..."
	@make compose-down
	@docker system prune -af
	@docker volume prune -f

# 📚 DOCUMENTAÇÃO
docs: ## 📚 Gerar documentação
	@echo "📚 Gerando documentação..."
	@command -v swag >/dev/null && swag init -g main.go || echo "⚠️  swag não instalado"

# 📈 MÉTRICAS E MONITORAMENTO
metrics: ## 📈 Ver métricas
	@echo "📈 Métricas atuais:"
	@curl -s http://localhost:8080/metrics | head -20 || echo "❌ Serviço não disponível"

health: ## 🏥 Health check
	@echo "🏥 Verificando saúde dos serviços..."
	@curl -s http://localhost:8080/health || echo "❌ API offline"
	@curl -s http://localhost:9090/-/ready || echo "❌ Prometheus offline"
	@curl -s http://localhost:3000/api/health || echo "❌ Grafana offline"

# 🔮 VERSÃO E INFO
version: ## 📋 Mostrar versão
	@echo "🏆 $(APP_NAME) v$(VERSION)"
	@echo "📅 Build: $(BUILD_TIME)"
	@echo "🐹 Go: $(shell go version)"

info: ## ℹ️ Informações do projeto
	@echo "🏆 PG Analytics v2 - Sistema Enterprise de Monitoramento PostgreSQL"
	@echo "=============================================================="
	@echo "📊 Componentes:"
	@echo "  • API Go com JWT"
	@echo "  • Coletor C OpenTelemetry"
	@echo "  • Prometheus + Grafana"
	@echo "  • PostgreSQL Analytics"
	@echo ""
	@echo "🌐 Endpoints:"
	@echo "  • API: http://localhost:8080"
	@echo "  • Swagger: http://localhost:8080/swagger/"
	@echo "  • Grafana: http://localhost:3000 (admin/admin)"
	@echo "  • Prometheus: http://localhost:9090"

.DEFAULT_GOAL := help
