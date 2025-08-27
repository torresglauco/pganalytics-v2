#!/bin/bash

echo "🚀 Initializing PgAnalytics Backend..."
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "⚠️  Go is not installed. Docker will handle this."
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "⚠️  docker-compose not found, trying docker compose..."
    if ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose is not installed. Please install Docker Compose."
        exit 1
    fi
fi

# Create go.sum if it doesn't exist and Go is available
if command -v go &> /dev/null; then
    echo "📦 Initializing Go modules..."
    go mod tidy
else
    echo "📦 Go modules will be initialized inside Docker container"
fi

# Copy environment file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
else
    echo "📝 .env file already exists"
fi

# Make scripts executable
chmod +x init.sh 2>/dev/null || true

echo ""
echo "✅ Project initialized successfully!"
echo ""
echo "📋 Next steps:"
echo "  make dev      # Start development environment"
echo "  make logs     # View logs"
echo "  make status   # Check status"
echo "  make help     # See all available commands"
echo ""
echo "🌐 URLs after starting:"
echo "  Backend API:    http://localhost:8080"
echo "  Health Check:   http://localhost:8080/health"
echo "  Database Admin: http://localhost:8081"
