# Project Structure

## Directory Layout

```
pganalytics-v2/
├── cmd/                    # Application entry points
│   └── server/            # Main server application
├── internal/              # Private application code
│   ├── config/           # Configuration management
│   ├── database/         # Database connection and operations
│   ├── handlers/         # HTTP request handlers
│   └── middleware/       # HTTP middleware
├── pkg/                   # Public library code
│   ├── auth/            # Authentication utilities
│   └── metrics/         # Metrics collection
├── monitoring/           # Monitoring and observability
│   ├── c-collector/     # C-based metrics collector
│   ├── collector-c-otel/ # OpenTelemetry C collector
│   ├── prometheus/      # Prometheus configuration
│   ├── grafana/         # Grafana dashboards
│   ├── dashboards/      # Pre-built dashboards
│   └── alerts/          # Alerting rules
├── docker/              # Docker configurations
│   ├── collectors/      # Collector-specific Dockerfiles
│   └── enhanced/        # Enhanced deployment configs
├── docs/                # Documentation
│   ├── architecture/    # Architecture documentation
│   ├── operations/      # Operations guides
│   ├── monitoring/      # Monitoring documentation
│   └── legal/          # Legal documents
├── tests/               # Test suites
│   ├── unit/           # Unit tests
│   └── integration/    # Integration tests
├── scripts/             # Utility scripts
├── migrations/          # Database migrations
└── archive/            # Archived files (for reference)
```

## Key Files

- `main.go` - Legacy monolithic application (deprecated)
- `cmd/server/main.go` - New modular application entry point
- `docker-compose.yml` - Main Docker Compose configuration
- `Makefile` - Build and development automation
- `.env.example` - Environment variable template
- `go.mod` - Go module dependencies
- `README.md` - Main project documentation

## Development Guidelines

1. Use the modular structure in `cmd/` and `internal/`
2. Place all new features in appropriate packages
3. Write tests for all new functionality
4. Update documentation when adding features
5. Follow Go best practices and conventions

## Migration from Legacy Structure

The legacy `main.go` is preserved for reference but should not be used for new development. 
Use `cmd/server/main.go` and the modular structure instead.
