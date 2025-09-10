.PHONY: test test-unit test-integration build clean lint

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod
BINARY_NAME=pganalytics-v2

# Build the application
build:
	$(GOBUILD) -o $(BINARY_NAME) -v ./cmd/server

# Run all tests
test: test-unit test-integration

# Run unit tests
test-unit:
	$(GOTEST) -v ./tests/unit/...

# Run integration tests
test-integration:
	$(GOTEST) -v ./tests/integration/...

# Clean build artifacts
clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

# Download dependencies
deps:
	$(GOMOD) download
	$(GOMOD) tidy

# Lint code
lint:
	golangci-lint run

# Run in development
dev:
	$(GOCMD) run ./cmd/server

# Docker build
docker-build:
	docker build -t pganalytics-v2 .

# Docker run
docker-run:
	docker-compose up -d
