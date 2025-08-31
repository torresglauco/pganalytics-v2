# PG Analytics v2 - PostgreSQL Monitoring Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791)](https://www.postgresql.org/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Latest-orange)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Latest-orange)](https://grafana.com/)

## 🎯 Overview

PG Analytics v2 is an enterprise-grade PostgreSQL monitoring and analytics platform that provides real-time insights into database performance, connection monitoring, and system metrics. Built with a high-performance C collector, Prometheus for metrics aggregation, and Grafana for visualization.

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │───▶│   C Collector    │───▶│   Prometheus    │───▶│     Grafana     │
│   Database      │    │  (Port 8080)     │    │  (Port 9090)    │    │  (Port 3000)    │
│   (Port 5432)   │    │                  │    │                 │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 4GB+ RAM available
- Network ports 3000, 5432, 8080, 9090 available

### 1. Clone and Setup

```bash
git clone <repository-url>
cd pganalytics-v2
```

### 2. Deploy Complete Stack

```bash
# One-command deployment
chmod +x final_cleanup_and_start.sh
./final_cleanup_and_start.sh
```

### 3. Verify Deployment

```bash
# Check all services
docker-compose ps

# Test connectivity
curl http://localhost:8080/health     # C Collector
curl http://localhost:9090/-/ready    # Prometheus
curl http://localhost:3000/api/health # Grafana
```

## 🌐 Service URLs and Credentials

| Service | URL | Credentials | Purpose |
|---------|-----|-------------|---------|
| **PostgreSQL** | `localhost:5432` | `admin` / `admin123` | Database Server |
| **C Collector** | `http://localhost:8080` | None | Metrics Collection |
| **Prometheus** | `http://localhost:9090` | None | Metrics Aggregation |
| **Grafana** | `http://localhost:3000` | `admin` / `admin` | Visualization |

## 📊 Available Metrics

### Database Connection Metrics
- `pganalytics_postgresql_connections{state="active"}` - Active connections
- `pganalytics_postgresql_connections{state="idle"}` - Idle connections  
- `pganalytics_postgresql_connections{state="total"}` - Total connections

### Performance Metrics
- `pganalytics_postgresql_cache_hit_ratio` - Buffer cache hit ratio
- `pganalytics_postgresql_queries_total` - Total queries executed
- `pganalytics_postgresql_slow_queries` - Slow query count

### System Metrics
- `pganalytics_collector_info{version,type}` - Collector information
- `pganalytics_collector_last_update` - Last metrics update timestamp

## ⚙️ Operations

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f c-bypass-collector
docker-compose logs -f postgres
docker-compose logs -f prometheus
docker-compose logs -f grafana
```

### Health Checks
```bash
# Automated health check
make status

# Manual verification
curl http://localhost:8080/health
curl http://localhost:9090/-/ready
curl http://localhost:3000/api/health
```

### Backup & Restore
```bash
# Backup PostgreSQL data
docker exec pganalytics-postgres pg_dump -U admin pganalytics > backup.sql

# Restore PostgreSQL data
docker exec -i pganalytics-postgres psql -U admin pganalytics < backup.sql
```

## 📈 Grafana Setup

### 1. Initial Access
- URL: http://localhost:3000
- Username: `admin`
- Password: `admin`

### 2. Add Prometheus Data Source
1. Navigate to **Configuration** → **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Set URL: `http://prometheus:9090`
5. Click **Save & Test**

### 3. Import Dashboard
Use the provided dashboard JSON or create custom panels with available metrics.

## 🔧 Configuration

### Environment Variables

Create `.env` file for custom configuration:

```bash
# PostgreSQL Configuration
POSTGRES_DB=pganalytics
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin123

# Grafana Configuration  
GF_SECURITY_ADMIN_PASSWORD=admin

# Collector Configuration
COLLECTOR_SCRAPE_INTERVAL=10s
COLLECTOR_DB_HOST=postgres
COLLECTOR_DB_PORT=5432
```

### Custom Prometheus Configuration

Edit `monitoring/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'c-collector'
    static_configs:
      - targets: ['c-bypass-collector:8080']
    metrics_path: '/metrics'
    scrape_interval: 10s
```

## 🛠️ Development

### Build C Collector
```bash
cd monitoring/c-collector
make build
```

### Rebuild Specific Service
```bash
docker-compose build c-bypass-collector
docker-compose up -d c-bypass-collector
```

### Debug Mode
```bash
# Run with debug logging
docker-compose -f docker-compose.yml -f docker-compose.debug.yml up
```

## 📋 Troubleshooting

### Common Issues

#### C Collector Not Starting
```bash
# Check logs
docker logs pganalytics-c-bypass-collector

# Rebuild without cache
docker-compose build --no-cache c-bypass-collector
```

#### PostgreSQL Connection Issues
```bash
# Verify PostgreSQL is healthy
docker exec pganalytics-postgres pg_isready -U admin -d pganalytics

# Check network connectivity
docker exec pganalytics-c-bypass-collector nc -zv postgres 5432
```

#### Grafana Data Source Issues
```bash
# Verify Prometheus connectivity from Grafana
docker exec pganalytics-grafana nc -zv prometheus 9090
```

### Performance Tuning

#### PostgreSQL Optimization
```sql
-- Enable pg_stat_statements for query analytics
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Optimize shared_preload_libraries
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
```

#### Prometheus Retention
```yaml
# Extend metrics retention in prometheus.yml
command:
  - '--storage.tsdb.retention.time=30d'
  - '--storage.tsdb.retention.size=50GB'
```

## 🔒 Security

### Production Considerations

1. **Change Default Passwords**
   ```bash
   # Update .env file with strong passwords
   POSTGRES_PASSWORD=<strong-password>
   GF_SECURITY_ADMIN_PASSWORD=<strong-password>
   ```

2. **Enable SSL/TLS**
   ```yaml
   # Add to docker-compose.yml for Grafana
   environment:
     - GF_SERVER_PROTOCOL=https
     - GF_SERVER_CERT_FILE=/etc/ssl/certs/grafana.crt
     - GF_SERVER_CERT_KEY=/etc/ssl/private/grafana.key
   ```

3. **Network Security**
   ```yaml
   # Restrict external access in docker-compose.yml
   ports:
     - "127.0.0.1:3000:3000"  # Grafana only on localhost
     - "127.0.0.1:9090:9090"  # Prometheus only on localhost
   ```

## 📊 Monitoring Best Practices

### Alert Rules

Create alerts for critical metrics:

```yaml
# alerts.yml
groups:
  - name: postgresql
    rules:
      - alert: PostgreSQLDown
        expr: up{job="c-collector"} == 0
        for: 1m
        
      - alert: HighConnections
        expr: pganalytics_postgresql_connections{state="total"} > 80
        for: 5m
        
      - alert: LowCacheHitRatio
        expr: pganalytics_postgresql_cache_hit_ratio < 0.9
        for: 5m
```

### Dashboard Panels

Essential panels for monitoring:

1. **Connection Overview** - Real-time connection counts
2. **Query Performance** - Query execution trends
3. **Cache Efficiency** - Buffer hit ratios
4. **System Health** - Collector status and uptime

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check this README and inline documentation
- **Issues**: Create an issue in the repository
- **Logs**: Use `docker-compose logs -f <service>` for debugging

## 🔄 Updates

### Version History

- **v2.0.0** - Complete rewrite with C collector, enterprise features
- **v1.x.x** - Legacy Go-based implementation

### Upgrade Notes

When upgrading from v1.x:
1. Backup existing data
2. Update configuration files
3. Run migration scripts if available
4. Test all functionalities

---

**Built with ❤️ for PostgreSQL monitoring**
