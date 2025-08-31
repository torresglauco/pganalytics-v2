# Monitoring System Documentation

## 📊 Monitoring Architecture Overview

The PG Analytics v2 monitoring system consists of four main components working together to provide comprehensive PostgreSQL monitoring:

### Components

#### 1. C Collector (Port 8080)
- **Purpose**: High-performance metrics collection from PostgreSQL
- **Language**: C (optimized for minimal overhead)
- **Metrics Endpoint**: `/metrics`
- **Health Endpoint**: `/health`
- **Update Interval**: 10 seconds

#### 2. PostgreSQL Database (Port 5432)
- **Version**: PostgreSQL 15
- **Database**: `pganalytics`
- **User**: `admin`
- **Password**: `admin123`
- **Extensions**: `pg_stat_statements`, `pg_stat_activity`

#### 3. Prometheus (Port 9090)
- **Purpose**: Metrics aggregation and storage
- **Scrape Interval**: 15 seconds
- **Retention**: 15 days (configurable)
- **Storage**: Time-series database

#### 4. Grafana (Port 3000)
- **Purpose**: Visualization and dashboards
- **Default Login**: admin/admin
- **Data Source**: Prometheus
- **Dashboard**: PostgreSQL Analytics

## 🔧 Detailed Configuration

### C Collector Configuration

The C collector is optimized for minimal resource usage while providing comprehensive metrics:

```c
// Key metrics collected:
- PostgreSQL connections (active, idle, total)
- Cache hit ratios
- Query execution statistics
- Database size and growth
- Lock information
- Table statistics
```

### Prometheus Configuration

Located at `monitoring/prometheus/prometheus.yml`:

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
    metrics_path: '/metrics'
    
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

### Alert Rules Configuration

Create `monitoring/prometheus/alerts.yml`:

```yaml
groups:
  - name: postgresql_alerts
    rules:
      - alert: PostgreSQLDown
        expr: up{job="c-collector"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL collector is down"
          description: "PostgreSQL metrics collector has been down for more than 1 minute"

      - alert: HighDatabaseConnections
        expr: pganalytics_postgresql_connections{state="total"} > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High number of database connections"
          description: "Database has {{ $value }} connections, which is above the threshold"

      - alert: LowCacheHitRatio
        expr: pganalytics_postgresql_cache_hit_ratio < 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low cache hit ratio"
          description: "Cache hit ratio is {{ $value }}, which is below 90%"

      - alert: DatabaseGrowthRate
        expr: increase(pganalytics_postgresql_database_size_bytes[1h]) > 100000000
        for: 0m
        labels:
          severity: info
        annotations:
          summary: "High database growth rate"
          description: "Database has grown by {{ $value }} bytes in the last hour"
```

## 📈 Available Metrics Reference

### Connection Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|---------|
| `pganalytics_postgresql_connections` | Gauge | Number of connections | `state`: active, idle, total |
| `pganalytics_postgresql_max_connections` | Gauge | Maximum allowed connections | - |
| `pganalytics_postgresql_connection_utilization` | Gauge | Connection utilization percentage | - |

### Performance Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|---------|
| `pganalytics_postgresql_cache_hit_ratio` | Gauge | Buffer cache hit ratio (0-1) | - |
| `pganalytics_postgresql_queries_total` | Counter | Total number of queries | `type`: select, insert, update, delete |
| `pganalytics_postgresql_slow_queries` | Counter | Number of slow queries | `duration`: >1s, >5s, >10s |
| `pganalytics_postgresql_transactions_total` | Counter | Total transactions | `state`: committed, rolled_back |

### Database Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|---------|
| `pganalytics_postgresql_database_size_bytes` | Gauge | Database size in bytes | `database` |
| `pganalytics_postgresql_table_size_bytes` | Gauge | Table size in bytes | `database`, `schema`, `table` |
| `pganalytics_postgresql_index_size_bytes` | Gauge | Index size in bytes | `database`, `schema`, `table`, `index` |

### System Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|---------|
| `pganalytics_collector_info` | Gauge | Collector information | `version`, `type` |
| `pganalytics_collector_last_update` | Gauge | Last metrics update timestamp | - |
| `pganalytics_collector_scrape_duration_seconds` | Gauge | Time taken to scrape metrics | - |

### Lock Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|---------|
| `pganalytics_postgresql_locks_total` | Gauge | Current number of locks | `mode`, `locktype` |
| `pganalytics_postgresql_deadlocks_total` | Counter | Total number of deadlocks | - |
| `pganalytics_postgresql_lock_waits_total` | Counter | Total lock waits | - |

## 📊 Grafana Dashboard Setup

### Step-by-Step Configuration

1. **Access Grafana**
   ```
   URL: http://localhost:3000
   Username: admin
   Password: admin
   ```

2. **Add Prometheus Data Source**
   - Go to Configuration → Data Sources
   - Click "Add data source"
   - Select "Prometheus"
   - URL: `http://prometheus:9090`
   - Access: Server (default)
   - Click "Save & Test"

3. **Create PostgreSQL Dashboard**

### Essential Dashboard Panels

#### Panel 1: Connection Overview
```json
{
  "title": "PostgreSQL Connections",
  "type": "stat",
  "targets": [
    {
      "expr": "pganalytics_postgresql_connections{state="total"}",
      "legendFormat": "Total"
    },
    {
      "expr": "pganalytics_postgresql_connections{state="active"}",
      "legendFormat": "Active"
    },
    {
      "expr": "pganalytics_postgresql_connections{state="idle"}",
      "legendFormat": "Idle"
    }
  ]
}
```

#### Panel 2: Cache Hit Ratio
```json
{
  "title": "Cache Hit Ratio",
  "type": "gauge",
  "targets": [
    {
      "expr": "pganalytics_postgresql_cache_hit_ratio * 100",
      "legendFormat": "Hit Ratio %"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "min": 0,
      "max": 100,
      "thresholds": {
        "steps": [
          {"color": "red", "value": 0},
          {"color": "yellow", "value": 80},
          {"color": "green", "value": 95}
        ]
      }
    }
  }
}
```

#### Panel 3: Query Rate
```json
{
  "title": "Queries per Second",
  "type": "graph",
  "targets": [
    {
      "expr": "rate(pganalytics_postgresql_queries_total[5m])",
      "legendFormat": "{{type}} queries/sec"
    }
  ]
}
```

#### Panel 4: Database Growth
```json
{
  "title": "Database Size Growth",
  "type": "graph",
  "targets": [
    {
      "expr": "pganalytics_postgresql_database_size_bytes / 1024 / 1024 / 1024",
      "legendFormat": "{{database}} (GB)"
    }
  ]
}
```

## 🚨 Alerting Setup

### AlertManager Configuration

Create `monitoring/alertmanager/alertmanager.yml`:

```yaml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@pganalytics.local'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://localhost:5001/'
        
  - name: 'email-notifications'
    email_configs:
      - to: 'admin@company.com'
        subject: 'PostgreSQL Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Value: {{ .ValueString }}
          {{ end }}
```

### Slack Integration

```yaml
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
        title: 'PostgreSQL Alert'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

## 🔍 Monitoring Queries

### Useful Prometheus Queries

#### Connection Monitoring
```promql
# Connection utilization percentage
(pganalytics_postgresql_connections{state="total"} / pganalytics_postgresql_max_connections) * 100

# Active connections trend
increase(pganalytics_postgresql_connections{state="active"}[5m])
```

#### Performance Analysis
```promql
# Query rate by type
rate(pganalytics_postgresql_queries_total[5m])

# Average query duration
pganalytics_postgresql_query_duration_seconds / pganalytics_postgresql_queries_total

# Slow query percentage
(pganalytics_postgresql_slow_queries / pganalytics_postgresql_queries_total) * 100
```

#### Resource Utilization
```promql
# Cache efficiency
pganalytics_postgresql_cache_hit_ratio

# Database growth rate (MB per hour)
increase(pganalytics_postgresql_database_size_bytes[1h]) / 1024 / 1024

# Lock contention
pganalytics_postgresql_locks_total{mode="ExclusiveLock"}
```

## 🔧 Advanced Configuration

### Custom Metrics Collection

To add custom metrics to the C collector:

1. **Edit collector source** (`monitoring/c-collector/main.c`)
2. **Add metric definition**:
   ```c
   void collect_custom_metric() {
       // Your custom SQL query
       PGresult *res = PQexec(conn, "SELECT custom_value FROM custom_table");
       // Process result and emit metric
       printf("# HELP custom_metric Description
");
       printf("# TYPE custom_metric gauge
");
       printf("custom_metric %s
", PQgetvalue(res, 0, 0));
   }
   ```
3. **Rebuild collector**:
   ```bash
   docker-compose build --no-cache c-bypass-collector
   ```

### High Availability Setup

For production environments:

```yaml
# docker-compose.ha.yml
services:
  prometheus-1:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-admin-api'
      - '--web.enable-lifecycle'
    
  prometheus-2:
    image: prom/prometheus:latest
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-admin-api'
      - '--web.enable-lifecycle'
```

## 📊 Performance Optimization

### C Collector Optimization

1. **Connection Pooling**: Reuse database connections
2. **Batch Queries**: Collect multiple metrics in single query
3. **Async Processing**: Non-blocking metric collection
4. **Memory Management**: Proper cleanup of PostgreSQL results

### Prometheus Optimization

```yaml
# prometheus.yml optimizations
global:
  scrape_interval: 15s        # Balance between freshness and load
  evaluation_interval: 15s
  external_labels:
    monitor: 'pganalytics'

# Storage optimization
command:
  - '--storage.tsdb.retention.time=30d'
  - '--storage.tsdb.retention.size=50GB'
  - '--storage.tsdb.wal-compression'
```

### Grafana Optimization

1. **Query Optimization**: Use recording rules for expensive queries
2. **Dashboard Variables**: Parameterize dashboards for multiple databases
3. **Panel Refresh**: Set appropriate refresh intervals
4. **Data Source**: Configure proper timeout and query limits

---

**For more information, see the main [README.md](../README.md)**
