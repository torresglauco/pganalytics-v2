# PGAnalytics Backend

🚀 Modern PostgreSQL analytics backend built with Go, Gin, and Docker.

## Quick Start

```bash
# 1. Start development environment
make dev

# 2. After changing code, restart manually:
make restart
```

## Development

### Without Hot Reload (Simple & Reliable)
- Change your code
- Run `make restart` to see changes
- Fast and reliable!

### Manual Commands
```bash
# Start everything
docker-compose up --build

# View logs
docker-compose logs -f api

# Restart after code changes
docker-compose restart api

# Stop everything
docker-compose down
```

## API Endpoints

- **Health Check**: `GET /health`
- **Authentication**: `POST /auth/login`
- **Metrics**: `POST /api/metrics` (requires auth)
- **Data**: `GET /api/data` (requires auth)

## Environment Variables

Copy `.env.example` to `.env` and customize:

```env
ENV=development
DB_HOST=postgres
DB_PORT=5432
DB_NAME=pganalytics
DB_USER=pganalytics
DB_PASSWORD=pganalytics123
JWT_SECRET=your-super-secret-jwt-key
```

## Project Structure

```
pganalytics-backend/
├── cmd/
│   ├── server/          # Main application
│   └── migrate/         # Migration tool
├── internal/
│   ├── auth/           # Authentication
│   ├── handlers/       # HTTP handlers
│   ├── middleware/     # Middlewares
│   ├── models/         # Data models
│   └── database/       # Database connection
├── migrations/         # SQL migrations
├── docker/             # Docker configs
└── docker-compose.yml  # Development setup
```

## Production Deployment

```bash
# Build production image
docker build -f Dockerfile -t pganalytics-backend .

# Run with environment variables
docker run -p 8080:8080 --env-file .env pganalytics-backend
```

## Next Steps

1. ✅ Backend running with Docker
2. 🔄 Build React frontend dashboard  
3. 🔌 Integrate C/C++ collector
4. 🚀 Deploy to production

---

**Simple, reliable, and ready for production!** 🎯
