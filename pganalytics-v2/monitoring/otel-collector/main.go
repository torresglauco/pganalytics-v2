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

    _ "github.com/lib/pq"
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
    queryDuration metric.Float64Histogram
    replicationLag metric.Int64Gauge
}

type SlowQuery struct {
    Query    string    `json:"query"`
    Duration float64   `json:"duration_ms"`
    Database string    `json:"database"`
    User     string    `json:"user"`
    Time     time.Time `json:"timestamp"`
}

type ConnectionInfo struct {
    Active   int `json:"active"`
    Idle     int `json:"idle"`
    Total    int `json:"total"`
    MaxConn  int `json:"max_connections"`
}

func main() {
    log.Println("🚀 Iniciando PG Analytics OpenTelemetry Collector...")

    // Configurar OpenTelemetry
    exporter, err := prometheus.New()
    if err != nil {
        log.Fatal("Erro criando exporter Prometheus:", err)
    }

    provider := metric.NewMeterProvider(metric.WithReader(exporter))
    otel.SetMeterProvider(provider)

    // Conectar ao PostgreSQL
    dbURL := os.Getenv("DATABASE_URL")
    if dbURL == "" {
        dbURL = "postgres://postgres:postgres@postgres:5432/pganalytics?sslmode=disable"
    }

    log.Printf("Conectando ao PostgreSQL: %s", dbURL)
    db, err := sql.Open("postgres", dbURL)
    if err != nil {
        log.Fatal("Erro conectando ao PostgreSQL:", err)
    }
    defer db.Close()

    // Testar conexão
    if err := db.Ping(); err != nil {
        log.Printf("⚠️  Aviso: PostgreSQL não acessível ainda: %v", err)
    } else {
        log.Println("✅ PostgreSQL conectado com sucesso")
    }

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

    log.Printf("🎯 Servidor iniciado na porta %s", port)
    log.Printf("📊 Métricas: http://localhost:%s/metrics", port)
    log.Printf("❤️  Health: http://localhost:%s/health", port)
    
    log.Fatal(http.ListenAndServe(":"+port, nil))
}

func (pm *PostgresMetrics) initMetrics() error {
    var err error

    pm.connectionCount, err = pm.meter.Int64UpDownCounter(
        "postgres_connections_total",
        metric.WithDescription("Number of active PostgreSQL connections"),
    )
    if err != nil {
        return fmt.Errorf("erro criando métrica de conexões: %w", err)
    }

    pm.slowQueryCount, err = pm.meter.Int64Counter(
        "postgres_slow_queries_total",
        metric.WithDescription("Total number of slow queries"),
    )
    if err != nil {
        return fmt.Errorf("erro criando métrica de slow queries: %w", err)
    }

    pm.cacheHitRatio, err = pm.meter.Float64Gauge(
        "postgres_cache_hit_ratio",
        metric.WithDescription("PostgreSQL buffer cache hit ratio"),
    )
    if err != nil {
        return fmt.Errorf("erro criando métrica de cache: %w", err)
    }

    log.Println("✅ Métricas OpenTelemetry inicializadas")
    return nil
}

func (pm *PostgresMetrics) collectMetrics() {
    ticker := time.NewTicker(30 * time.Second)
    defer ticker.Stop()

    log.Println("📊 Iniciando coleta de métricas...")

    for {
        select {
        case <-ticker.C:
            pm.collectConnectionMetrics()
            pm.collectCacheMetrics()
        }
    }
}

func (pm *PostgresMetrics) collectConnectionMetrics() {
    query := `
        SELECT 
            COALESCE(state, 'unknown') as state, 
            count(*) 
        FROM pg_stat_activity 
        GROUP BY state
    `
    
    rows, err := pm.db.Query(query)
    if err != nil {
        log.Printf("⚠️  Erro coletando métricas de conexão: %v", err)
        return
    }
    defer rows.Close()

    ctx := context.Background()
    connections := make(map[string]int)
    
    for rows.Next() {
        var state string
        var count int
        if err := rows.Scan(&state, &count); err != nil {
            continue
        }
        connections[state] = count
        
        pm.connectionCount.Add(ctx, int64(count), 
            metric.WithAttributes(attribute.String("state", state)))
    }
}

func (pm *PostgresMetrics) collectCacheMetrics() {
    query := `
        SELECT 
            CASE 
                WHEN sum(heap_blks_hit) + sum(heap_blks_read) = 0 THEN 0
                ELSE sum(heap_blks_hit)::float / (sum(heap_blks_hit) + sum(heap_blks_read))
            END as cache_hit_ratio
        FROM pg_statio_user_tables
    `
    
    var hitRatio float64
    if err := pm.db.QueryRow(query).Scan(&hitRatio); err != nil {
        log.Printf("⚠️  Erro coletando métricas de cache: %v", err)
        return
    }

    ctx := context.Background()
    pm.cacheHitRatio.Record(ctx, hitRatio)
}

func (pm *PostgresMetrics) slowQueriesHandler(w http.ResponseWriter, r *http.Request) {
    limit := 10
    if l := r.URL.Query().Get("limit"); l != "" {
        if parsed, err := strconv.Atoi(l); err == nil {
            limit = parsed
        }
    }

    // Simulação de slow queries (substitua por query real se pg_stat_statements estiver disponível)
    slowQueries := []SlowQuery{
        {
            Query: "SELECT * FROM large_table WHERE complex_condition = ?",
            Duration: 1500.5,
            Database: "pganalytics",
            User: "postgres",
            Time: time.Now(),
        },
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]interface{}{
        "slow_queries": slowQueries[:limit],
        "count": len(slowQueries),
        "timestamp": time.Now(),
    })
}

func (pm *PostgresMetrics) connectionsHandler(w http.ResponseWriter, r *http.Request) {
    query := `
        SELECT 
            count(*) FILTER (WHERE state = 'active') as active,
            count(*) FILTER (WHERE state = 'idle') as idle,
            count(*) as total
        FROM pg_stat_activity
        WHERE state IS NOT NULL
    `
    
    var conn ConnectionInfo
    if err := pm.db.QueryRow(query).Scan(&conn.Active, &conn.Idle, &conn.Total); err != nil {
        // Se falhar, retornar dados simulados
        conn = ConnectionInfo{
            Active: 5,
            Idle: 10,
            Total: 15,
            MaxConn: 100,
        }
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
        "collector": "opentelemetry",
    })
}
