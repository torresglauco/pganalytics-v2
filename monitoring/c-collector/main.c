#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <libpq-fe.h>

#define PORT 8080
#define BUFFER_SIZE 8192

char metrics_buffer[BUFFER_SIZE];
char *db_conninfo = "host=postgres port=5432 dbname=pganalytics user=pganalytics password=pganalytics123";

// Função para conectar ao PostgreSQL
PGconn* connect_db() {
    PGconn *conn = PQconnectdb(db_conninfo);
    if (PQstatus(conn) != CONNECTION_OK) {
        fprintf(stderr, "Connection failed: %s\n", PQerrorMessage(conn));
        PQfinish(conn);
        return NULL;
    }
    return conn;
}

// Função para coletar métricas
void collect_metrics() {
    time_t now = time(NULL);
    
    // Inicializar buffer com métricas básicas
    snprintf(metrics_buffer, sizeof(metrics_buffer),
        "# HELP pganalytics_collector_info Information about the collector\n"
        "# TYPE pganalytics_collector_info gauge\n"
        "pganalytics_collector_info{version=\"1.0\",type=\"c-bypass\"} 1\n"
        "# HELP pganalytics_collector_last_update Last metrics update timestamp\n"
        "# TYPE pganalytics_collector_last_update gauge\n"
        "pganalytics_collector_last_update %ld\n", now);
    
    PGconn *conn = connect_db();
    if (!conn) {
        strcat(metrics_buffer, 
            "# HELP pganalytics_collector_error Collector connection error\n"
            "# TYPE pganalytics_collector_error gauge\n"
            "pganalytics_collector_error 1\n");
        return;
    }
    
    // Query para conexões
    PGresult *res = PQexec(conn, 
        "SELECT "
        "  (SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND datname = current_database()) as active, "
        "  (SELECT count(*) FROM pg_stat_activity WHERE state = 'idle' AND datname = current_database()) as idle, "
        "  (SELECT count(*) FROM pg_stat_activity WHERE datname = current_database()) as total");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        char *active = PQgetvalue(res, 0, 0);
        char *idle = PQgetvalue(res, 0, 1);
        char *total = PQgetvalue(res, 0, 2);
        
        char temp[512];
        snprintf(temp, sizeof(temp),
            "# HELP pganalytics_postgresql_connections Number of PostgreSQL connections\n"
            "# TYPE pganalytics_postgresql_connections gauge\n"
            "pganalytics_postgresql_connections{state=\"active\"} %s\n"
            "pganalytics_postgresql_connections{state=\"idle\"} %s\n"
            "pganalytics_postgresql_connections{state=\"total\"} %s\n",
            active, idle, total);
        strcat(metrics_buffer, temp);
    }
    PQclear(res);
    
    // Cache hit ratio
    res = PQexec(conn, 
        "SELECT round(sum(blks_hit)*100.0/sum(blks_hit+blks_read), 4) "
        "FROM pg_stat_database WHERE datname = current_database()");
    
    if (PQresultStatus(res) == PGRES_TUPLES_OK && PQntuples(res) > 0) {
        char *ratio = PQgetvalue(res, 0, 0);
        char temp[256];
        snprintf(temp, sizeof(temp),
            "# HELP pganalytics_postgresql_cache_hit_ratio PostgreSQL cache hit ratio\n"
            "# TYPE pganalytics_postgresql_cache_hit_ratio gauge\n"
            "pganalytics_postgresql_cache_hit_ratio %s\n", 
            ratio ? ratio : "0");
        strcat(metrics_buffer, temp);
    }
    PQclear(res);
    
    // Slow queries (placeholder)
    strcat(metrics_buffer,
        "# HELP pganalytics_postgresql_slow_queries_total Total slow queries\n"
        "# TYPE pganalytics_postgresql_slow_queries_total counter\n"
        "pganalytics_postgresql_slow_queries_total 0\n");
    
    PQfinish(conn);
}

// Servidor HTTP simples
void handle_request(int client_socket, const char* request) {
    char response[BUFFER_SIZE + 512];
    
    if (strstr(request, "GET /metrics") != NULL) {
        collect_metrics();
        snprintf(response, sizeof(response),
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: text/plain; charset=utf-8\r\n"
            "Content-Length: %zu\r\n"
            "\r\n%s", strlen(metrics_buffer), metrics_buffer);
    } else if (strstr(request, "GET /health") != NULL) {
        snprintf(response, sizeof(response),
            "HTTP/1.1 200 OK\r\n"
            "Content-Type: text/plain\r\n"
            "Content-Length: 2\r\n"
            "\r\nOK");
    } else {
        snprintf(response, sizeof(response),
            "HTTP/1.1 404 Not Found\r\n"
            "Content-Type: text/plain\r\n"
            "Content-Length: 9\r\n"
            "\r\nNot Found");
    }
    
    send(client_socket, response, strlen(response), 0);
}

int main() {
    printf("🚀 PG Analytics C Collector iniciando...\n");
    printf("📊 Porta: %d\n", PORT);
    printf("🐘 Database: %s\n", db_conninfo);
    
    // Testar conexão inicial
    PGconn *test_conn = connect_db();
    if (!test_conn) {
        fprintf(stderr, "❌ Falha na conexão inicial com PostgreSQL\n");
        fprintf(stderr, "⚠️  Continuando mesmo assim - tentará reconectar...\n");
    } else {
        printf("✅ Conexão PostgreSQL OK\n");
        PQfinish(test_conn);
    }
    
    // Criar socket
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        perror("❌ Erro ao criar socket");
        return 1;
    }
    
    // Configurar socket para reutilizar endereço
    int opt = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    // Configurar endereço
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);
    
    // Bind
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("❌ Erro no bind");
        return 1;
    }
    
    // Listen
    if (listen(server_socket, 10) < 0) {
        perror("❌ Erro no listen");
        return 1;
    }
    
    printf("✅ Servidor HTTP iniciado em http://0.0.0.0:%d\n", PORT);
    printf("📊 Métricas: http://0.0.0.0:%d/metrics\n", PORT);
    printf("💚 Health: http://0.0.0.0:%d/health\n", PORT);
    
    // Loop principal
    while (1) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        
        int client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        if (client_socket < 0) {
            perror("⚠️  Erro ao aceitar conexão");
            continue;
        }
        
        // Ler request
        char request[1024] = {0};
        read(client_socket, request, sizeof(request) - 1);
        
        // Processar request
        handle_request(client_socket, request);
        
        // Fechar conexão
        close(client_socket);
    }
    
    close(server_socket);
    return 0;
}
