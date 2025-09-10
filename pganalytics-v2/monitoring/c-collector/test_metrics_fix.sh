#!/bin/bash
# Script para testar se as correções foram aplicadas corretamente

echo "🧪 Testando Correções de Métricas"
echo "================================"

# Testar se o coletor está respondendo
echo "📡 Testando endpoint do coletor..."
response=$(curl -s http://localhost:9090/metrics)

if [ $? -eq 0 ]; then
    echo "✅ Coletor respondendo"
    
    echo ""
    echo "🔍 Verificando métricas corrigidas:"
    
    # Query Performance
    if echo "$response" | grep -q "pganalytics_slow_queries_count"; then
        echo "✅ Query Performance: pganalytics_slow_queries_count"
        slow_count=$(echo "$response" | grep "pganalytics_slow_queries_count" | head -1)
        echo "   📊 $slow_count"
    else
        echo "❌ Query Performance: pganalytics_slow_queries_count FALTANDO"
    fi
    
    if echo "$response" | grep -q "pganalytics_avg_query_time_ms"; then
        echo "✅ Query Performance: pganalytics_avg_query_time_ms"
    else
        echo "❌ Query Performance: pganalytics_avg_query_time_ms FALTANDO"
    fi
    
    # Lock Metrics
    if echo "$response" | grep -q "pganalytics_active_locks"; then
        echo "✅ Lock Metrics: pganalytics_active_locks"
        locks=$(echo "$response" | grep "pganalytics_active_locks" | head -1)
        echo "   🔒 $locks"
    else
        echo "❌ Lock Metrics: pganalytics_active_locks FALTANDO"
    fi
    
    if echo "$response" | grep -q "pganalytics_waiting_locks"; then
        echo "✅ Lock Metrics: pganalytics_waiting_locks"
    else
        echo "❌ Lock Metrics: pganalytics_waiting_locks FALTANDO"
    fi
    
    # Replication Metrics
    if echo "$response" | grep -q "pganalytics_is_primary"; then
        echo "✅ Replication: pganalytics_is_primary"
        primary=$(echo "$response" | grep "pganalytics_is_primary" | head -1)
        echo "   🔄 $primary"
    else
        echo "❌ Replication: pganalytics_is_primary FALTANDO"
    fi
    
    # Transaction Metrics
    if echo "$response" | grep -q "pganalytics_commits_total"; then
        echo "✅ Transactions: pganalytics_commits_total"
    else
        echo "❌ Transactions: pganalytics_commits_total FALTANDO"
    fi
    
    # Cache Metrics
    if echo "$response" | grep -q "pganalytics_cache_hit_ratio"; then
        echo "✅ Cache: pganalytics_cache_hit_ratio"
        cache=$(echo "$response" | grep "pganalytics_cache_hit_ratio" | head -1)
        echo "   💾 $cache"
    else
        echo "❌ Cache: pganalytics_cache_hit_ratio FALTANDO"
    fi
    
    echo ""
    echo "📊 Contando métricas por categoria:"
    
    query_metrics=$(echo "$response" | grep -c "query\|slow")
    lock_metrics=$(echo "$response" | grep -c "lock\|deadlock")
    replication_metrics=$(echo "$response" | grep -c "primary\|replication\|lag")
    transaction_metrics=$(echo "$response" | grep -c "commit\|rollback")
    
    echo "🔍 Query Performance: $query_metrics métricas"
    echo "🔒 Lock Analysis: $lock_metrics métricas"
    echo "🔄 Replication: $replication_metrics métricas"
    echo "💳 Transactions: $transaction_metrics métricas"
    
    total_metrics=$(echo "$response" | grep -c "pganalytics_")
    echo "📈 Total de métricas: $total_metrics"
    
    echo ""
    echo "🎯 Status das Funcionalidades Prioritárias:"
    if [ "$query_metrics" -gt 0 ]; then
        echo "🔴 Query Performance Monitoring: ✅ FUNCIONANDO"
    else
        echo "🔴 Query Performance Monitoring: ❌ NÃO FUNCIONANDO"
    fi
    
    if [ "$lock_metrics" -gt 0 ]; then
        echo "🔴 Lock/Wait Analysis: ✅ FUNCIONANDO"
    else
        echo "🔴 Lock/Wait Analysis: ❌ NÃO FUNCIONANDO"
    fi
    
    if [ "$replication_metrics" -gt 0 ]; then
        echo "🟡 Replication Monitoring: ✅ FUNCIONANDO"
    else
        echo "🟡 Replication Monitoring: ❌ NÃO FUNCIONANDO"
    fi
    
    if [ "$transaction_metrics" -gt 0 ]; then
        echo "🔴 Detailed PostgreSQL Metrics: ✅ FUNCIONANDO"
    else
        echo "🔴 Detailed PostgreSQL Metrics: ❌ NÃO FUNCIONANDO"
    fi
    
else
    echo "❌ Coletor não está respondendo em http://localhost:9090"
    echo "💡 Verificar se está rodando: docker-compose ps pg-collector"
    echo "💡 Ver logs: docker-compose logs pg-collector"
    exit 1
fi

echo ""
echo "🔍 Para debugging detalhado:"
echo "docker-compose logs pg-collector | tail -20"
echo ""
echo "🧪 TESTE CONCLUÍDO!"
