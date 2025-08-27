# PGAnalytics Backend

🚀 Modern PostgreSQL analytics backend built with Go, Gin, and Docker.

## Quick Start

```bash
# 1. Start development environment
make dev

# 2. Test the API
curl http://localhost:8080/health
```

## API Endpoints

### Authentication
- **Login**: `POST /auth/login`
  ```json
  {
    "username": "admin",
    "password": "admin"
  }
  ```

### Analytics (Protected)
- **Submit Metrics**: `POST /api/metrics` (requires Bearer token)
- **Get Data**: `GET /api/data` (requires Bearer token)

### Health Check
- **Health**: `GET /health`

## Development

```bash
# Start everything
make dev

# View logs
make logs

# Restart after code changes
make restart

# Clean everything
make clean
```

## Environment Variables

Copy `.env.example` to `.env` and customize as needed.

## Project Structure

```
pganalytics-backend/
├── cmd/
│   └── server/          # Main application
├── internal/
│   ├── config/          # Configuration
│   ├── database/        # Database connection
│   ├── handlers/        # HTTP handlers
│   └── middleware/      # Middlewares
├── docker-compose.yml   # Development setup
└── Dockerfile.dev       # Development container
```

✅ **Ready to use!** All imports are correct and dependencies are clean.
