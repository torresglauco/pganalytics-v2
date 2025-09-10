CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2 -I/usr/include/postgresql -I/usr/include/json-c -I/usr/include/curl
LDFLAGS = -lpq -ljson-c -lcurl
TARGET = pg_c_otel_collector
DOCKER_IMAGE = pganalytics/c-otel-collector:latest

.PHONY: build docker-build docker-run docker-stop logs clean

build:
	$(CC) $(CFLAGS) -o $(TARGET) main.c $(LDFLAGS)

docker-build:
	@echo "🔧 Building Cliente C com OpenTelemetry..."
	docker build -t $(DOCKER_IMAGE) .
	@echo "✅ Imagem criada: $(DOCKER_IMAGE)"

docker-run: docker-build
	@echo "🚀 Executando Cliente C com OpenTelemetry..."
	docker run -d \
		--name pganalytics-c-otel \
		-e DATABASE_URL="postgres://postgres:postgres@host.docker.internal:5432/pganalytics?sslmode=disable" \
		-e OTEL_EXPORTER_OTLP_ENDPOINT="http://host.docker.internal:4318/v1/metrics" \
		--network pganalytics_default \
		$(DOCKER_IMAGE)

docker-stop:
	docker stop pganalytics-c-otel || true
	docker rm pganalytics-c-otel || true

logs:
	docker logs -f pganalytics-c-otel

clean:
	rm -f $(TARGET)
	docker rmi $(DOCKER_IMAGE) || true
