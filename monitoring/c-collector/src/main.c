#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libpq-fe.h>
#include <microhttpd.h>

typedef struct {
    long long active_connections;
    long long slow_queries;
    int is_healthy;
} metrics_t;

static metrics_t global_metrics = {0};

static int answer_to_connection(void *cls, struct MHD_Connection *connection,
                              const char *url, const char *method,
                              const char *version, const char *upload_data,
                              size_t *upload_data_size, void **con_cls) {
    
    if (strcmp(url, "/metrics") != 0) {
        return MHD_NO;
    }

    char response[2048];
    snprintf(response, sizeof(response),
        "# HELP pg_active_connections Number of active connections\n"
        "# TYPE pg_active_connections gauge\n"
        "pg_active_connections %lld\n"
        "# HELP pg_slow_queries_total Number of slow queries\n"
        "# TYPE pg_slow_queries_total counter\n"
        "pg_slow_queries_total %lld\n"
        "# HELP pg_up Database is up\n"
        "# TYPE pg_up gauge\n"
        "pg_up %d\n",
        global_metrics.active_connections,
        global_metrics.slow_queries,
        global_metrics.is_healthy);

    struct MHD_Response *mhd_response = MHD_create_response_from_buffer(
        strlen(response), (void*)response, MHD_RESPMEM_MUST_COPY);
    
    MHD_add_response_header(mhd_response, "Content-Type", "text/plain");
    int ret = MHD_queue_response(connection, MHD_HTTP_OK, mhd_response);
    MHD_destroy_response(mhd_response);

    return ret;
}

void collect_metrics(PGconn *conn) {
    if (!conn) return;
    
    PGresult *res;
    
    // Active connections
    res = PQexec(conn, "SELECT count(*) FROM pg_stat_activity WHERE state = 'active'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK) {
        global_metrics.active_connections = atoll(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Slow queries
    res = PQexec(conn, "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '1 second'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK) {
        global_metrics.slow_queries = atoll(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    global_metrics.is_healthy = 1;
}

int main() {
    printf("🚀 PG Metrics Collector starting...\n");
    
    char *conninfo = getenv("DATABASE_URL");
    if (!conninfo) {
        conninfo = "host=postgres port=5432 dbname=pganalytics user=postgres password=postgres";
    }
    
    PGconn *conn = PQconnectdb(conninfo);
    if (PQstatus(conn) != CONNECTION_OK) {
        fprintf(stderr, "Connection failed: %s", PQerrorMessage(conn));
        PQfinish(conn);
        return 1;
    }
    
    printf("✅ Connected to PostgreSQL\n");
    
    struct MHD_Daemon *daemon = MHD_start_daemon(
        MHD_USE_SELECT_INTERNALLY, 9188, NULL, NULL,
        &answer_to_connection, NULL, MHD_OPTION_END);

    if (daemon == NULL) {
        PQfinish(conn);
        return 1;
    }

    printf("🌐 HTTP server started on port 9188\n");
    printf("📊 Metrics: http://localhost:9188/metrics\n");

    while (1) {
        collect_metrics(conn);
        sleep(15);
    }

    MHD_stop_daemon(daemon);
    PQfinish(conn);
    return 0;
}
