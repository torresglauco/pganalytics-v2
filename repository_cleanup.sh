#!/bin/bash
# PGANALYTICS-V2 REPOSITORY CLEANUP SCRIPT
# This script organizes the repository structure and removes unnecessary files

set -e

echo "🧹 Starting Repository Cleanup..."
echo "======================================================"

# Create backup of current state
echo "📋 Creating full repository backup..."
BACKUP_DIR="repository_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
rsync -av --exclude="$BACKUP_DIR" . "$BACKUP_DIR/"
echo "✅ Repository backed up to $BACKUP_DIR"

# 1. Remove experimental and duplicate files
echo "🗑️  Removing experimental and duplicate files..."

# Experimental code variants
declare -a experimental_files=(
    "main.c.with-emojis-broken"
    "main.c.pre-swagger"
    "env_v0.example"
    "Makefile_v0"
)

for file in "${experimental_files[@]}"; do
    if [ -f "$file" ]; then
        rm "$file"
        echo "  ✅ Removed $file"
    fi
done

# Duplicate README files (keep essential ones)
declare -a redundant_readmes=(
    "README_v2.md"
    "README_ENTERPRISE.md"
    "README_EXTENSIONS.md"
    "README_FINAL_UPDATED.md"
    "README_METRICS_FIX.md"
    "README_SCRIPTS.md"
    "MONITORING_README_FINAL.md"
    "RELATORIO_ENHANCED_COMPLETO_20250910_143113.md"
)

for file in "${redundant_readmes[@]}"; do
    if [ -f "$file" ]; then
        # Move to archive instead of deleting (preserve content)
        mkdir -p archive/documentation
        mv "$file" "archive/documentation/"
        echo "  ✅ Archived $file"
    fi
done

# 2. Remove timestamped files
echo "🕐 Removing timestamped diagnostic files..."

# Timestamped diagnostic files
find . -name "diagnostic_*.txt" -delete
find . -name "metrics_enhanced_*.txt" -delete
find . -name "metrics_sample_*.txt" -delete
find . -name "validation_results_*.json" -delete
find . -name "pganalytics_debug_*.tar.gz" -delete

# Remove timestamped directories
find . -type d -name "logs_20*" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "logs_enhanced_*" -exec rm -rf {} + 2>/dev/null || true
find . -type d -name "pganalytics_debug_*" -exec rm -rf {} + 2>/dev/null || true

echo "  ✅ Removed timestamped diagnostic files"

# 3. Organize Docker files
echo "🐳 Organizing Docker configuration..."

mkdir -p docker/collectors
mkdir -p docker/enhanced

# Move collector-specific Dockerfiles
if [ -f "Dockerfile.c-collector" ]; then
    mv "Dockerfile.c-collector" "docker/collectors/"
    echo "  ✅ Moved Dockerfile.c-collector"
fi

if [ -f "Dockerfile.c-collector-enhanced" ]; then
    mv "Dockerfile.c-collector-enhanced" "docker/enhanced/"
    echo "  ✅ Moved Dockerfile.c-collector-enhanced"
fi

if [ -f "docker-compose.enhanced.yml" ]; then
    mv "docker-compose.enhanced.yml" "docker/enhanced/"
    echo "  ✅ Moved docker-compose.enhanced.yml"
fi

# 4. Organize documentation
echo "📚 Organizing documentation..."

mkdir -p docs/{architecture,operations,monitoring,legal}

# Move documentation files
declare -A doc_moves=(
    ["MONITORING.md"]="docs/monitoring/"
    ["OPERATIONS_GUIDE.md"]="docs/operations/"
    ["SWAGGER_EXECUTIVE_SUMMARY.md"]="docs/architecture/"
    ["ANTI_PIRACY.md"]="docs/legal/"
    ["COPYRIGHT.md"]="docs/legal/"
    ["LICENSE_CC_STYLE.md"]="docs/legal/"
    ["LICENSE_COMPARISON.md"]="docs/legal/"
    ["LICENSE_CUSTOM.md"]="docs/legal/"
    ["LICENSE_FAIR_SOURCE.md"]="docs/legal/"
)

for file in "${!doc_moves[@]}"; do
    if [ -f "$file" ]; then
        mv "$file" "${doc_moves[$file]}"
        echo "  ✅ Moved $file to ${doc_moves[$file]}"
    fi
done

# 5. Create organized monitoring structure
echo "📊 Organizing monitoring components..."

# Ensure monitoring directories exist
mkdir -p monitoring/{collectors,exporters,dashboards,alerts}

# Move specific files to appropriate locations
if [ -f "postgresql-analytics-dashboard.json" ]; then
    mv "postgresql-analytics-dashboard.json" "monitoring/dashboards/"
    echo "  ✅ Moved dashboard to monitoring/dashboards/"
fi

# 6. Create clear project structure documentation
echo "📝 Creating project structure documentation..."

cat > PROJECT_STRUCTURE.md << 'EOF'
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
EOF

# 7. Update .gitignore
echo "🚫 Updating .gitignore..."

cat > .gitignore << 'EOF'
# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
pganalytics-v2

# Test binary, built with `go test -c`
*.test

# Output of the go coverage tool
*.out

# Go workspace file
go.work

# Environment files
.env
.env.local
.env.*.local

# Logs
*.log
logs/
log/

# Database
*.db
*.sqlite
*.sqlite3

# Temporary files
*.tmp
*.temp
tmp/
temp/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Docker
.dockerignore

# Backup files
*.backup
*_backup_*
backup_*/
repository_backup_*/

# Diagnostic and debug files
diagnostic_*.txt
metrics_*.txt
validation_results_*.json
debug_*.tar.gz
pganalytics_debug_*/

# Timestamped directories
logs_20*/
logs_enhanced_*/

# Node modules (if any JS tools)
node_modules/

# Build directories
build/
dist/
EOF

# 8. Create standardized README
echo "📖 Creating standardized README..."

cat > README.md << 'EOF'
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
EOF

echo "🎉 Repository cleanup completed!"
echo "📋 Summary of changes:"
echo "  ✅ Removed experimental and duplicate files"
echo "  ✅ Organized Docker configurations"
echo "  ✅ Structured documentation properly"
echo "  ✅ Created clear project structure"
echo "  ✅ Updated .gitignore"
echo "  ✅ Created standardized README"
echo ""
echo "📁 New organized structure:"
echo "  - docker/{collectors,enhanced}"
echo "  - docs/{architecture,operations,monitoring,legal}"
echo "  - monitoring/{dashboards,alerts}"
echo "  - archive/ (preserved removed files)"
echo ""
echo "📋 Backup created in: $BACKUP_DIR"
