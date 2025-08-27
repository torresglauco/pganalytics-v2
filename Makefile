# Makefile for PGAnalytics Backend

.PHONY: help dev build clean test logs restart

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev: ## Start development environment
	@echo "🚀 Starting PGAnalytics development environment..."
	docker-compose up --build

build: ## Build the application
	@echo "🔨 Building PGAnalytics..."
	docker-compose build

clean: ## Clean up containers and images
	@echo "🧹 Cleaning up..."
	docker-compose down -v
	docker system prune -f

logs: ## Show application logs
	docker-compose logs -f api

restart: ## Restart the API service
	@echo "🔄 Restarting API service..."
	docker-compose restart api
