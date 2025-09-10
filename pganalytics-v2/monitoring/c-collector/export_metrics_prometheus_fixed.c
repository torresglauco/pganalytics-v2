/*
 * PATCH - Exportação correta de métricas no formato Prometheus
 * Substituir ou adicionar esta função ao main_enhanced.c
 */

void export_metrics_prometheus_format(PostgreSQLMetrics *metrics, const char *tenant_name, char *output, size_t output_size) {
    char metrics_buffer[4096];
    
    snprintf(metrics_buffer, sizeof(metrics_buffer),
        "# PostgreSQL Analytics - Enhanced Metrics\n"
        
        // Connection Metrics
        "pganalytics_total_connections{tenant=\"%s\"} %d\n"
        "pganalytics_active_connections{tenant=\"%s\"} %d\n"
        "pganalytics_idle_connections{tenant=\"%s\"} %d\n"
        "pganalytics_idle_in_transaction{tenant=\"%s\"} %d\n"
        
        // Query Performance Metrics (CORRIGIDAS)
        "pganalytics_slow_queries_count{tenant=\"%s\"} %d\n"
        "pganalytics_avg_query_time_ms{tenant=\"%s\"} %.2f\n"
        "pganalytics_max_query_time_ms{tenant=\"%s\"} %.2f\n"
        
        // Transaction Metrics (NOVAS)
        "pganalytics_commits_total{tenant=\"%s\"} %lld\n"
        "pganalytics_rollbacks_total{tenant=\"%s\"} %lld\n"
        
        // Database Size
        "pganalytics_database_size_bytes{tenant=\"%s\"} %lld\n"
        "pganalytics_largest_table_size_bytes{tenant=\"%s\"} %lld\n"
        
        // Lock Metrics (CORRIGIDAS)
        "pganalytics_active_locks{tenant=\"%s\"} %d\n"
        "pganalytics_waiting_locks{tenant=\"%s\"} %d\n"
        "pganalytics_deadlocks_total{tenant=\"%s\"} %d\n"
        
        // Replication Metrics (CORRIGIDAS)
        "pganalytics_is_primary{tenant=\"%s\"} %d\n"
        "pganalytics_replication_lag_bytes{tenant=\"%s\"} %.0f\n"
        "pganalytics_replication_lag_seconds{tenant=\"%s\"} %.2f\n"
        
        // Cache Metrics (MELHORADAS)
        "pganalytics_cache_hit_ratio{tenant=\"%s\"} %.2f\n"
        "pganalytics_index_hit_ratio{tenant=\"%s\"} %.2f\n"
        
        // Status
        "pganalytics_database_connected{tenant=\"%s\"} %d\n"
        "pganalytics_last_update{tenant=\"%s\"} %ld\n",
        
        // Connection Metrics
        tenant_name, metrics->total_connections,
        tenant_name, metrics->active_connections,
        tenant_name, metrics->idle_connections,
        tenant_name, metrics->idle_in_transaction,
        
        // Query Performance Metrics
        tenant_name, metrics->slow_queries_count,
        tenant_name, metrics->avg_query_time,
        tenant_name, metrics->max_query_time,
        
        // Transaction Metrics
        tenant_name, metrics->commits_total,
        tenant_name, metrics->rollbacks_total,
        
        // Database Size
        tenant_name, metrics->database_size,
        tenant_name, metrics->largest_table_size,
        
        // Lock Metrics
        tenant_name, metrics->active_locks,
        tenant_name, metrics->waiting_locks,
        tenant_name, metrics->deadlocks_total,
        
        // Replication Metrics
        tenant_name, metrics->is_primary,
        tenant_name, metrics->replication_lag_bytes,
        tenant_name, metrics->replication_lag_seconds,
        
        // Cache Metrics
        tenant_name, metrics->cache_hit_ratio,
        tenant_name, metrics->index_hit_ratio,
        
        // Status
        tenant_name, metrics->database_connected,
        tenant_name, metrics->last_update);
    
    strncpy(output, metrics_buffer, output_size - 1);
    output[output_size - 1] = '\0';
}
