#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>

// Secure version with proper buffer management and input validation
int export_metrics_prometheus_format(const PostgreSQLMetrics* metrics, 
                                    const char* tenant_name, 
                                    char* output, 
                                    size_t output_size) {
    if (!metrics || !tenant_name || !output || output_size == 0) {
        return -1; // Invalid parameters
    }
    
    // Validate tenant name (alphanumeric and underscores only)
    size_t tenant_len = strlen(tenant_name);
    if (tenant_len == 0 || tenant_len > 50) {
        return -2; // Invalid tenant name length
    }
    
    for (size_t i = 0; i < tenant_len; i++) {
        if (!isalnum(tenant_name[i]) && tenant_name[i] != '_' && tenant_name[i] != '-') {
            return -3; // Invalid tenant name character
        }
    }
    
    // Calculate required buffer size more accurately
    size_t estimated_size = 8192; // Increased base size
    estimated_size += tenant_len * 25; // Account for tenant name in each metric
    
    // Allocate dynamic buffer with safety margin
    char* metrics_buffer = calloc(1, estimated_size);
    if (!metrics_buffer) {
        return -4; // Memory allocation failed
    }
    
    size_t offset = 0;
    
    // Safe string concatenation macro with overflow protection
    #define SAFE_APPEND(format, ...) do { \
        int written = snprintf(metrics_buffer + offset, estimated_size - offset, format, ##__VA_ARGS__); \
        if (written < 0) { \
            free(metrics_buffer); \
            return -5; /* snprintf error */ \
        } \
        if (offset + written >= estimated_size) { \
            free(metrics_buffer); \
            return -6; /* Buffer would overflow */ \
        } \
        offset += written; \
    } while(0)
    
    // Add header
    SAFE_APPEND("# HELP pganalytics PostgreSQL Analytics Metrics\n");
    SAFE_APPEND("# TYPE pganalytics_total_connections gauge\n");
    
    // Connection metrics with validation
    if (metrics->total_connections >= 0) {
        SAFE_APPEND("pganalytics_total_connections{tenant=\"%s\"} %d\n", tenant_name, metrics->total_connections);
    }
    if (metrics->active_connections >= 0) {
        SAFE_APPEND("pganalytics_active_connections{tenant=\"%s\"} %d\n", tenant_name, metrics->active_connections);
    }
    if (metrics->idle_connections >= 0) {
        SAFE_APPEND("pganalytics_idle_connections{tenant=\"%s\"} %d\n", tenant_name, metrics->idle_connections);
    }
    if (metrics->idle_in_transaction >= 0) {
        SAFE_APPEND("pganalytics_idle_in_transaction{tenant=\"%s\"} %d\n", tenant_name, metrics->idle_in_transaction);
    }
    
    // Query performance metrics
    if (metrics->slow_queries_count >= 0) {
        SAFE_APPEND("pganalytics_slow_queries_count{tenant=\"%s\"} %d\n", tenant_name, metrics->slow_queries_count);
    }
    if (metrics->avg_query_time >= 0.0) {
        SAFE_APPEND("pganalytics_avg_query_time_ms{tenant=\"%s\"} %.2f\n", tenant_name, metrics->avg_query_time);
    }
    if (metrics->max_query_time >= 0.0) {
        SAFE_APPEND("pganalytics_max_query_time_ms{tenant=\"%s\"} %.2f\n", tenant_name, metrics->max_query_time);
    }
    
    // Transaction metrics
    if (metrics->commits_total >= 0) {
        SAFE_APPEND("pganalytics_commits_total{tenant=\"%s\"} %lld\n", tenant_name, metrics->commits_total);
    }
    if (metrics->rollbacks_total >= 0) {
        SAFE_APPEND("pganalytics_rollbacks_total{tenant=\"%s\"} %lld\n", tenant_name, metrics->rollbacks_total);
    }
    
    // Database size metrics
    if (metrics->database_size >= 0) {
        SAFE_APPEND("pganalytics_database_size_bytes{tenant=\"%s\"} %lld\n", tenant_name, metrics->database_size);
    }
    if (metrics->largest_table_size >= 0) {
        SAFE_APPEND("pganalytics_largest_table_size_bytes{tenant=\"%s\"} %lld\n", tenant_name, metrics->largest_table_size);
    }
    
    // Lock metrics
    if (metrics->active_locks >= 0) {
        SAFE_APPEND("pganalytics_active_locks{tenant=\"%s\"} %d\n", tenant_name, metrics->active_locks);
    }
    if (metrics->waiting_locks >= 0) {
        SAFE_APPEND("pganalytics_waiting_locks{tenant=\"%s\"} %d\n", tenant_name, metrics->waiting_locks);
    }
    if (metrics->deadlocks_total >= 0) {
        SAFE_APPEND("pganalytics_deadlocks_total{tenant=\"%s\"} %d\n", tenant_name, metrics->deadlocks_total);
    }
    
    // Replication metrics
    SAFE_APPEND("pganalytics_is_primary{tenant=\"%s\"} %d\n", tenant_name, metrics->is_primary ? 1 : 0);
    if (metrics->replication_lag_bytes >= 0.0) {
        SAFE_APPEND("pganalytics_replication_lag_bytes{tenant=\"%s\"} %.0f\n", tenant_name, metrics->replication_lag_bytes);
    }
    if (metrics->replication_lag_seconds >= 0.0) {
        SAFE_APPEND("pganalytics_replication_lag_seconds{tenant=\"%s\"} %.2f\n", tenant_name, metrics->replication_lag_seconds);
    }
    
    // Cache metrics
    if (metrics->cache_hit_ratio >= 0.0 && metrics->cache_hit_ratio <= 100.0) {
        SAFE_APPEND("pganalytics_cache_hit_ratio{tenant=\"%s\"} %.2f\n", tenant_name, metrics->cache_hit_ratio);
    }
    if (metrics->index_hit_ratio >= 0.0 && metrics->index_hit_ratio <= 100.0) {
        SAFE_APPEND("pganalytics_index_hit_ratio{tenant=\"%s\"} %.2f\n", tenant_name, metrics->index_hit_ratio);
    }
    
    // Status metrics
    SAFE_APPEND("pganalytics_database_connected{tenant=\"%s\"} %d\n", tenant_name, metrics->database_connected ? 1 : 0);
    SAFE_APPEND("pganalytics_last_update{tenant=\"%s\"} %ld\n", tenant_name, (long)metrics->last_update);
    
    // Copy to output buffer safely
    if (offset >= output_size) {
        free(metrics_buffer);
        return -7; // Output buffer too small
    }
    
    memcpy(output, metrics_buffer, offset);
    output[offset] = '\0';
    
    free(metrics_buffer);
    return 0; // Success
    
    #undef SAFE_APPEND
}
