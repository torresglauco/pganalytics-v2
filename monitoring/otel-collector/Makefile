# Makefile para PG Analytics OpenTelemetry Collector

.PHONY: build run test clean docker-build docker-run

# Variáveis
APP_NAME=otel-collector
DOCKER_IMAGE=pganalytics/otel-collector:latest
PORT=9188

# Build local
build:
	@echo "🔨 Building OpenTelemetry collector..."
	go mod tidy
	go build -o $(APP_NAME) .
	@echo "✅ Build completo!"

# Executar localmente
run: build
	@echo "🚀 Iniciando coletor..."
	DATABASE_URL="postgres://postgres:postgres@localhost:5432/pganalytics?sslmode=disable" \
	PORT=$(PORT) \
	./$(APP_NAME)

# Testes
test:
	@echo "🧪 Executando testes..."
	go test ./...

# Limpar binários
clean:
	@echo "🧹 Limpando..."
	rm -f $(APP_NAME)
	go clean

# Build Docker
docker-build:
	@echo "🐳 Building Docker image..."
	docker build -t $(DOCKER_IMAGE) .
	@echo "✅ Docker image criada: $(DOCKER_IMAGE)"

# Executar via Docker
docker-run: docker-build
	@echo "🚀 Executando via Docker..."
	docker run -d \
		--name pganalytics-otel \
		--network pganalytics_default \
		-p $(PORT):$(PORT) \
		-e DATABASE_URL="postgres://postgres:postgres@postgres:5432/pganalytics?sslmode=disable" \
		$(DOCKER_IMAGE)
	@echo "✅ Coletor rodando na porta $(PORT)"

# Parar container
docker-stop:
	@echo "⏹️  Parando coletor..."
	docker stop pganalytics-otel || true
	docker rm pganalytics-otel || true

# Logs do container
docker-logs:
	docker logs -f pganalytics-otel

# Deploy completo
deploy: docker-build docker-stop docker-run
	@echo "🎯 Deploy completo!"
	@echo "📊 Métricas: http://localhost:$(PORT)/metrics"
	@echo "❤️  Health: http://localhost:$(PORT)/health"
	@echo "🐌 Slow Queries: http://localhost:$(PORT)/slow-queries"
	@echo "🔗 Conexões: http://localhost:$(PORT)/connections"

# Verificar status
status:
	@echo "📊 Status do coletor:"
	@curl -s http://localhost:$(PORT)/health | jq . || echo "❌ Coletor não está rodando"
