/*
 * PATCH - Estrutura PostgreSQLMetrics completa
 * Verificar se estes campos existem na struct, se não, adicionar
 */

typedef struct {
    // Conexões (já implementado)
    int total_connections;
    int active_connections;
    int idle_connections;
    int idle_in_transaction;
    
    // Query Performance (CORRIGIR implementação)
    int slow_queries_count;
    double avg_query_time;
    double max_query_time;
    
    // ADICIONAR se não existir - Transaction metrics
    long long commits_total;
    long long rollbacks_total;
    long long tuples_returned;
    long long tuples_fetched;
    long long tuples_inserted;
    long long tuples_updated;
    long long tuples_deleted;
    
    // Database Size (já implementado)
    long long database_size;
    long long largest_table_size;
    
    // Lock Metrics (CORRIGIR implementação)
    int active_locks;
    int waiting_locks;
    int deadlocks_total;
    
    // Replication (CORRIGIR implementação)
    int is_primary;
    double replication_lag_bytes;
    double replication_lag_seconds;
    
    // Background Writer (já implementado)
    int checkpoints_timed;
    int checkpoints_req;
    int buffers_checkpoint;
    int buffers_clean;
    
    // Cache (MELHORAR implementação)
    double cache_hit_ratio;
    double index_hit_ratio;
    
    // Status
    int database_connected;
    time_t last_update;
    
} PostgreSQLMetrics;
