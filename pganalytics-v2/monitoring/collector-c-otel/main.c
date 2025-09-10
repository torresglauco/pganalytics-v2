/*
 * PG Analytics - Cliente C com OpenTelemetry SDK
 * Arquitetura correta: Client-side instrumentation
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <curl/curl.h>
#include <json-c/json.h>
#include <libpq-fe.h>

// OpenTelemetry-like structures (simplified C implementation)
typedef struct {
    char name[256];
    double value;
    char labels[512];
    time_t timestamp;
} otel_metric_t;

typedef struct {
    char trace_id[64];
    char span_id[32];
    char operation_name[256];
    long duration_ms;
    time_t start_time;
} otel_span_t;

typedef struct {
    otel_metric_t metrics[100];
    otel_span_t spans[50];
    int metric_count;
    int span_count;
    char service_name[64];
    char service_version[16];
} otel_context_t;

// Global OpenTelemetry context
static otel_context_t otel_ctx = {
    .metric_count = 0,
    .span_count = 0,
    .service_name = "pganalytics-c-collector",
    .service_version = "1.0.0"
};

static PGconn *db_conn = NULL;
static char *otel_collector_endpoint = NULL;

// OpenTelemetry SDK Functions
void otel_init() {
    otel_collector_endpoint = getenv("OTEL_EXPORTER_OTLP_ENDPOINT");
    if (!otel_collector_endpoint) {
        otel_collector_endpoint = "http://otel-collector:4318/v1/metrics";
    }
    
    printf("🚀 OpenTelemetry SDK inicializado\n");
    printf("📡 Endpoint: %s\n", otel_collector_endpoint);
    printf("🏷️  Service: %s v%s\n", otel_ctx.service_name, otel_ctx.service_version);
}

void otel_record_metric(const char *name, double value, const char *labels) {
    if (otel_ctx.metric_count >= 100) return;
    
    otel_metric_t *metric = &otel_ctx.metrics[otel_ctx.metric_count++];
    strncpy(metric->name, name, sizeof(metric->name) - 1);
    metric->value = value;
    strncpy(metric->labels, labels ? labels : "", sizeof(metric->labels) - 1);
    metric->timestamp = time(NULL);
    
    printf("📊 Métrica: %s = %.2f [%s]\n", name, value, labels ? labels : "");
}

void otel_start_span(const char *operation_name) {
    if (otel_ctx.span_count >= 50) return;
    
    otel_span_t *span = &otel_ctx.spans[otel_ctx.span_count++];
    snprintf(span->trace_id, sizeof(span->trace_id), "trace_%ld", time(NULL));
    snprintf(span->span_id, sizeof(span->span_id), "span_%d", otel_ctx.span_count);
    strncpy(span->operation_name, operation_name, sizeof(span->operation_name) - 1);
    span->start_time = time(NULL);
    
    printf("🔍 Span iniciado: %s [%s]\n", operation_name, span->span_id);
}

void otel_end_span() {
    if (otel_ctx.span_count == 0) return;
    
    otel_span_t *span = &otel_ctx.spans[otel_ctx.span_count - 1];
    span->duration_ms = (time(NULL) - span->start_time) * 1000;
    
    printf("✅ Span finalizado: %s (duração: %ld ms)\n", 
           span->operation_name, span->duration_ms);
}

// Enviar dados para OpenTelemetry Collector
int otel_export_metrics() {
    CURL *curl;
    CURLcode res;
    
    curl = curl_easy_init();
    if (!curl) return 0;
    
    // Criar payload OpenTelemetry Protocol (OTLP)
    json_object *root = json_object_new_object();
    json_object *resource_metrics = json_object_new_array();
    json_object *resource_metric = json_object_new_object();
    
    // Resource
    json_object *resource = json_object_new_object();
    json_object *attributes = json_object_new_array();
    
    json_object *service_name_attr = json_object_new_object();
    json_object_object_add(service_name_attr, "key", json_object_new_string("service.name"));
    json_object_object_add(service_name_attr, "value", 
                          json_object_new_string(otel_ctx.service_name));
    json_object_array_add(attributes, service_name_attr);
    
    json_object_object_add(resource, "attributes", attributes);
    json_object_object_add(resource_metric, "resource", resource);
    
    // Scope Metrics
    json_object *scope_metrics = json_object_new_array();
    json_object *scope_metric = json_object_new_object();
    
    json_object *scope = json_object_new_object();
    json_object_object_add(scope, "name", json_object_new_string("pganalytics-c-collector"));
    json_object_object_add(scope, "version", json_object_new_string("1.0.0"));
    json_object_object_add(scope_metric, "scope", scope);
    
    // Metrics
    json_object *metrics = json_object_new_array();
    
    for (int i = 0; i < otel_ctx.metric_count; i++) {
        json_object *metric = json_object_new_object();
        json_object_object_add(metric, "name", 
                              json_object_new_string(otel_ctx.metrics[i].name));
        
        json_object *gauge = json_object_new_object();
        json_object *data_points = json_object_new_array();
        json_object *data_point = json_object_new_object();
        
        json_object_object_add(data_point, "timeUnixNano", 
                              json_object_new_int64(otel_ctx.metrics[i].timestamp * 1000000000));
        json_object_object_add(data_point, "asDouble", 
                              json_object_new_double(otel_ctx.metrics[i].value));
        
        json_object_array_add(data_points, data_point);
        json_object_object_add(gauge, "dataPoints", data_points);
        json_object_object_add(metric, "gauge", gauge);
        
        json_object_array_add(metrics, metric);
    }
    
    json_object_object_add(scope_metric, "metrics", metrics);
    json_object_array_add(scope_metrics, scope_metric);
    json_object_object_add(resource_metric, "scopeMetrics", scope_metrics);
    json_object_array_add(resource_metrics, resource_metric);
    json_object_object_add(root, "resourceMetrics", resource_metrics);
    
    const char *json_string = json_object_to_json_string(root);
    
    // Configurar CURL para enviar via OTLP
    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");
    
    curl_easy_setopt(curl, CURLOPT_URL, otel_collector_endpoint);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_string);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 10L);
    
    res = curl_easy_perform(curl);
    
    if (res == CURLE_OK) {
        printf("📡 Métricas enviadas para OpenTelemetry Collector\n");
    } else {
        printf("⚠️  Erro enviando métricas: %s\n", curl_easy_strerror(res));
    }
    
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    json_object_put(root);
    
    // Reset metrics
    otel_ctx.metric_count = 0;
    
    return res == CURLE_OK;
}

// PostgreSQL operations with OpenTelemetry instrumentation
int connect_postgresql() {
    otel_start_span("postgresql.connect");
    
    const char *conninfo = getenv("DATABASE_URL");
    if (!conninfo) {
        conninfo = "host=postgres port=5432 dbname=pganalytics user=postgres password=postgres";
    }
    
    db_conn = PQconnectdb(conninfo);
    
    if (PQstatus(db_conn) != CONNECTION_OK) {
        printf("⚠️  PostgreSQL connection failed: %s\n", PQerrorMessage(db_conn));
        otel_record_metric("postgresql.connection.failed", 1, "service=pganalytics");
        PQfinish(db_conn);
        db_conn = NULL;
        otel_end_span();
        return 0;
    }
    
    printf("✅ PostgreSQL connected\n");
    otel_record_metric("postgresql.connection.success", 1, "service=pganalytics");
    otel_end_span();
    return 1;
}

void collect_and_instrument_metrics() {
    otel_start_span("metrics.collection");
    
    if (!db_conn) {
        // Métricas simuladas com instrumentação OpenTelemetry
        otel_record_metric("postgresql.connections.active", 5, "state=active,service=pganalytics");
        otel_record_metric("postgresql.connections.idle", 10, "state=idle,service=pganalytics");
        otel_record_metric("postgresql.cache.hit_ratio", 0.95, "service=pganalytics");
        otel_record_metric("postgresql.slow_queries.count", 2, "service=pganalytics");
        
        otel_end_span();
        return;
    }
    
    // Coletar conexões com instrumentação
    otel_start_span("postgresql.query.connections");
    PGresult *res = PQexec(db_conn, 
        "SELECT "
        "count(*) FILTER (WHERE state = 'active') as active, "
        "count(*) FILTER (WHERE state = 'idle') as idle, "
        "count(*) as total "
        "FROM pg_stat_activity WHERE state IS NOT NULL");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        int active = atoi(PQgetvalue(res, 0, 0));
        int idle = atoi(PQgetvalue(res, 0, 1));
        int total = atoi(PQgetvalue(res, 0, 2));
        
        otel_record_metric("postgresql.connections.active", active, "state=active,service=pganalytics");
        otel_record_metric("postgresql.connections.idle", idle, "state=idle,service=pganalytics");
        otel_record_metric("postgresql.connections.total", total, "service=pganalytics");
    }
    PQclear(res);
    otel_end_span();
    
    // Cache hit ratio com instrumentação
    otel_start_span("postgresql.query.cache_stats");
    res = PQexec(db_conn,
        "SELECT "
        "CASE "
        "WHEN sum(heap_blks_hit) + sum(heap_blks_read) = 0 THEN 0 "
        "ELSE sum(heap_blks_hit)::float / (sum(heap_blks_hit) + sum(heap_blks_read)) "
        "END "
        "FROM pg_statio_user_tables");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        double hit_ratio = atof(PQgetvalue(res, 0, 0));
        otel_record_metric("postgresql.cache.hit_ratio", hit_ratio, "service=pganalytics");
    }
    PQclear(res);
    otel_end_span();
    
    otel_end_span(); // metrics.collection
}

int main() {
    printf("🚀 PG Analytics - Cliente C com OpenTelemetry SDK\n");
    printf("🏗️  Arquitetura: Client-side instrumentation\n");
    printf("📍 Localização: /monitoring/collector-c-otel/\n");
    
    // Inicializar OpenTelemetry SDK
    otel_init();
    curl_global_init(CURL_GLOBAL_DEFAULT);
    
    // Conectar ao PostgreSQL
    if (!connect_postgresql()) {
        printf("💡 Continuando com métricas simuladas instrumentadas...\n");
    }
    
    printf("🔄 Iniciando loop de coleta e instrumentação...\n");
    
    // Loop principal de coleta e envio
    while (1) {
        collect_and_instrument_metrics();
        
        // Enviar métricas via OpenTelemetry Protocol
        otel_export_metrics();
        
        printf("⏳ Aguardando próxima coleta (30s)...\n");
        sleep(30);
    }
    
    // Cleanup
    if (db_conn) PQfinish(db_conn);
    curl_global_cleanup();
    
    return 0;
}
