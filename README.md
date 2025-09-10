# PGAnalytics v2 - Modern PostgreSQL Monitoring

A modern, containerized PostgreSQL monitoring and analytics platform with OpenTelemetry integration, Prometheus metrics, and Grafana visualization.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Go 1.19+ (for development)
- PostgreSQL 12+ (target database)

### Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Generate JWT secret
openssl rand -base64 32

# Edit .env with your configuration
vim .env
```

### Run with Docker
```bash
# Start all services
docker-compose up -d

# Check health
curl http://localhost:8080/health

# View metrics
curl http://localhost:8080/metrics
```

## 📊 Features

- **Comprehensive PostgreSQL Monitoring**: 25+ metrics covering connections, queries, locks, replication, and cache performance
- **Modern Tech Stack**: Go backend, C collectors, OpenTelemetry integration
- **Multi-Tenant Support**: Built-in tenant isolation for enterprise environments
- **Container-Ready**: Docker and Kubernetes deployment support
- **Grafana Dashboards**: Pre-built visualization dashboards
- **Prometheus Integration**: Native metrics export for alerting and analysis

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   C Collector   │    │   Go Backend    │
│    Database     │◄───┤   (C/OTel)     │◄───┤   (Gin/REST)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │                       │
                               ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │◄───┤     Metrics     │    │     Auth &      │
│    (TSDB)       │    │    Endpoint     │    │   Management    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐
│     Grafana     │
│  (Dashboards)   │
└─────────────────┘
```

## 🛠️ Development

### Local Development
```bash
# Install dependencies
make deps

# Run tests
make test

# Run locally
make dev

# Build binary
make build
```

### Project Structure
```
cmd/server/          # Application entry point
internal/            # Private application code
  ├── config/        # Configuration management
  ├── handlers/      # HTTP handlers
  └── middleware/    # HTTP middleware
monitoring/          # Monitoring components
docs/               # Documentation
tests/              # Test suites
```

## 📚 Documentation

- [Architecture Guide](docs/architecture/)
- [Operations Guide](docs/operations/)
- [Monitoring Setup](docs/monitoring/)
- [API Documentation](docs/api/)

## 🔒 Security

See [SECURITY.md](SECURITY.md) for security configuration and best practices.

## 📝 License

See [LICENSE](LICENSE) for licensing information.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📊 Monitoring Metrics

PGAnalytics v2 provides comprehensive PostgreSQL monitoring including:

### Connection Metrics
- Total connections
- Active connections  
- Idle connections
- Idle in transaction

### Performance Metrics
- Query execution times
- Slow query detection
- Transaction rates
- Cache hit ratios

### Resource Metrics
- Database sizes
- Lock activity
- Replication lag
- Background writer activity

[View complete metrics list](docs/monitoring/METRICS.md)
