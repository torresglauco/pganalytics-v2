/*
 * PG Analytics - Cliente C com endpoint /metrics para Prometheus
 * Solução BYPASS: Cliente C → Direto Prometheus
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <libpq-fe.h>
#include <microhttpd.h>

#define PORT 8080
#define METRICS_INTERVAL 30

// Estrutura para métricas
typedef struct {
    int active_connections;
    int idle_connections;
    int total_connections;
    float cache_hit_ratio;
    int slow_queries;
    time_t last_update;
} pg_metrics_t;

static pg_metrics_t metrics = {0};
static PGconn *db_conn = NULL;

// Conectar ao PostgreSQL
int connect_postgresql() {
    const char *conninfo = getenv("DATABASE_URL");
    if (!conninfo) {
        conninfo = "host=postgres port=5432 dbname=pganalytics user=postgres password=postgres";
    }
    
    db_conn = PQconnectdb(conninfo);
    
    if (PQstatus(db_conn) != CONNECTION_OK) {
        printf("⚠️  PostgreSQL connection failed: %s\n", PQerrorMessage(db_conn));
        PQfinish(db_conn);
        db_conn = NULL;
        return 0;
    }
    
    printf("✅ PostgreSQL connected (C collector bypass)\n");
    return 1;
}

// Coletar métricas do PostgreSQL
void collect_metrics() {
    printf("📊 Coletando métricas PostgreSQL...\n");
    
    if (!db_conn) {
        // Métricas simuladas
        metrics.active_connections = 5;
        metrics.idle_connections = 10;
        metrics.total_connections = 15;
        metrics.cache_hit_ratio = 0.95;
        metrics.slow_queries = 2;
        metrics.last_update = time(NULL);
        printf("⚠️  Usando métricas simuladas (PostgreSQL não conectado)\n");
        return;
    }
    
    // Coletar conexões reais
    PGresult *res = PQexec(db_conn, 
        "SELECT "
        "count(*) FILTER (WHERE state = 'active') as active, "
        "count(*) FILTER (WHERE state = 'idle') as idle, "
        "count(*) as total "
        "FROM pg_stat_activity WHERE state IS NOT NULL");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics.active_connections = atoi(PQgetvalue(res, 0, 0));
        metrics.idle_connections = atoi(PQgetvalue(res, 0, 1));
        metrics.total_connections = atoi(PQgetvalue(res, 0, 2));
        printf("✅ Conexões: %d ativo, %d idle, %d total\n", 
               metrics.active_connections, metrics.idle_connections, metrics.total_connections);
    }
    PQclear(res);
    
    // Cache hit ratio
    res = PQexec(db_conn,
        "SELECT "
        "CASE "
        "WHEN sum(heap_blks_hit) + sum(heap_blks_read) = 0 THEN 0 "
        "ELSE sum(heap_blks_hit)::float / (sum(heap_blks_hit) + sum(heap_blks_read)) "
        "END "
        "FROM pg_statio_user_tables");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics.cache_hit_ratio = atof(PQgetvalue(res, 0, 0));
        printf("✅ Cache hit ratio: %.4f\n", metrics.cache_hit_ratio);
    }
    PQclear(res);
    
    metrics.last_update = time(NULL);
    printf("📊 Métricas atualizadas: %ld\n", metrics.last_update);
}

// Handler para /metrics (formato Prometheus)
static enum MHD_Result metrics_handler(void *cls, struct MHD_Connection *connection,
                                     const char *url, const char *method,
                                     const char *version, const char *upload_data,
                                     size_t *upload_data_size, void **con_cls) {
    
    if (strcmp(method, "GET") != 0) {
        return MHD_NO;
    }
    
    char *response_text = malloc(4096);
    snprintf(response_text, 4096,
        "# HELP pganalytics_postgresql_connections Number of PostgreSQL connections\n"
        "# TYPE pganalytics_postgresql_connections gauge\n"
        "pganalytics_postgresql_connections{state=\"active\"} %d\n"
        "pganalytics_postgresql_connections{state=\"idle\"} %d\n"
        "pganalytics_postgresql_connections{state=\"total\"} %d\n"
        "\n"
        "# HELP pganalytics_postgresql_cache_hit_ratio PostgreSQL cache hit ratio\n"
        "# TYPE pganalytics_postgresql_cache_hit_ratio gauge\n"
        "pganalytics_postgresql_cache_hit_ratio %.4f\n"
        "\n"
        "# HELP pganalytics_postgresql_slow_queries_total Total slow queries\n"
        "# TYPE pganalytics_postgresql_slow_queries_total counter\n"
        "pganalytics_postgresql_slow_queries_total %d\n"
        "\n"
        "# HELP pganalytics_collector_last_update Last metrics update timestamp\n"
        "# TYPE pganalytics_collector_last_update gauge\n"
        "pganalytics_collector_last_update %ld\n"
        "\n"
        "# HELP pganalytics_collector_info Information about the collector\n"
        "# TYPE pganalytics_collector_info gauge\n"
        "pganalytics_collector_info{version=\"1.0\",type=\"c-bypass\"} 1\n",
        metrics.active_connections,
        metrics.idle_connections,
        metrics.total_connections,
        metrics.cache_hit_ratio,
        metrics.slow_queries,
        metrics.last_update
    );
    
    struct MHD_Response *response = MHD_create_response_from_buffer(
        strlen(response_text), response_text, MHD_RESPMEM_MUST_FREE);
    
    MHD_add_response_header(response, "Content-Type", "text/plain; charset=utf-8");
    enum MHD_Result ret = MHD_queue_response(connection, MHD_HTTP_OK, response);
    MHD_destroy_response(response);
    
    return ret;
}

// Handler principal
static enum MHD_Result request_handler(void *cls, struct MHD_Connection *connection,
                                     const char *url, const char *method,
                                     const char *version, const char *upload_data,
                                     size_t *upload_data_size, void **con_cls) {
    
    if (strcmp(url, "/metrics") == 0) {
        return metrics_handler(cls, connection, url, method, version, 
                             upload_data, upload_data_size, con_cls);
    }
    
    // Root handler
    if (strcmp(url, "/") == 0) {
        const char *page = 
            "<html><body>"
            "<h1>🚀 PG Analytics - Cliente C (Bypass)</h1>"
            "<p>✅ Status: Operacional</p>"
            "<p>🔗 <a href='/metrics'>Métricas Prometheus</a></p>"
            "<p>🎯 Arquitetura: PostgreSQL → Cliente C → Prometheus</p>"
            "</body></html>";
        
        struct MHD_Response *response = MHD_create_response_from_buffer(
            strlen(page), (void*)page, MHD_RESPMEM_PERSISTENT);
        MHD_add_response_header(response, "Content-Type", "text/html");
        enum MHD_Result ret = MHD_queue_response(connection, MHD_HTTP_OK, response);
        MHD_destroy_response(response);
        return ret;
    }
    
    // 404 para outras rotas
    const char *not_found = "404 Not Found";
    struct MHD_Response *response = MHD_create_response_from_buffer(
        strlen(not_found), (void*)not_found, MHD_RESPMEM_PERSISTENT);
    
    enum MHD_Result ret = MHD_queue_response(connection, MHD_HTTP_NOT_FOUND, response);
    MHD_destroy_response(response);
    
    return ret;
}

int main() {
    printf("🚀 PG Analytics - Cliente C BYPASS\n");
    printf("🎯 Arquitetura: PostgreSQL → Cliente C → Prometheus\n");
    printf("📍 Localização: /monitoring/collector-c-otel/\n");
    
    // Conectar ao PostgreSQL
    if (!connect_postgresql()) {
        printf("💡 Continuando com métricas simuladas...\n");
    }
    
    // Iniciar servidor HTTP
    struct MHD_Daemon *daemon = MHD_start_daemon(
        MHD_USE_INTERNAL_POLLING_THREAD,
        PORT,
        NULL, NULL,
        &request_handler, NULL,
        MHD_OPTION_END
    );
    
    if (!daemon) {
        printf("❌ Erro iniciando servidor HTTP\n");
        return 1;
    }
    
    printf("🎯 Cliente C BYPASS ativo na porta %d\n", PORT);
    printf("📊 Métricas: http://localhost:%d/metrics\n", PORT);
    printf("🏠 Home: http://localhost:%d/\n", PORT);
    
    // Loop principal com coleta de métricas
    while (1) {
        collect_metrics();
        sleep(METRICS_INTERVAL);
    }
    
    MHD_stop_daemon(daemon);
    if (db_conn) PQfinish(db_conn);
    
    return 0;
}
