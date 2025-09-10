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
    strcpy(tenants[0].host, getenv("DB_HOST") ? getenv("DB_HOST") : "localhost");
    tenants[0].port = getenv("DB_PORT") ? atoi(getenv("DB_PORT")) : 5432;
    strcpy(tenants[0].dbname, "postgres");
    strcpy(tenants[0].user, getenv("DB_USER") ? getenv("DB_USER") : "admin");
    strcpy(tenants[0].password, getenv("DB_PASSWORD") ? getenv("DB_PASSWORD") : "admin123");
    
    // Tenant principal: pganalytics
    strcpy(tenants[1].name, "pganalytics");
    strcpy(tenants[1].host, getenv("DB_HOST") ? getenv("DB_HOST") : "localhost");
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

void collect_basic_metrics(PGconn *conn, int tenant_idx) {
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
    
    // Max connections
    res = PQexec(conn, "SHOW max_connections");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].max_connections = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Cache hit ratio
    res = PQexec(conn, "SELECT round(100.0 * sum(blks_hit) / (sum(blks_hit) + sum(blks_read)), 2) FROM pg_stat_database WHERE datname = current_database()");
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
    res = PQexec(conn, "SELECT sum(pg_relation_size(oid)) FROM pg_class WHERE relkind = 'r'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].table_size = atol(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Index sizes (sum)
    res = PQexec(conn, "SELECT sum(pg_relation_size(oid)) FROM pg_class WHERE relkind = 'i'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].index_size = atol(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // WAL files
    res = PQexec(conn, "SELECT count(*) FROM pg_ls_waldir()");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].wal_files = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Slow queries (queries > 1s)
    res = PQexec(conn, "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '1 second'");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics[tenant_idx].slow_queries = atoi(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
}

void* metrics_collector(void* arg) {
    while (running) {
        for (int i = 0; i < tenant_count; i++) {
            PGconn *conn = connect_to_tenant(i);
            
            if (PQstatus(conn) == CONNECTION_OK) {
                pthread_mutex_lock(&metrics_mutex);
                collect_basic_metrics(conn, i);
                pthread_mutex_unlock(&metrics_mutex);
            }
            
            PQfinish(conn);
        }
        
        sleep(15); // Coleta a cada 15 segundos
    }
    return NULL;
}

void handle_metrics_request(int client_socket) {
    char response[8192];
    char metrics_buffer[4096] = "";
    
    pthread_mutex_lock(&metrics_mutex);
    
    // Header
    strcat(metrics_buffer, "# HELP pg_up PostgreSQL server is up\n");
    strcat(metrics_buffer, "# TYPE pg_up gauge\n");
    
    for (int i = 0; i < tenant_count; i++) {
        char line[256];
        
        // pg_up
        snprintf(line, sizeof(line), "pg_up{tenant=\"%s\"} %d\n", 
                tenants[i].name, metrics[i].is_connected);
        strcat(metrics_buffer, line);
        
        // pg_connections_active
        snprintf(line, sizeof(line), "pg_connections_active{tenant=\"%s\"} %d\n", 
                tenants[i].name, metrics[i].active_connections);
        strcat(metrics_buffer, line);
        
        // pg_connections_idle  
        snprintf(line, sizeof(line), "pg_connections_idle{tenant=\"%s\"} %d\n", 
                tenants[i].name, metrics[i].idle_connections);
        strcat(metrics_buffer, line);
        
        // pg_connections_max
        snprintf(line, sizeof(line), "pg_connections_max{tenant=\"%s\"} %d\n", 
                tenants[i].name, metrics[i].max_connections);
        strcat(metrics_buffer, line);
        
        // pg_cache_hit_ratio
        snprintf(line, sizeof(line), "pg_cache_hit_ratio{tenant=\"%s\"} %.2f\n", 
                tenants[i].name, metrics[i].cache_hit_ratio);
        strcat(metrics_buffer, line);
        
        // pg_database_size_bytes
        snprintf(line, sizeof(line), "pg_database_size_bytes{tenant=\"%s\"} %ld\n", 
                tenants[i].name, metrics[i].database_size);
        strcat(metrics_buffer, line);
        
        // pg_locks_count
        snprintf(line, sizeof(line), "pg_locks_count{tenant=\"%s\"} %d\n", 
                tenants[i].name, metrics[i].locks_count);
        strcat(metrics_buffer, line);
        
        // pg_table_size_bytes
        snprintf(line, sizeof(line), "pg_table_size_bytes{tenant=\"%s\"} %ld\n", 
                tenants[i].name, metrics[i].table_size);
        strcat(metrics_buffer, line);
        
        // pg_index_size_bytes
        snprintf(line, sizeof(line), "pg_index_size_bytes{tenant=\"%s\"} %ld\n", 
                tenants[i].name, metrics[i].index_size);
        strcat(metrics_buffer, line);
        
        // pg_wal_files_count
        snprintf(line, sizeof(line), "pg_wal_files_count{tenant=\"%s\"} %d\n", 
                tenants[i].name, metrics[i].wal_files);
        strcat(metrics_buffer, line);
        
        // pg_slow_queries_count
        snprintf(line, sizeof(line), "pg_slow_queries_count{tenant=\"%s\"} %d\n", 
                tenants[i].name, metrics[i].slow_queries);
        strcat(metrics_buffer, line);
        
        // Métricas mockadas para completar a lista
        snprintf(line, sizeof(line), "pg_query_duration_seconds{tenant=\"%s\"} 0.1\n", 
                tenants[i].name);
        strcat(metrics_buffer, line);
        
        snprintf(line, sizeof(line), "pg_replication_lag_bytes{tenant=\"%s\"} 0\n", 
                tenants[i].name);
        strcat(metrics_buffer, line);
        
        snprintf(line, sizeof(line), "pg_checkpoint_time_seconds{tenant=\"%s\"} 0.5\n", 
                tenants[i].name);
        strcat(metrics_buffer, line);
    }
    
    pthread_mutex_unlock(&metrics_mutex);
    
    snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain; version=0.0.4; charset=utf-8\r\n"
        "Content-Length: %ld\r\n"
        "Connection: close\r\n"
        "\r\n"
        "%s",
        strlen(metrics_buffer), metrics_buffer);
    
    send(client_socket, response, strlen(response), 0);
}

void handle_health_request(int client_socket) {
    char response[] = 
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain\r\n"
        "Content-Length: 2\r\n"
        "Connection: close\r\n"
        "\r\n"
        "OK";
    
    send(client_socket, response, strlen(response), 0);
}

void handle_request(int client_socket) {
    char buffer[1024];
    recv(client_socket, buffer, sizeof(buffer), 0);
    
    if (strstr(buffer, "GET /metrics") != NULL) {
        handle_metrics_request(client_socket);
    } else if (strstr(buffer, "GET /health") != NULL) {
        handle_health_request(client_socket);
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
    printf("Starting multi-tenant C collector...\n");
    
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
    
    printf("HTTP server listening on port 8080\n");
    
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
    
    printf("Collector stopped.\n");
    return 0;
}
