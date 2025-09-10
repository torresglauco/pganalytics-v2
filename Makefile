# PGAnalytics v2 Makefile

.PHONY: help setup build start stop restart status logs clean validate

# Cores para output
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m # No Color

help: ## Mostrar esta ajuda
	@echo "$(GREEN)PGAnalytics v2 - Comandos Disponíveis$(NC)"
	@echo "======================================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Configuração inicial completa
	@echo "$(GREEN)Executando setup completo...$(NC)"
	@bash scripts/setup_final.sh

setup-clean: ## Setup com limpeza de volumes
	@echo "$(GREEN)Executando setup com limpeza...$(NC)"
	@bash scripts/setup_final.sh --clean

build: ## Build de todos os containers
	@echo "$(GREEN)Building containers...$(NC)"
	@docker-compose -f docker-compose-complete.yml build

start: ## Iniciar todos os serviços
	@echo "$(GREEN)Iniciando serviços...$(NC)"
	@docker-compose -f docker-compose-complete.yml up -d

stop: ## Parar todos os serviços
	@echo "$(YELLOW)Parando serviços...$(NC)"
	@docker-compose -f docker-compose-complete.yml down

restart: ## Reiniciar todos os serviços
	@echo "$(YELLOW)Reiniciando serviços...$(NC)"
	@docker-compose -f docker-compose-complete.yml restart

status: ## Ver status dos containers
	@echo "$(GREEN)Status dos containers:$(NC)"
	@docker-compose -f docker-compose-complete.yml ps

logs: ## Ver logs de todos os serviços
	@echo "$(GREEN)Logs dos serviços:$(NC)"
	@docker-compose -f docker-compose-complete.yml logs --tail=50

validate: ## Executar validação completa
	@echo "$(GREEN)Executando validação...$(NC)"
	@bash scripts/validate_complete_stack.sh

clean: ## Limpar containers e volumes
	@echo "$(RED)Limpando containers e volumes...$(NC)"
	@docker-compose -f docker-compose-complete.yml down -v
	@docker system prune -f

metrics: ## Ver métricas do C Collector
	@echo "$(GREEN)Métricas do C Collector:$(NC)"
	@curl -s http://localhost:8080/metrics | head -20

health: ## Verificar saúde de todos os serviços
	@echo "$(GREEN)Health check:$(NC)"
	@echo "C Collector: $$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:8080/health)"
	@echo "Go Backend:  $$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:8081/health)"
	@echo "Prometheus:  $$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:9090/-/healthy)"
	@echo "Grafana:     $$(curl -s -o /dev/null -w "%%{http_code}" http://localhost:3000/api/health)"

info: ## Mostrar informações do ambiente
	@echo "$(GREEN)PGAnalytics v2 - Informações do Ambiente$(NC)"
	@echo "=========================================="
	@echo "📊 Grafana:              http://localhost:3000"
	@echo "📈 Prometheus:           http://localhost:9090"
	@echo "🔧 C Collector:          http://localhost:8080/metrics"
	@echo "🖥️  Go Backend:           http://localhost:8081/health"
	@echo "🗄️  PostgreSQL:           localhost:5432"
