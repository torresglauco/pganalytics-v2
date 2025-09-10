#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libpq-fe.h>
#include <microhttpd.h>
#include <time.h>
#include <signal.h>
#include <errno.h>
#include <sys/select.h>

// Performance optimizations
#define METRIC_BUFFER_INITIAL_SIZE 8192
#define MAX_CONNECTIONS 100
#define COLLECTION_INTERVAL_SECONDS 15
#define CONNECTION_POOL_SIZE 5

// Connection pool structure
typedef struct {
    PGconn *connections[CONNECTION_POOL_SIZE];
    int available[CONNECTION_POOL_SIZE];
    int pool_size;
    char *conninfo;
} ConnectionPool;

// Metrics cache structure
typedef struct {
    PostgreSQLMetrics metrics;
    time_t last_update;
    int cache_valid;
} MetricsCache;

// Global state
static ConnectionPool *pool = NULL;
static MetricsCache cache = {0};
static volatile int running = 1;

// Connection pool management
ConnectionPool* create_connection_pool(const char* conninfo) {
    ConnectionPool *p = malloc(sizeof(ConnectionPool));
    if (!p) return NULL;
    
    p->conninfo = strdup(conninfo);
    p->pool_size = CONNECTION_POOL_SIZE;
    
    // Initialize connections
    for (int i = 0; i < CONNECTION_POOL_SIZE; i++) {
        p->connections[i] = PQconnectdb(conninfo);
        if (PQstatus(p->connections[i]) == CONNECTION_OK) {
            p->available[i] = 1;
        } else {
            p->available[i] = 0;
            fprintf(stderr, "Connection %d failed: %s", i, PQerrorMessage(p->connections[i]));
        }
    }
    
    return p;
}

PGconn* get_connection(ConnectionPool *p) {
    for (int i = 0; i < p->pool_size; i++) {
        if (p->available[i]) {
            p->available[i] = 0;
            return p->connections[i];
        }
    }
    return NULL; // No available connections
}

void return_connection(ConnectionPool *p, PGconn *conn) {
    for (int i = 0; i < p->pool_size; i++) {
        if (p->connections[i] == conn) {
            p->available[i] = 1;
            break;
        }
    }
}

void destroy_connection_pool(ConnectionPool *p) {
    if (!p) return;
    
    for (int i = 0; i < p->pool_size; i++) {
        if (p->connections[i]) {
            PQfinish(p->connections[i]);
        }
    }
    free(p->conninfo);
    free(p);
}

// Optimized metrics collection
int collect_metrics_optimized(PostgreSQLMetrics *metrics) {
    PGconn *conn = get_connection(pool);
    if (!conn) {
        return -1; // No available connections
    }
    
    PGresult *res;
    
    // Single query to get multiple metrics efficiently
    const char *query = 
        "SELECT "
        "  (SELECT count(*) FROM pg_stat_activity) as total_connections,"
        "  (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') as active_connections,"
        "  (SELECT count(*) FROM pg_stat_activity WHERE state = 'idle') as idle_connections,"
        "  (SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction') as idle_in_transaction,"
        "  (SELECT sum(xact_commit) FROM pg_stat_database) as commits_total,"
        "  (SELECT sum(xact_rollback) FROM pg_stat_database) as rollbacks_total,"
        "  (SELECT pg_database_size(current_database())) as database_size,"
        "  (SELECT count(*) FROM pg_locks WHERE granted = false) as waiting_locks,"
        "  (SELECT count(*) FROM pg_locks WHERE granted = true) as active_locks,"
        "  (SELECT CASE WHEN pg_is_in_recovery() THEN 0 ELSE 1 END) as is_primary,"
        "  (SELECT sum(blks_hit)*100.0/NULLIF(sum(blks_hit + blks_read), 0) FROM pg_stat_database) as cache_hit_ratio;";
    
    res = PQexec(conn, query);
    
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        fprintf(stderr, "Query failed: %s", PQerrorMessage(conn));
        PQclear(res);
        return_connection(pool, conn);
        return -1;
    }
    
    if (PQntuples(res) > 0) {
        metrics->total_connections = atoi(PQgetvalue(res, 0, 0));
        metrics->active_connections = atoi(PQgetvalue(res, 0, 1));
        metrics->idle_connections = atoi(PQgetvalue(res, 0, 2));
        metrics->idle_in_transaction = atoi(PQgetvalue(res, 0, 3));
        metrics->commits_total = atoll(PQgetvalue(res, 0, 4));
        metrics->rollbacks_total = atoll(PQgetvalue(res, 0, 5));
        metrics->database_size = atoll(PQgetvalue(res, 0, 6));
        metrics->waiting_locks = atoi(PQgetvalue(res, 0, 7));
        metrics->active_locks = atoi(PQgetvalue(res, 0, 8));
        metrics->is_primary = atoi(PQgetvalue(res, 0, 9));
        metrics->cache_hit_ratio = atof(PQgetvalue(res, 0, 10));
        metrics->database_connected = 1;
        metrics->last_update = time(NULL);
    }
    
    PQclear(res);
    return_connection(pool, conn);
    return 0;
}

// Cached metrics retrieval
PostgreSQLMetrics* get_cached_metrics() {
    time_t now = time(NULL);
    
    // Cache for 10 seconds to reduce database load
    if (cache.cache_valid && (now - cache.last_update) < 10) {
        return &cache.metrics;
    }
    
    // Update cache
    if (collect_metrics_optimized(&cache.metrics) == 0) {
        cache.last_update = now;
        cache.cache_valid = 1;
    }
    
    return &cache.metrics;
}

// Optimized HTTP response handler
static int handle_metrics_request(void *cls, struct MHD_Connection *connection,
                                const char *url, const char *method,
                                const char *version, const char *upload_data,
                                size_t *upload_data_size, void **con_cls) {
    
    if (strcmp(method, "GET") != 0) {
        return MHD_NO;
    }
    
    const char *tenant = getenv("TENANT_NAME");
    if (!tenant) tenant = "default";
    
    PostgreSQLMetrics *metrics = get_cached_metrics();
    if (!metrics) {
        const char *error_response = "Internal server error";
        struct MHD_Response *response = MHD_create_response_from_buffer(
            strlen(error_response), (void*)error_response, MHD_RESPMEM_PERSISTENT);
        int ret = MHD_queue_response(connection, MHD_HTTP_INTERNAL_SERVER_ERROR, response);
        MHD_destroy_response(response);
        return ret;
    }
    
    // Pre-allocate buffer based on estimated size
    size_t buffer_size = 4096 + strlen(tenant) * 20;
    char *response_buffer = malloc(buffer_size);
    if (!response_buffer) {
        return MHD_NO;
    }
    
    // Use optimized metrics formatting
    if (export_metrics_prometheus_format(metrics, tenant, response_buffer, buffer_size) != 0) {
        free(response_buffer);
        return MHD_NO;
    }
    
    struct MHD_Response *response = MHD_create_response_from_buffer(
        strlen(response_buffer), response_buffer, MHD_RESPMEM_MUST_FREE);
    
    MHD_add_response_header(response, "Content-Type", "text/plain; charset=utf-8");
    MHD_add_response_header(response, "Cache-Control", "no-cache");
    
    int ret = MHD_queue_response(connection, MHD_HTTP_OK, response);
    MHD_destroy_response(response);
    
    return ret;
}

// Signal handler for graceful shutdown
void signal_handler(int sig) {
    if (sig == SIGINT || sig == SIGTERM) {
        running = 0;
    }
}

int main() {
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // Initialize connection pool
    const char *conninfo = getenv("DATABASE_URL");
    if (!conninfo) {
        conninfo = "host=postgres port=5432 dbname=pganalytics user=admin password=admin123";
    }
    
    pool = create_connection_pool(conninfo);
    if (!pool) {
        fprintf(stderr, "Failed to create connection pool\n");
        return 1;
    }
    
    // Start HTTP server
    struct MHD_Daemon *daemon = MHD_start_daemon(
        MHD_USE_THREAD_PER_CONNECTION,
        8080, NULL, NULL,
        &handle_metrics_request, NULL,
        MHD_OPTION_END);
    
    if (!daemon) {
        fprintf(stderr, "Failed to start HTTP server\n");
        destroy_connection_pool(pool);
        return 1;
    }
    
    printf("Optimized collector started on port 8080\n");
    
    // Main loop
    while (running) {
        sleep(1);
    }
    
    printf("Shutting down gracefully...\n");
    MHD_stop_daemon(daemon);
    destroy_connection_pool(pool);
    
    return 0;
}
