package main

import (
    "context"
    "database/sql"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "strconv"
    "time"

    "github.com/lib/pq"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/attribute"
    "go.opentelemetry.io/otel/exporters/prometheus"
    "go.opentelemetry.io/otel/metric"
    "go.opentelemetry.io/otel/sdk/metric"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

type PostgresMetrics struct {
    db *sql.DB
    meter metric.Meter
    
    // Métricas
    connectionCount metric.Int64UpDownCounter
    slowQueryCount metric.Int64Counter
    deadlockCount metric.Int64Counter
    cacheHitRatio metric.Float64Gauge
    transactionDuration metric.Float64Histogram
    queryDuration metric.Float64Histogram
    replicationLag metric.Int64Gauge
    vacuumProgress metric.Float64Gauge
    bufferCacheHits metric.Int64Counter
    diskReads metric.Int64Counter
}

type SlowQuery struct {
    Query    string    \`json:"query"\`
    Duration float64   \`json:"duration_ms"\`
    Database string    \`json:"database"\`
    User     string    \`json:"user"\`
    Time     time.Time \`json:"timestamp"\`
}

type ConnectionInfo struct {
    Active   int \`json:"active"\`
    Idle     int \`json:"idle"\`
    Total    int \`json:"total"\`
    MaxConn  int \`json:"max_connections"\`
}

func main() {
    // Configurar OpenTelemetry
    exporter, err := prometheus.New()
    if err != nil {
        log.Fatal(err)
    }

    provider := metric.NewMeterProvider(metric.WithReader(exporter))
    otel.SetMeterProvider(provider)

    // Conectar ao PostgreSQL
    dbURL := os.Getenv("DATABASE_URL")
    if dbURL == "" {
        dbURL = "postgres://postgres:postgres@localhost:5432/pganalytics?sslmode=disable"
    }

    db, err := sql.Open("postgres", dbURL)
    if err != nil {
        log.Fatal("Erro conectando ao PostgreSQL:", err)
    }
    defer db.Close()

    // Inicializar métricas
    pm := &PostgresMetrics{
        db: db,
        meter: otel.Meter("postgres-metrics"),
    }

    if err := pm.initMetrics(); err != nil {
        log.Fatal("Erro inicializando métricas:", err)
    }

    // Configurar coleta periódica
    go pm.collectMetrics()

    // Servidor HTTP
    http.Handle("/metrics", promhttp.Handler())
    http.HandleFunc("/health", healthHandler)
    http.HandleFunc("/slow-queries", pm.slowQueriesHandler)
    http.HandleFunc("/connections", pm.connectionsHandler)

    port := os.Getenv("PORT")
    if port == "" {
        port = "9188"
    }

    log.Printf("🚀 Coletor OpenTelemetry iniciado na porta %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}

func (pm *PostgresMetrics) initMetrics() error {
    var err error

    pm.connectionCount, err = pm.meter.Int64UpDownCounter(
        "postgres_connections_total",
        metric.WithDescription("Number of active PostgreSQL connections"),
    )
    if err != nil {
        return err
    }

    pm.slowQueryCount, err = pm.meter.Int64Counter(
        "postgres_slow_queries_total",
        metric.WithDescription("Total number of slow queries"),
    )
    if err != nil {
        return err
    }

    pm.deadlockCount, err = pm.meter.Int64Counter(
        "postgres_deadlocks_total",
        metric.WithDescription("Total number of deadlocks"),
    )
    if err != nil {
        return err
    }

    pm.cacheHitRatio, err = pm.meter.Float64Gauge(
        "postgres_cache_hit_ratio",
        metric.WithDescription("PostgreSQL buffer cache hit ratio"),
    )
    if err != nil {
        return err
    }

    pm.queryDuration, err = pm.meter.Float64Histogram(
        "postgres_query_duration_seconds",
        metric.WithDescription("Query execution time in seconds"),
    )
    if err != nil {
        return err
    }

    pm.replicationLag, err = pm.meter.Int64Gauge(
        "postgres_replication_lag_bytes",
        metric.WithDescription("Replication lag in bytes"),
    )
    if err != nil {
        return err
    }

    return nil
}

func (pm *PostgresMetrics) collectMetrics() {
    ticker := time.NewTicker(30 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ticker.C:
            pm.collectConnectionMetrics()
            pm.collectCacheMetrics()
            pm.collectSlowQueryMetrics()
            pm.collectDeadlockMetrics()
            pm.collectReplicationMetrics()
        }
    }
}

func (pm *PostgresMetrics) collectConnectionMetrics() {
    query := \`
        SELECT state, count(*) 
        FROM pg_stat_activity 
        WHERE state IS NOT NULL 
        GROUP BY state
    \`
    
    rows, err := pm.db.Query(query)
    if err != nil {
        log.Printf("Erro coletando métricas de conexão: %v", err)
        return
    }
    defer rows.Close()

    connections := make(map[string]int)
    for rows.Next() {
        var state string
        var count int
        if err := rows.Scan(&state, &count); err != nil {
            continue
        }
        connections[state] = count
    }

    ctx := context.Background()
    for state, count := range connections {
        pm.connectionCount.Add(ctx, int64(count), 
            metric.WithAttributes(attribute.String("state", state)))
    }
}

func (pm *PostgresMetrics) collectCacheMetrics() {
    query := \`
        SELECT 
            sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as cache_hit_ratio
        FROM pg_statio_user_tables
        WHERE heap_blks_hit + heap_blks_read > 0
    \`
    
    var hitRatio sql.NullFloat64
    if err := pm.db.QueryRow(query).Scan(&hitRatio); err != nil {
        log.Printf("Erro coletando métricas de cache: %v", err)
        return
    }

    if hitRatio.Valid {
        ctx := context.Background()
        pm.cacheHitRatio.Record(ctx, hitRatio.Float64)
    }
}

func (pm *PostgresMetrics) collectSlowQueryMetrics() {
    // Habilitar log de slow queries se não estiver habilitado
    enableSlowQueryLogging := \`
        SELECT 
            count(*) as slow_queries
        FROM pg_stat_statements 
        WHERE mean_exec_time > 1000
    \`
    
    var slowCount int
    if err := pm.db.QueryRow(enableSlowQueryLogging).Scan(&slowCount); err != nil {
        // pg_stat_statements pode não estar habilitado
        return
    }

    ctx := context.Background()
    pm.slowQueryCount.Add(ctx, int64(slowCount))
}

func (pm *PostgresMetrics) collectDeadlockMetrics() {
    query := \`
        SELECT sum(deadlocks) as total_deadlocks
        FROM pg_stat_database
    \`
    
    var deadlocks sql.NullInt64
    if err := pm.db.QueryRow(query).Scan(&deadlocks); err != nil {
        log.Printf("Erro coletando métricas de deadlock: %v", err)
        return
    }

    if deadlocks.Valid {
        ctx := context.Background()
        pm.deadlockCount.Add(ctx, deadlocks.Int64)
    }
}

func (pm *PostgresMetrics) collectReplicationMetrics() {
    // Verificar se é um master/primary
    query := \`
        SELECT 
            CASE WHEN pg_is_in_recovery() THEN 
                pg_last_wal_receive_lsn() - pg_last_wal_replay_lsn()
            ELSE 
                0
            END as lag_bytes
    \`
    
    var lagBytes sql.NullInt64
    if err := pm.db.QueryRow(query).Scan(&lagBytes); err != nil {
        return
    }

    if lagBytes.Valid {
        ctx := context.Background()
        pm.replicationLag.Record(ctx, lagBytes.Int64)
    }
}

func (pm *PostgresMetrics) slowQueriesHandler(w http.ResponseWriter, r *http.Request) {
    limitStr := r.URL.Query().Get("limit")
    limit := 10
    if limitStr != "" {
        if l, err := strconv.Atoi(limitStr); err == nil {
            limit = l
        }
    }

    query := \`
        SELECT 
            query,
            mean_exec_time,
            calls,
            total_exec_time
        FROM pg_stat_statements 
        ORDER BY mean_exec_time DESC 
        LIMIT $1
    \`
    
    rows, err := pm.db.Query(query, limit)
    if err != nil {
        http.Error(w, "Erro consultando slow queries", http.StatusInternalServerError)
        return
    }
    defer rows.Close()

    var slowQueries []SlowQuery
    for rows.Next() {
        var sq SlowQuery
        var calls int
        var totalTime float64
        
        if err := rows.Scan(&sq.Query, &sq.Duration, &calls, &totalTime); err != nil {
            continue
        }
        
        sq.Time = time.Now()
        sq.Database = "pganalytics"
        slowQueries = append(slowQueries, sq)
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "slow_queries": slowQueries,
        "count": len(slowQueries),
        "timestamp": time.Now(),
    })
}

func (pm *PostgresMetrics) connectionsHandler(w http.ResponseWriter, r *http.Request) {
    query := \`
        SELECT 
            count(*) FILTER (WHERE state = 'active') as active,
            count(*) FILTER (WHERE state = 'idle') as idle,
            count(*) as total,
            (SELECT setting FROM pg_settings WHERE name = 'max_connections')::int as max_conn
        FROM pg_stat_activity
        WHERE state IS NOT NULL
    \`
    
    var conn ConnectionInfo
    if err := pm.db.QueryRow(query).Scan(&conn.Active, &conn.Idle, &conn.Total, &conn.MaxConn); err != nil {
        http.Error(w, "Erro consultando conexões", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "connections": conn,
        "timestamp": time.Now(),
    })
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status": "healthy",
        "timestamp": time.Now(),
        "version": "1.0.0",
    })
}
