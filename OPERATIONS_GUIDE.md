# Operations Guide - PG Analytics v2

## 🚀 Deployment Operations

### Production Deployment Checklist

#### Pre-Deployment
- [ ] Verify Docker and Docker Compose versions
- [ ] Check available system resources (4GB+ RAM)
- [ ] Ensure required ports are available (3000, 5432, 8080, 9090)
- [ ] Review and update environment variables
- [ ] Backup existing data if upgrading

#### Deployment Steps
```bash
# 1. Clone repository
git clone <repository-url>
cd pganalytics-v2

# 2. Configure environment
cp .env.example .env
# Edit .env with production values

# 3. Deploy stack
chmod +x final_cleanup_and_start.sh
./final_cleanup_and_start.sh

# 4. Verify deployment
curl http://localhost:8080/health
curl http://localhost:9090/-/ready
curl http://localhost:3000/api/health
```

#### Post-Deployment
- [ ] Configure Grafana data source
- [ ] Import or create dashboards
- [ ] Set up alerting rules
- [ ] Configure backup procedures
- [ ] Document custom configurations

### Environment-Specific Configurations

#### Development Environment
```bash
# .env.development
POSTGRES_PASSWORD=dev123
GF_SECURITY_ADMIN_PASSWORD=dev
COLLECTOR_SCRAPE_INTERVAL=5s
LOG_LEVEL=debug
```

#### Staging Environment
```bash
# .env.staging
POSTGRES_PASSWORD=staging_secure_password
GF_SECURITY_ADMIN_PASSWORD=staging_admin
COLLECTOR_SCRAPE_INTERVAL=10s
LOG_LEVEL=info
```

#### Production Environment
```bash
# .env.production
POSTGRES_PASSWORD=very_secure_production_password
GF_SECURITY_ADMIN_PASSWORD=secure_admin_password
COLLECTOR_SCRAPE_INTERVAL=15s
LOG_LEVEL=warn
GF_SERVER_PROTOCOL=https
```

## 🔧 Operational Commands

### Service Management

#### Start Services
```bash
# Start all services
docker-compose up -d

# Start specific service
docker-compose up -d postgres
docker-compose up -d c-bypass-collector
docker-compose up -d prometheus
docker-compose up -d grafana
```

#### Stop Services
```bash
# Stop all services
docker-compose down

# Stop specific service
docker-compose stop postgres
docker-compose stop c-bypass-collector
docker-compose stop prometheus
docker-compose stop grafana
```

#### Restart Services
```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart c-bypass-collector
```

#### Update Services
```bash
# Pull latest images
docker-compose pull

# Rebuild and restart services
docker-compose up -d --build

# Force rebuild without cache
docker-compose build --no-cache
docker-compose up -d
```

### Health Monitoring

#### System Health Check Script
```bash
#!/bin/bash
# health_check.sh

echo "=== PG Analytics Health Check ==="
echo "Date: $(date)"
echo ""

# Check Docker containers
echo "🐳 Container Status:"
docker-compose ps

echo ""
echo "🌐 Service Connectivity:"

# PostgreSQL
if docker exec pganalytics-postgres pg_isready -U admin -d pganalytics >/dev/null 2>&1; then
    echo "✅ PostgreSQL: Connected"
else
    echo "❌ PostgreSQL: Connection failed"
fi

# C Collector
if curl -sf http://localhost:8080/health >/dev/null; then
    echo "✅ C Collector: Healthy"
else
    echo "❌ C Collector: Health check failed"
fi

# Prometheus
if curl -sf http://localhost:9090/-/ready >/dev/null; then
    echo "✅ Prometheus: Ready"
else
    echo "❌ Prometheus: Not ready"
fi

# Grafana
if curl -sf http://localhost:3000/api/health >/dev/null; then
    echo "✅ Grafana: Healthy"
else
    echo "❌ Grafana: Health check failed"
fi

echo ""
echo "📊 Quick Metrics Check:"
curl -s http://localhost:8080/metrics | grep -E "(pganalytics_postgresql_connections|pganalytics_collector_info)" | head -3
```

### Log Management

#### View Logs
```bash
# All services
docker-compose logs -f

# Specific service logs
docker-compose logs -f postgres
docker-compose logs -f c-bypass-collector
docker-compose logs -f prometheus
docker-compose logs -f grafana

# Last N lines
docker-compose logs --tail=100 c-bypass-collector

# Filter logs by time
docker-compose logs --since="2023-01-01T00:00:00" c-bypass-collector
```

#### Log Rotation Setup
```bash
# Create logrotate configuration
sudo tee /etc/logrotate.d/pganalytics << EOF
/var/log/pganalytics/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker-compose restart pganalytics-*
    endscript
}
EOF
```

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

#### Issue: C Collector Won't Start
**Symptoms:**
- Container exits immediately
- Health check fails
- No metrics available

**Diagnosis:**
```bash
# Check container logs
docker logs pganalytics-c-bypass-collector

# Check PostgreSQL connectivity
docker exec pganalytics-c-bypass-collector nc -zv postgres 5432

# Verify build
docker-compose build --no-cache c-bypass-collector
```

**Solutions:**
1. **PostgreSQL not ready**: Wait for PostgreSQL to fully start
2. **Build issues**: Clean rebuild with `--no-cache`
3. **Connection issues**: Check network configuration
4. **Permission issues**: Verify user permissions in Dockerfile

#### Issue: Grafana Shows "No Data"
**Symptoms:**
- Dashboards show no data
- Data source connection fails
- Queries return empty results

**Diagnosis:**
```bash
# Check Prometheus data
curl http://localhost:9090/api/v1/query?query=up

# Check collector metrics
curl http://localhost:8080/metrics

# Test Prometheus from Grafana container
docker exec pganalytics-grafana nc -zv prometheus 9090
```

**Solutions:**
1. **Data source URL**: Use `http://prometheus:9090` (not localhost)
2. **Network issues**: Verify containers are on same network
3. **Time range**: Check dashboard time range settings
4. **Metrics availability**: Verify collector is producing metrics

#### Issue: High Memory Usage
**Symptoms:**
- System becomes slow
- Out of memory errors
- Container restarts

**Diagnosis:**
```bash
# Check container memory usage
docker stats

# Check Prometheus storage
docker exec pganalytics-prometheus du -sh /prometheus

# Check PostgreSQL memory
docker exec pganalytics-postgres cat /proc/meminfo
```

**Solutions:**
1. **Increase retention settings**: Reduce Prometheus retention
2. **Optimize queries**: Use recording rules for expensive queries
3. **Resource limits**: Set memory limits in docker-compose.yml
4. **System resources**: Increase available RAM

#### Issue: Database Connection Limit Exceeded
**Symptoms:**
- Connection refused errors
- Application timeouts
- High connection count metrics

**Diagnosis:**
```bash
# Check current connections
docker exec pganalytics-postgres psql -U admin -d pganalytics -c "SELECT count(*) FROM pg_stat_activity;"

# Check connection limit
docker exec pganalytics-postgres psql -U admin -d pganalytics -c "SHOW max_connections;"
```

**Solutions:**
1. **Increase max_connections**: Edit PostgreSQL configuration
2. **Connection pooling**: Implement connection pooling
3. **Query optimization**: Optimize long-running queries
4. **Application tuning**: Reduce connection lifetime

### Performance Troubleshooting

#### Slow Query Analysis
```sql
-- Enable slow query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;
SELECT pg_reload_conf();

-- Find slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

#### Connection Pool Analysis
```sql
-- Active connections by state
SELECT state, count(*)
FROM pg_stat_activity
WHERE state IS NOT NULL
GROUP BY state;

-- Long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

#### Resource Usage Analysis
```bash
# Container resource usage
docker stats --format "table {{.Container}}	{{.CPUPerc}}	{{.MemUsage}}	{{.NetIO}}	{{.BlockIO}}"

# Disk usage by service
docker exec pganalytics-postgres du -sh /var/lib/postgresql/data
docker exec pganalytics-prometheus du -sh /prometheus
```

## 📊 Performance Monitoring

### Key Performance Indicators (KPIs)

#### Database Performance
- **Connection Utilization**: < 80% of max_connections
- **Cache Hit Ratio**: > 95%
- **Average Query Time**: < 100ms
- **Active Sessions**: Monitor for spikes

#### System Performance
- **Collector Response Time**: < 50ms
- **Metrics Scrape Duration**: < 5s
- **Memory Usage**: < 80% of available
- **Disk I/O**: Monitor for bottlenecks

#### Application Performance
- **Dashboard Load Time**: < 3s
- **Alert Response Time**: < 1 minute
- **Data Freshness**: < 15s delay

### Performance Optimization

#### Database Optimization
```sql
-- Optimize PostgreSQL settings
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
SELECT pg_reload_conf();
```

#### Collector Optimization
```c
// C collector optimizations
#define MAX_CONNECTIONS 100
#define BATCH_SIZE 1000
#define CACHE_TTL 10

// Use prepared statements
PGresult *prepare_query(const char *query) {
    return PQprepare(conn, "stmt", query, 0, NULL);
}
```

#### Prometheus Optimization
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Recording rules for expensive queries
recording_rules:
  - name: pganalytics_rules
    rules:
      - record: pganalytics:connection_utilization
        expr: pganalytics_postgresql_connections{state="total"} / pganalytics_postgresql_max_connections * 100
```

## 🔐 Security Operations

### Security Hardening Checklist

#### Authentication & Authorization
- [ ] Change default passwords
- [ ] Enable two-factor authentication for Grafana
- [ ] Configure LDAP/SSO integration
- [ ] Set up role-based access control

#### Network Security
- [ ] Use HTTPS for all web interfaces
- [ ] Configure firewall rules
- [ ] Enable VPN access for remote monitoring
- [ ] Implement network segmentation

#### Data Protection
- [ ] Encrypt data at rest
- [ ] Encrypt data in transit
- [ ] Regular security updates
- [ ] Backup encryption

#### Monitoring & Auditing
- [ ] Enable audit logging
- [ ] Monitor failed login attempts
- [ ] Set up security alerts
- [ ] Regular security assessments

### SSL/TLS Configuration

#### Grafana HTTPS Setup
```yaml
# docker-compose.yml
grafana:
  environment:
    - GF_SERVER_PROTOCOL=https
    - GF_SERVER_CERT_FILE=/etc/ssl/certs/grafana.crt
    - GF_SERVER_CERT_KEY=/etc/ssl/private/grafana.key
  volumes:
    - ./ssl/grafana.crt:/etc/ssl/certs/grafana.crt:ro
    - ./ssl/grafana.key:/etc/ssl/private/grafana.key:ro
```

#### PostgreSQL SSL Setup
```yaml
postgres:
  environment:
    - POSTGRES_SSL_MODE=require
  volumes:
    - ./ssl/server.crt:/var/lib/postgresql/server.crt:ro
    - ./ssl/server.key:/var/lib/postgresql/server.key:ro
```

## 🗄️ Backup & Recovery

### Automated Backup Script
```bash
#!/bin/bash
# backup.sh

BACKUP_DIR="/backup/pganalytics"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
echo "Backing up PostgreSQL..."
docker exec pganalytics-postgres pg_dump -U admin pganalytics | gzip > "$BACKUP_DIR/postgres_$DATE.sql.gz"

# Backup Grafana dashboards
echo "Backing up Grafana..."
docker exec pganalytics-grafana grafana-cli admin export-dashboards | gzip > "$BACKUP_DIR/grafana_$DATE.json.gz"

# Backup Prometheus data
echo "Backing up Prometheus..."
docker exec pganalytics-prometheus tar czf - /prometheus > "$BACKUP_DIR/prometheus_$DATE.tar.gz"

# Cleanup old backups (keep 30 days)
find "$BACKUP_DIR" -name "*.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR"
```

### Recovery Procedures
```bash
# Restore PostgreSQL
gunzip -c postgres_backup.sql.gz | docker exec -i pganalytics-postgres psql -U admin pganalytics

# Restore Grafana
gunzip -c grafana_backup.json.gz | docker exec -i pganalytics-grafana grafana-cli admin import-dashboards

# Restore Prometheus (requires service restart)
docker-compose down prometheus
docker run --rm -v pganalytics_prometheus-data:/data -v $(pwd):/backup alpine tar xzf /backup/prometheus_backup.tar.gz -C /data
docker-compose up -d prometheus
```

---

**For additional support, refer to the main [README.md](README.md) and [MONITORING_README.md](MONITORING_README.md)**
