# pgAnalytics Modern - Makefile

.PHONY: help build start stop restart logs clean health setup-dev

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)pgAnalytics Modern - Available commands:$(NC)"
	@echo ""
	@echo "  $(GREEN)make build$(NC)      - Build all Docker images"
	@echo "  $(GREEN)make start$(NC)      - Start all services"
	@echo "  $(GREEN)make stop$(NC)       - Stop all services"
	@echo "  $(GREEN)make restart$(NC)    - Restart all services"
	@echo "  $(GREEN)make logs$(NC)       - Show logs from all services"
	@echo "  $(GREEN)make clean$(NC)      - Clean up Docker containers and images"
	@echo "  $(GREEN)make health$(NC)     - Check service health"
	@echo "  $(GREEN)make setup-dev$(NC)  - Setup development environment"
	@echo ""

build:
	@echo "$(BLUE)Building all Docker images...$(NC)"
	docker-compose build --no-cache
	@echo "$(GREEN)✅ Build complete!$(NC)"

start:
	@echo "$(BLUE)Starting all services...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✅ Services started!$(NC)"
	@echo ""
	@echo "$(YELLOW)Access your applications:$(NC)"
	@echo "  🌐 Frontend:    http://localhost:3000"
	@echo "  🔧 Backend API: http://localhost:8000"
	@echo "  📖 API Docs:    http://localhost:8000/docs"
	@echo "  📊 Grafana:     http://localhost:3001 (admin/admin)"
	@echo "  📈 Prometheus:  http://localhost:9090"
	@echo ""
	@echo "$(YELLOW)Check status with:$(NC) make logs"

stop:
	@echo "$(BLUE)Stopping all services...$(NC)"
	docker-compose down
	@echo "$(GREEN)✅ All services stopped$(NC)"

restart: stop start

logs:
	@echo "$(BLUE)Showing logs from all services...$(NC)"
	docker-compose logs -f --tail=100

clean:
	@echo "$(RED)Cleaning up Docker containers and images...$(NC)"
	docker-compose down -v --rmi all
	docker system prune -f
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

health:
	@echo "$(BLUE)Checking service health...$(NC)"
	@echo -n "Backend:    "
	@if curl -sf http://localhost:8000/health > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Healthy$(NC)"; \
	else \
		echo "$(RED)❌ Unhealthy$(NC)"; \
	fi
	@echo -n "Frontend:   "
	@if curl -sf http://localhost:3000 > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Healthy$(NC)"; \
	else \
		echo "$(RED)❌ Unhealthy$(NC)"; \
	fi
	@echo -n "Grafana:    "
	@if curl -sf http://localhost:3001/api/health > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Healthy$(NC)"; \
	else \
		echo "$(RED)❌ Unhealthy$(NC)"; \
	fi
	@echo -n "Prometheus: "
	@if curl -sf http://localhost:9090/-/healthy > /dev/null 2>&1; then \
		echo "$(GREEN)✅ Healthy$(NC)"; \
	else \
		echo "$(RED)❌ Unhealthy$(NC)"; \
	fi

setup-dev:
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)✅ Created .env file from example$(NC)"; \
		echo "$(YELLOW)⚠️  Please edit .env file with your configuration$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  .env file already exists$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Development setup instructions:$(NC)"
	@echo ""
	@echo "$(BLUE)Backend development:$(NC)"
	@echo "  cd backend"
	@echo "  python -m venv venv"
	@echo "  source venv/bin/activate  # Windows: venv\\Scripts\\activate"
	@echo "  pip install -r requirements.txt"
	@echo "  uvicorn app.main:app --reload"
	@echo ""
	@echo "$(BLUE)Frontend development:$(NC)"
	@echo "  cd frontend"
	@echo "  npm install"
	@echo "  npm start"
