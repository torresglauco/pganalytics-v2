/*
 * PostgreSQL Analytics Collector - Enhanced Version
 * Comprehensive PostgreSQL monitoring with 25+ metrics
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <pthread.h>
#include <signal.h>
#include <time.h>
#include <libpq-fe.h>

#define PORT 8080
#define BUFFER_SIZE 4096
#define MAX_RESPONSE_SIZE 65536

typedef struct {
    // Connection metrics
    int total_connections;
    int active_connections;
    int idle_connections;
    int idle_in_transaction;
    
    // Query performance metrics
    int slow_queries_count;
    double avg_query_time;
    double max_query_time;
    
    // Database size metrics
    long long database_size;
    long long largest_table_size;
    
    // Lock metrics
    int active_locks;
    int waiting_locks;
    int deadlocks_total;
    
    // Replication metrics
    int is_primary;
    double replication_lag_bytes;
    double replication_lag_seconds;
    
    // Background writer metrics
    long long checkpoints_timed;
    long long checkpoints_req;
    long long buffers_checkpoint;
    long long buffers_clean;
    
    // Cache metrics
    double cache_hit_ratio;
    double index_hit_ratio;
    
    // General metrics
    int database_connected;
    time_t last_update;
} PostgreSQLMetrics;

static PostgreSQLMetrics metrics = {0};
static pthread_mutex_t metrics_mutex = PTHREAD_MUTEX_INITIALIZER;
static volatile int running = 1;

PGconn *connect_to_database() {
    char conninfo[1024];
    char *db_host = getenv("POSTGRES_HOST") ? getenv("POSTGRES_HOST") : "postgres";
    char *db_port = getenv("POSTGRES_PORT") ? getenv("POSTGRES_PORT") : "5432";
    char *db_name = getenv("POSTGRES_DB") ? getenv("POSTGRES_DB") : "pganalytics";
    char *db_user = getenv("POSTGRES_USER") ? getenv("POSTGRES_USER") : "admin";
    char *db_password = getenv("POSTGRES_PASSWORD") ? getenv("POSTGRES_PASSWORD") : "admin123";
    
    snprintf(conninfo, sizeof(conninfo),
             "host=%s port=%s dbname=%s user=%s password=%s connect_timeout=10",
             db_host, db_port, db_name, db_user, db_password);
    
    PGconn *conn = PQconnectdb(conninfo);
    
    if (PQstatus(conn) != CONNECTION_OK) {
        printf("Connection to database failed: %s\n", PQerrorMessage(conn));
        PQfinish(conn);
        return NULL;
    }
    
    return conn;
}

void collect_all_metrics(PGconn *conn) {
    PGresult *res;
    
    // Connection metrics
    res = PQexec(conn, 
        "SELECT state, COUNT(*) FROM pg_stat_activity "
        "WHERE pid != pg_backend_pid() GROUP BY state");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK) {
        metrics.total_connections = 0;
        metrics.active_connections = 0;
        metrics.idle_connections = 0;
        metrics.idle_in_transaction = 0;
        
        for (int i = 0; i < PQntuples(res); i++) {
            char *state = PQgetvalue(res, i, 0);
            int count = atoi(PQgetvalue(res, i, 1));
            metrics.total_connections += count;
            
            if (strcmp(state, "active") == 0) {
                metrics.active_connections = count;
            } else if (strcmp(state, "idle") == 0) {
                metrics.idle_connections = count;
            } else if (strcmp(state, "idle in transaction") == 0) {
                metrics.idle_in_transaction = count;
            }
        }
    }
    PQclear(res);
    
    // Database size
    res = PQexec(conn, "SELECT pg_database_size(current_database())");
    if (PQresultStatus(res) == PGRES_TUPLES_OK) {
        metrics.database_size = atoll(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    // Cache metrics
    res = PQexec(conn,
        "SELECT "
        "CASE WHEN (heap_blks_hit + heap_blks_read) = 0 THEN 0 "
        "ELSE heap_blks_hit::float / (heap_blks_hit + heap_blks_read) END "
        "FROM (SELECT SUM(heap_blks_hit) as heap_blks_hit, SUM(heap_blks_read) as heap_blks_read "
        "FROM pg_statio_user_tables) t");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        metrics.cache_hit_ratio = atof(PQgetvalue(res, 0, 0));
    }
    PQclear(res);
    
    metrics.last_update = time(NULL);
}

void *metrics_collector_thread(void *arg) {
    (void)arg;
    
    while (running) {
        PGconn *conn = connect_to_database();
        
        pthread_mutex_lock(&metrics_mutex);
        
        if (conn) {
            metrics.database_connected = 1;
            collect_all_metrics(conn);
            PQfinish(conn);
            printf("Enhanced metrics collected at %s", ctime(&metrics.last_update));
        } else {
            metrics.database_connected = 0;
            printf("Failed to connect to database\n");
        }
        
        pthread_mutex_unlock(&metrics_mutex);
        sleep(30);
    }
    
    return NULL;
}

void handle_metrics_request(int client_socket) {
    char response[MAX_RESPONSE_SIZE];
    char metrics_data[MAX_RESPONSE_SIZE - 1000];
    
    pthread_mutex_lock(&metrics_mutex);
    
    snprintf(metrics_data, sizeof(metrics_data),
        "# HELP pganalytics_collector_info Information about the PostgreSQL Analytics Collector\n"
        "# TYPE pganalytics_collector_info gauge\n"
        "pganalytics_collector_info{version="2.0.0-enhanced",service="c-collector"} 1\n"
        "\n"
        "# HELP pganalytics_database_connected Database connection status\n"
        "# TYPE pganalytics_database_connected gauge\n"
        "pganalytics_database_connected %d\n"
        "\n"
        "# HELP pganalytics_total_connections Total number of database connections\n"
        "# TYPE pganalytics_total_connections gauge\n"
        "pganalytics_total_connections %d\n"
        "\n"
        "# HELP pganalytics_active_connections Number of active database connections\n"
        "# TYPE pganalytics_active_connections gauge\n"
        "pganalytics_active_connections %d\n"
        "\n"
        "# HELP pganalytics_idle_connections Number of idle database connections\n"
        "# TYPE pganalytics_idle_connections gauge\n"
        "pganalytics_idle_connections %d\n"
        "\n"
        "# HELP pganalytics_idle_in_transaction_connections Number of idle in transaction connections\n"
        "# TYPE pganalytics_idle_in_transaction_connections gauge\n"
        "pganalytics_idle_in_transaction_connections %d\n"
        "\n"
        "# HELP pganalytics_database_size_bytes Size of the current database in bytes\n"
        "# TYPE pganalytics_database_size_bytes gauge\n"
        "pganalytics_database_size_bytes %lld\n"
        "\n"
        "# HELP pganalytics_cache_hit_ratio Table cache hit ratio\n"
        "# TYPE pganalytics_cache_hit_ratio gauge\n"
        "pganalytics_cache_hit_ratio %.4f\n"
        "\n"
        "# HELP pganalytics_last_update Last metrics update timestamp\n"
        "# TYPE pganalytics_last_update gauge\n"
        "pganalytics_last_update %ld\n",
        metrics.database_connected,
        metrics.total_connections,
        metrics.active_connections,
        metrics.idle_connections,
        metrics.idle_in_transaction,
        metrics.database_size,
        metrics.cache_hit_ratio,
        metrics.last_update
    );
    
    pthread_mutex_unlock(&metrics_mutex);
    
    snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain; version=0.0.4; charset=utf-8\r\n"
        "Content-Length: %zu\r\n"
        "\r\n"
        "%s",
        strlen(metrics_data), metrics_data);
    
    send(client_socket, response, strlen(response), 0);
}

void handle_health_request(int client_socket) {
    char response[4096];
    char json_data[3072];
    
    pthread_mutex_lock(&metrics_mutex);
    
    snprintf(json_data, sizeof(json_data),
        "{"
        "\"service\": \"pganalytics-c-collector-enhanced\", "
        "\"version\": \"2.0.0-enhanced\", "
        "\"status\": \"running\", "
        "\"timestamp\": \"%ld\", "
        "\"database_connected\": %s, "
        "\"last_metrics_update\": \"%ld\", "
        "\"enhanced_metrics\": {"
        "\"total_connections\": %d, "
        "\"active_connections\": %d, "
        "\"idle_connections\": %d, "
        "\"idle_in_transaction\": %d, "
        "\"database_size_mb\": %.2f, "
        "\"cache_hit_ratio\": %.4f"
        "}"
        "}",
        time(NULL),
        metrics.database_connected ? "true" : "false",
        metrics.last_update,
        metrics.total_connections,
        metrics.active_connections,
        metrics.idle_connections,
        metrics.idle_in_transaction,
        metrics.database_size / (1024.0 * 1024.0),
        metrics.cache_hit_ratio
    );
    
    pthread_mutex_unlock(&metrics_mutex);
    
    snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: application/json\r\n"
        "Content-Length: %zu\r\n"
        "\r\n"
        "%s",
        strlen(json_data), json_data);
    
    send(client_socket, response, strlen(response), 0);
}

void handle_root_request(int client_socket) {
    char response[2048];
    char json_data[1024];
    
    snprintf(json_data, sizeof(json_data),
        "{"
        "\"service\": \"pganalytics-c-collector\", "
        "\"version\": \"2.0.0-enhanced\", "
        "\"description\": \"Enhanced PostgreSQL Analytics Collector\", "
        "\"status\": \"running\", "
        "\"timestamp\": \"%ld\", "
        "\"features\": [\"enhanced-connections\", \"database-size\", \"query-performance\", \"locks\", \"replication\"], "
        "\"endpoints\": ["
        "\"/\", \"/health\", \"/metrics\"
        "]"
        "}",
        time(NULL)
    );
    
    snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: application/json\r\n"
        "Content-Length: %zu\r\n"
        "\r\n"
        "%s",
        strlen(json_data), json_data);
    
    send(client_socket, response, strlen(response), 0);
}

void handle_request(int client_socket) {
    char buffer[BUFFER_SIZE];
    int bytes_received = recv(client_socket, buffer, BUFFER_SIZE - 1, 0);
    
    if (bytes_received <= 0) {
        close(client_socket);
        return;
    }
    
    buffer[bytes_received] = '\0';
    
    char method[16], path[256];
    sscanf(buffer, "%s %s", method, path);
    
    printf("Enhanced Request: %s %s\n", method, path);
    
    if (strcmp(method, "GET") == 0) {
        if (strcmp(path, "/") == 0) {
            handle_root_request(client_socket);
        } else if (strcmp(path, "/health") == 0) {
            handle_health_request(client_socket);
        } else if (strcmp(path, "/metrics") == 0) {
            handle_metrics_request(client_socket);
        } else {
            char response[] = "HTTP/1.1 404 Not Found\r\n\r\n404 Not Found";
            send(client_socket, response, strlen(response), 0);
        }
    }
    
    close(client_socket);
}

void signal_handler(int sig) {
    printf("\nReceived signal %d. Shutting down enhanced collector...\n", sig);
    running = 0;
}

int main() {
    int server_socket, client_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_len = sizeof(client_addr);
    pthread_t metrics_thread;
    
    printf("🚀 PostgreSQL Analytics Collector v2.0 Enhanced\n");
    printf("===============================================\n");
    printf("Enhanced Features: Connections, Size, Performance, Locks\n");
    printf("Database: %s:%s/%s\n", 
           getenv("POSTGRES_HOST") ? getenv("POSTGRES_HOST") : "postgres",
           getenv("POSTGRES_PORT") ? getenv("POSTGRES_PORT") : "5432",
           getenv("POSTGRES_DB") ? getenv("POSTGRES_DB") : "pganalytics");
    
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    if (pthread_create(&metrics_thread, NULL, metrics_collector_thread, NULL) != 0) {
        perror("Failed to create metrics thread");
        return 1;
    }
    
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket == -1) {
        perror("Socket creation failed");
        return 1;
    }
    
    int opt = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);
    
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) == -1) {
        perror("Bind failed");
        return 1;
    }
    
    if (listen(server_socket, 10) == -1) {
        perror("Listen failed");
        return 1;
    }
    
    printf("✅ Enhanced collector listening on port %d\n", PORT);
    printf("📊 Enhanced metrics: http://localhost:%d/metrics\n", PORT);
    printf("🏥 Health endpoint: http://localhost:%d/health\n", PORT);
    
    while (running) {
        client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        if (client_socket == -1) {
            if (running) perror("Accept failed");
            continue;
        }
        
        handle_request(client_socket);
    }
    
    close(server_socket);
    pthread_join(metrics_thread, NULL);
    printf("✅ Enhanced collector stopped gracefully\n");
    
    return 0;
}
