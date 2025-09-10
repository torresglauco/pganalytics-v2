#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <pthread.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <libpq-fe.h>

#define PORT 8080
#define BUFFER_SIZE 4096
#define MAX_TENANTS 100

typedef struct {
    char tenant_id[64];
    char db_name[64];
    char conn_string[256];
    int active;
    long total_connections;
    long active_connections;
    double cache_hit_ratio;
    long database_size;
    int database_connected;
    time_t last_update;
} tenant_metrics_t;

typedef struct {
    tenant_metrics_t tenants[MAX_TENANTS];
    int tenant_count;
    pthread_mutex_t mutex;
    int running;
    time_t last_global_update;
} global_metrics_t;

global_metrics_t global_metrics = {0};

char *db_host = "postgres";
char *db_port = "5432";
char *db_name = "pganalytics";
char *db_user = "admin";
char *db_password = "admin123";

volatile sig_atomic_t keep_running = 1;

void signal_handler(int signo) {
    keep_running = 0;
    global_metrics.running = 0;
}

void send_response(int client_socket, const char* status, const char* content_type, const char* body) {
    char response[BUFFER_SIZE];
    snprintf(response, sizeof(response),
        "HTTP/1.1 %s\r\n"
        "Content-Type: %s\r\n"
        "Content-Length: %lu\r\n"
        "Connection: close\r\n"
        "\r\n%s",
        status, content_type, strlen(body), body);
    send(client_socket, response, strlen(response), 0);
}

PGconn* connect_to_database(const char* conn_string) {
    PGconn *conn = PQconnectdb(conn_string);
    if (PQstatus(conn) != CONNECTION_OK) {
        PQfinish(conn);
        return NULL;
    }
    return conn;
}

void discover_tenants() {
    char conn_string[512];
    snprintf(conn_string, sizeof(conn_string),
        "host=%s port=%s dbname=%s user=%s password=%s",
        db_host, db_port, db_name, db_user, db_password);
    
    PGconn *conn = connect_to_database(conn_string);
    if (!conn) return;
    
    PGresult *res = PQexec(conn, "SELECT datname FROM pg_database WHERE datistemplate = false");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK) {
        pthread_mutex_lock(&global_metrics.mutex);
        global_metrics.tenant_count = 0;
        
        int rows = PQntuples(res);
        for (int i = 0; i < rows && i < MAX_TENANTS; i++) {
            char *dbname = PQgetvalue(res, i, 0);
            tenant_metrics_t *tenant = &global_metrics.tenants[global_metrics.tenant_count];
            
            strncpy(tenant->tenant_id, dbname, sizeof(tenant->tenant_id) - 1);
            strncpy(tenant->db_name, dbname, sizeof(tenant->db_name) - 1);
            snprintf(tenant->conn_string, sizeof(tenant->conn_string),
                "host=%s port=%s dbname=%s user=%s password=%s",
                db_host, db_port, dbname, db_user, db_password);
            
            tenant->active = 1;
            global_metrics.tenant_count++;
        }
        pthread_mutex_unlock(&global_metrics.mutex);
    }
    
    PQclear(res);
    PQfinish(conn);
}

void update_tenant_metrics(tenant_metrics_t *tenant) {
    PGconn *conn = connect_to_database(tenant->conn_string);
    if (!conn) {
        tenant->database_connected = 0;
        return;
    }
    
    tenant->database_connected = 1;
    
    PGresult *res = PQexec(conn, 
        "SELECT COUNT(*), COUNT(*) FILTER (WHERE state = 'active') "
        "FROM pg_stat_activity WHERE datname = current_database()");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        tenant->total_connections = atol(PQgetvalue(res, 0, 0));
        tenant->active_connections = atol(PQgetvalue(res, 0, 1));
    }
    PQclear(res);
    
    res = PQexec(conn,
        "SELECT CASE WHEN sum(heap_blks_hit + heap_blks_read) = 0 THEN 0 "
        "ELSE round(sum(heap_blks_hit) * 100.0 / sum(heap_blks_hit + heap_blks_read), 2) END "
        "FROM pg_statio_user_tables");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        tenant->cache_hit_ratio = atof(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    res = PQexec(conn, "SELECT pg_database_size(current_database())");
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        tenant->database_size = atol(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    tenant->last_update = time(NULL);
    PQfinish(conn);
}

void* metrics_collector_thread(void* arg) {
    while (global_metrics.running) {
        discover_tenants();
        
        pthread_mutex_lock(&global_metrics.mutex);
        for (int i = 0; i < global_metrics.tenant_count; i++) {
            if (global_metrics.tenants[i].active) {
                update_tenant_metrics(&global_metrics.tenants[i]);
            }
        }
        global_metrics.last_global_update = time(NULL);
        pthread_mutex_unlock(&global_metrics.mutex);
        
        sleep(30);
    }
    return NULL;
}

void handle_metrics_request(int client_socket) {
    char response_body[BUFFER_SIZE * 4] = {0};
    char temp[512];
    
    strcat(response_body, "# Multi-tenant PostgreSQL metrics\n");
    strcat(response_body, "pganalytics_info{version=\"1.0\"} 1\n\n");
    
    pthread_mutex_lock(&global_metrics.mutex);
    
    for (int i = 0; i < global_metrics.tenant_count; i++) {
        tenant_metrics_t *tenant = &global_metrics.tenants[i];
        if (!tenant->active) continue;
        
        snprintf(temp, sizeof(temp), 
            "pganalytics_total_connections{tenant=\"%s\"} %ld\n",
            tenant->tenant_id, tenant->total_connections);
        strcat(response_body, temp);
        
        snprintf(temp, sizeof(temp), 
            "pganalytics_active_connections{tenant=\"%s\"} %ld\n",
            tenant->tenant_id, tenant->active_connections);
        strcat(response_body, temp);
        
        snprintf(temp, sizeof(temp),
            "pganalytics_cache_hit_ratio{tenant=\"%s\"} %.2f\n",
            tenant->tenant_id, tenant->cache_hit_ratio);
        strcat(response_body, temp);
        
        snprintf(temp, sizeof(temp),
            "pganalytics_database_size_bytes{tenant=\"%s\"} %ld\n",
            tenant->tenant_id, tenant->database_size);
        strcat(response_body, temp);
        
        snprintf(temp, sizeof(temp),
            "pganalytics_database_connected{tenant=\"%s\"} %d\n",
            tenant->tenant_id, tenant->database_connected);
        strcat(response_body, temp);
    }
    
    pthread_mutex_unlock(&global_metrics.mutex);
    
    send_response(client_socket, "200 OK", "text/plain", response_body);
}

void handle_health_request(int client_socket) {
    char response_body[1024];
    time_t now = time(NULL);
    
    pthread_mutex_lock(&global_metrics.mutex);
    int connected_tenants = 0;
    for (int i = 0; i < global_metrics.tenant_count; i++) {
        if (global_metrics.tenants[i].database_connected) {
            connected_tenants++;
        }
    }
    
    const char* status = connected_tenants > 0 ? "healthy" : "unhealthy";
    
    snprintf(response_body, sizeof(response_body),
        "{\"status\": \"%s\", \"tenants\": %d, \"connected\": %d, \"timestamp\": %ld}",
        status, global_metrics.tenant_count, connected_tenants, now);
    
    pthread_mutex_unlock(&global_metrics.mutex);
    
    send_response(client_socket, "200 OK", "application/json", response_body);
}

void handle_request(int client_socket) {
    char buffer[BUFFER_SIZE];
    ssize_t bytes_received = recv(client_socket, buffer, sizeof(buffer) - 1, 0);
    
    if (bytes_received > 0) {
        buffer[bytes_received] = '\0';
        
        if (strstr(buffer, "GET /metrics")) {
            handle_metrics_request(client_socket);
        } else if (strstr(buffer, "GET /health")) {
            handle_health_request(client_socket);
        } else {
            const char* body = "{\"service\": \"pganalytics-c-collector\"}";
            send_response(client_socket, "200 OK", "application/json", body);
        }
    }
}

int main() {
    char *env_host = getenv("DB_HOST");
    char *env_port = getenv("DB_PORT");
    char *env_name = getenv("DB_NAME");
    char *env_user = getenv("DB_USER");
    char *env_password = getenv("DB_PASSWORD");
    
    if (env_host) db_host = env_host;
    if (env_port) db_port = env_port;
    if (env_name) db_name = env_name;
    if (env_user) db_user = env_user;
    if (env_password) db_password = env_password;
    
    printf("Starting multi-tenant C collector...\n");
    printf("Database: %s:%s/%s\n", db_host, db_port, db_name);
    
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    pthread_mutex_init(&global_metrics.mutex, NULL);
    global_metrics.running = 1;
    
    discover_tenants();
    
    pthread_t metrics_thread;
    pthread_create(&metrics_thread, NULL, metrics_collector_thread, NULL);
    
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);
    
    bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr));
    listen(server_socket, 10);
    
    printf("Collector listening on port %d\n", PORT);
    
    while (keep_running) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        
        int client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        if (client_socket != -1) {
            handle_request(client_socket);
            close(client_socket);
        }
    }
    
    global_metrics.running = 0;
    pthread_join(metrics_thread, NULL);
    pthread_mutex_destroy(&global_metrics.mutex);
    close(server_socket);
    
    return 0;
}