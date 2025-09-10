#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <libpq-fe.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <signal.h>

typedef struct {
    char name[64];
    char host[256];
    int port;
    char dbname[64];
    char user[64];
    char password[64];
} tenant_config;

typedef struct {
    int total_connections;
    int active_connections;
    int idle_connections;
    int idle_in_transaction_connections;
    int max_connections;
    double cache_hit_ratio;
    long database_size;
    int locks_count;
    double avg_query_time;
    int slow_queries;
    long table_size;
    long index_size;
    int wal_files;
    double checkpoint_time;
    long replication_lag;
    int is_connected;
    int is_primary;
} tenant_metrics;

static volatile int running = 1;
static tenant_config tenants[10];
static tenant_metrics metrics[10];
static int tenant_count = 0;
static pthread_mutex_t metrics_mutex = PTHREAD_MUTEX_INITIALIZER;

void signal_handler(int sig) {
    printf("Received signal %d, shutting down...\n", sig);
    running = 0;
}

void init_tenants() {
    // Tenant padrão: PostgreSQL
    strcpy(tenants[0].name, "postgres");
    strcpy(tenants[0].host, getenv("DB_HOST") ? getenv("DB_HOST") : "postgres");
    tenants[0].port = getenv("DB_PORT") ? atoi(getenv("DB_PORT")) : 5432;
    strcpy(tenants[0].dbname, "postgres");
    strcpy(tenants[0].user, getenv("DB_USER") ? getenv("DB_USER") : "admin");
    strcpy(tenants[0].password, getenv("DB_PASSWORD") ? getenv("DB_PASSWORD") : "admin123");
    
    // Tenant principal: pganalytics
    strcpy(tenants[1].name, "pganalytics");
    strcpy(tenants[1].host, getenv("DB_HOST") ? getenv("DB_HOST") : "postgres");
    tenants[1].port = getenv("DB_PORT") ? atoi(getenv("DB_PORT")) : 5432;
    strcpy(tenants[1].dbname, getenv("DB_NAME") ? getenv("DB_NAME") : "pganalytics");
    strcpy(tenants[1].user, getenv("DB_USER") ? getenv("DB_USER") : "admin");
    strcpy(tenants[1].password, getenv("DB_PASSWORD") ? getenv("DB_PASSWORD") : "admin123");
    
    tenant_count = 2;
}

PGconn* connect_to_tenant(int tenant_idx) {
    char conn_string[512];
    snprintf(conn_string, sizeof(conn_string),
        "host=%s port=%d dbname=%s user=%s password=%s connect_timeout=10",
        tenants[tenant_idx].host,
        tenants[tenant_idx].port, 
        tenants[tenant_idx].dbname,
        tenants[tenant_idx].user,
        tenants[tenant_idx].password);
    
    return PQconnectdb(conn_string);
}

void collect_enhanced_metrics(PGconn *conn, int tenant_idx) {
    PGresult *res;
    
    // Reset metrics
    memset(&metrics[tenant_idx], 0, sizeof(tenant_metrics));
    
    // Check connection
    if (PQstatus(conn) == CONNECTION_OK) {
        metrics[tenant_idx].is_connected = 1;
    }
    
    // Total connections
    res = PQexec(conn, "SELECT count(*) FROM pg_stat_activity");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].total_connections = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Active connections
    res = PQexec(conn, "SELECT count(*) FROM pg_stat_activity WHERE state = 'active'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].active_connections = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Idle connections
    res = PQexec(conn, "SELECT count(*) FROM pg_stat_activity WHERE state = 'idle'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].idle_connections = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Idle in transaction connections
    res = PQexec(conn, "SELECT count(*) FROM pg_stat_activity WHERE state = 'idle in transaction'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].idle_in_transaction_connections = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Max connections
    res = PQexec(conn, "SHOW max_connections");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].max_connections = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Cache hit ratio
    res = PQexec(conn, "SELECT round(100.0 * sum(blks_hit) / NULLIF(sum(blks_hit) + sum(blks_read), 0), 2) FROM pg_stat_database WHERE datname = current_database()");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0 && strlen(PQgetvalue(res, 0, 0)) > 0) {
        metrics[tenant_idx].cache_hit_ratio = atof(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Database size
    res = PQexec(conn, "SELECT pg_database_size(current_database())");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].database_size = atol(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Locks count
    res = PQexec(conn, "SELECT count(*) FROM pg_locks");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].locks_count = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Table sizes (sum)
    res = PQexec(conn, "SELECT COALESCE(sum(pg_relation_size(oid)), 0) FROM pg_class WHERE relkind = 'r'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].table_size = atol(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Index sizes (sum)
    res = PQexec(conn, "SELECT COALESCE(sum(pg_relation_size(oid)), 0) FROM pg_class WHERE relkind = 'i'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].index_size = atol(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // WAL files (approximation)
    res = PQexec(conn, "SELECT count(*) FROM pg_ls_waldir() WHERE name ~ '^[0-9A-F]{24}$'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].wal_files = atoi(PQgetvalue(res, 0, 0));
    } else {
        // Fallback for older PostgreSQL versions
        metrics[tenant_idx].wal_files = 3; // Default estimate
    }
    PQclear(res);
    
    // Slow queries (queries > 1s)
    res = PQexec(conn, "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '1 second'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].slow_queries = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Check if primary
    res = PQexec(conn, "SELECT NOT pg_is_in_recovery()");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].is_primary = (strcmp(PQgetvalue(res, 0, 0), "t") == 0) ? 1 : 0;
    }
    PQclear(res);
}

void* metrics_collector(void* arg) {
    while (running) {
        for (int i = 0; i < tenant_count; i++) {
            PGconn *conn = connect_to_tenant(i);
            
            if (PQstatus(conn) == CONNECTION_OK) {
                pthread_mutex_lock(&metrics_mutex);
                collect_enhanced_metrics(conn, i);
                pthread_mutex_unlock(&metrics_mutex);
            }
            
            PQfinish(conn);
        }
        
        sleep(15); // Coleta a cada 15 segundos
    }
    return NULL;
}

void handle_metrics_request(int client_socket) {
    char metrics_data[8192];
    
    pthread_mutex_lock(&metrics_mutex);
    
    snprintf(metrics_data, sizeof(metrics_data),
        "# HELP pganalytics_collector_info Collector information\n"
        "# TYPE pganalytics_collector_info gauge\n"
        "pganalytics_collector_info{version=\"2.0.0-enhanced\",service=\"c-collector\"} 1\n"
        "\n"
        "# HELP pganalytics_total_connections Total connections\n"
        "# TYPE pganalytics_total_connections gauge\n"
        "# HELP pganalytics_active_connections Active connections\n"
        "# TYPE pganalytics_active_connections gauge\n"
        "# HELP pganalytics_idle_connections Idle connections\n"
        "# TYPE pganalytics_idle_connections gauge\n"
        "# HELP pganalytics_idle_in_transaction_connections Idle in transaction connections\n"
        "# TYPE pganalytics_idle_in_transaction_connections gauge\n"
        "# HELP pganalytics_max_connections Maximum connections\n"
        "# TYPE pganalytics_max_connections gauge\n"
        "# HELP pganalytics_cache_hit_ratio Cache hit ratio\n"
        "# TYPE pganalytics_cache_hit_ratio gauge\n"
        "# HELP pganalytics_database_size_bytes Database size in bytes\n"
        "# TYPE pganalytics_database_size_bytes gauge\n"
        "# HELP pganalytics_locks_count Number of locks\n"
        "# TYPE pganalytics_locks_count gauge\n"
        "# HELP pganalytics_table_size_bytes Table size in bytes\n"
        "# TYPE pganalytics_table_size_bytes gauge\n"
        "# HELP pganalytics_index_size_bytes Index size in bytes\n"
        "# TYPE pganalytics_index_size_bytes gauge\n"
        "# HELP pganalytics_wal_files_count WAL files count\n"
        "# TYPE pganalytics_wal_files_count gauge\n"
        "# HELP pganalytics_slow_queries_count Slow queries count\n"
        "# TYPE pganalytics_slow_queries_count gauge\n"
        "# HELP pganalytics_is_primary Is primary server\n"
        "# TYPE pganalytics_is_primary gauge\n"
        "# HELP pganalytics_database_connected Database connection status\n"
        "# TYPE pganalytics_database_connected gauge\n"
        "\n");
    
    for (int i = 0; i < tenant_count; i++) {
        char tenant_metrics[2048];
        snprintf(tenant_metrics, sizeof(tenant_metrics),
            "pganalytics_total_connections{tenant=\"%s\"} %d\n"
            "pganalytics_active_connections{tenant=\"%s\"} %d\n"
            "pganalytics_idle_connections{tenant=\"%s\"} %d\n"
            "pganalytics_idle_in_transaction_connections{tenant=\"%s\"} %d\n"
            "pganalytics_max_connections{tenant=\"%s\"} %d\n"
            "pganalytics_cache_hit_ratio{tenant=\"%s\"} %.2f\n"
            "pganalytics_database_size_bytes{tenant=\"%s\"} %ld\n"
            "pganalytics_locks_count{tenant=\"%s\"} %d\n"
            "pganalytics_table_size_bytes{tenant=\"%s\"} %ld\n"
            "pganalytics_index_size_bytes{tenant=\"%s\"} %ld\n"
            "pganalytics_wal_files_count{tenant=\"%s\"} %d\n"
            "pganalytics_slow_queries_count{tenant=\"%s\"} %d\n"
            "pganalytics_is_primary{tenant=\"%s\"} %d\n"
            "pganalytics_database_connected{tenant=\"%s\"} %d\n",
            tenants[i].name, metrics[i].total_connections,
            tenants[i].name, metrics[i].active_connections,
            tenants[i].name, metrics[i].idle_connections,
            tenants[i].name, metrics[i].idle_in_transaction_connections,
            tenants[i].name, metrics[i].max_connections,
            tenants[i].name, metrics[i].cache_hit_ratio,
            tenants[i].name, metrics[i].database_size,
            tenants[i].name, metrics[i].locks_count,
            tenants[i].name, metrics[i].table_size,
            tenants[i].name, metrics[i].index_size,
            tenants[i].name, metrics[i].wal_files,
            tenants[i].name, metrics[i].slow_queries,
            tenants[i].name, metrics[i].is_primary,
            tenants[i].name, metrics[i].is_connected);
        
        strcat(metrics_data, tenant_metrics);
    }
    
    pthread_mutex_unlock(&metrics_mutex);
    
    char response[16384];
    snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain; version=0.0.4; charset=utf-8\r\n"
        "Content-Length: %ld\r\n"
        "Connection: close\r\n"
        "\r\n"
        "%s",
        strlen(metrics_data), metrics_data);
    
    send(client_socket, response, strlen(response), 0);
}

void handle_health_request(int client_socket) {
    char response[] = 
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: application/json\r\n"
        "Content-Length: 25\r\n"
        "Connection: close\r\n"
        "\r\n"
        "{\"status\": \"healthy\"}";
    
    send(client_socket, response, strlen(response), 0);
}

void handle_root_request(int client_socket) {
    char response[] = 
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/html\r\n"
        "Content-Length: 200\r\n"
        "Connection: close\r\n"
        "\r\n"
        "<h1>PGAnalytics Enhanced Collector</h1>"
        "<p>Version: 2.0.0-enhanced</p>"
        "<p>Available endpoints:</p>"
        "<ul>"
        "<li><a href=\"/metrics\">/metrics</a></li>"
        "<li><a href=\"/health\">/health</a></li>"
        "</ul>";
    
    send(client_socket, response, strlen(response), 0);
}

void handle_request(int client_socket) {
    char buffer[1024];
    recv(client_socket, buffer, sizeof(buffer), 0);
    
    if (strstr(buffer, "GET /metrics") != NULL) {
        handle_metrics_request(client_socket);
    } else if (strstr(buffer, "GET /health") != NULL) {
        handle_health_request(client_socket);
    } else if (strstr(buffer, "GET / ") != NULL) {
        handle_root_request(client_socket);
    } else {
        char response[] = 
            "HTTP/1.1 404 Not Found\r\n"
            "Content-Length: 0\r\n"
            "Connection: close\r\n"
            "\r\n";
        send(client_socket, response, strlen(response), 0);
    }
}

int main() {
    printf("Starting enhanced multi-tenant C collector...\n");
    
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    init_tenants();
    
    // Start metrics collection thread
    pthread_t collector_thread;
    pthread_create(&collector_thread, NULL, metrics_collector, NULL);
    
    // HTTP server
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(8080);
    
    bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr));
    listen(server_socket, 10);
    
    printf("Enhanced HTTP server listening on port 8080\n");
    
    while (running) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        int client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        
        if (client_socket > 0) {
            handle_request(client_socket);
            close(client_socket);
        }
    }
    
    pthread_join(collector_thread, NULL);
    close(server_socket);
    
    printf("Enhanced collector stopped.\n");
    return 0;
}
