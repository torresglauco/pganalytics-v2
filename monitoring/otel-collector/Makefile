APP_NAME=otel-collector
DOCKER_IMAGE=pganalytics/otel-collector:latest
PORT=9188

.PHONY: build docker-build docker-run clean

# Build local
build:
	@echo "🔨 Building locally..."
	go mod tidy
	go build -o $(APP_NAME) .

# Build Docker
docker-build:
	@echo "🐳 Building Docker image..."
	docker build -t $(DOCKER_IMAGE) .
	@echo "✅ Image criada: $(DOCKER_IMAGE)"

# Executar via Docker
docker-run: docker-build
	@echo "🚀 Executando container..."
	docker run -d \
		--name pganalytics-otel \
		--network pganalytics_default \
		-p $(PORT):$(PORT) \
		-e DATABASE_URL="postgres://postgres:postgres@postgres:5432/pganalytics?sslmode=disable" \
		$(DOCKER_IMAGE)
	@echo "✅ Container rodando na porta $(PORT)"

# Parar
docker-stop:
	docker stop pganalytics-otel || true
	docker rm pganalytics-otel || true

# Logs
logs:
	docker logs -f pganalytics-otel

clean:
	rm -f $(APP_NAME)
	docker rmi $(DOCKER_IMAGE) || true
