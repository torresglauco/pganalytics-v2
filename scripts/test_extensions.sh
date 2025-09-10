#!/bin/bash
# Script de teste das extensões prioritárias

echo "🧪 Testando Extensões Prioritárias"
echo "=================================="

# Testar se o coletor está respondendo
echo "📡 Testando endpoint do coletor..."
response=$(curl -s http://localhost:9090/metrics)

if [ $? -eq 0 ]; then
    echo "✅ Coletor respondendo"
    
    # Testar novas métricas de Query Performance
    if echo "$response" | grep -q "pg_slow_queries"; then
        echo "✅ Métricas de Query Performance encontradas"
        slow_queries=$(echo "$response" | grep "pg_slow_queries" | head -1)
        echo "   📊 $slow_queries"
    else
        echo "❌ Métricas de Query Performance ausentes"
    fi
    
    # Testar métricas de Lock Analysis
    if echo "$response" | grep -q "pg_total_locks"; then
        echo "✅ Métricas de Lock Analysis encontradas"
        total_locks=$(echo "$response" | grep "pg_total_locks" | head -1)
        echo "   🔒 $total_locks"
    else
        echo "❌ Métricas de Lock Analysis ausentes"
    fi
    
    # Testar métricas de Replication
    if echo "$response" | grep -q "pg_is_standby"; then
        echo "✅ Métricas de Replication encontradas"
        standby_status=$(echo "$response" | grep "pg_is_standby" | head -1)
        echo "   🔄 $standby_status"
    else
        echo "❌ Métricas de Replication ausentes"
    fi
    
    # Testar métricas de Cache
    if echo "$response" | grep -q "pg_cache_hit_ratio"; then
        echo "✅ Métricas de Cache Performance encontradas"
        cache_ratio=$(echo "$response" | grep "pg_cache_hit_ratio" | head -1)
        echo "   💾 $cache_ratio"
    else
        echo "❌ Métricas de Cache Performance ausentes"
    fi
    
    echo ""
    echo "📈 Testando Prometheus..."
    if curl -s http://localhost:9091/-/healthy > /dev/null; then
        echo "✅ Prometheus acessível"
        
        # Testar se as novas regras estão carregadas
        rules_response=$(curl -s http://localhost:9091/api/v1/rules)
        if echo "$rules_response" | grep -q "HighSlowQueries"; then
            echo "✅ Regras de alerta estendidas carregadas"
        else
            echo "⚠️ Regras de alerta estendidas não encontradas"
        fi
    else
        echo "❌ Prometheus não acessível"
    fi
    
    echo ""
    echo "📊 Testando Grafana..."
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo "✅ Grafana acessível"
    else
        echo "❌ Grafana não acessível"
    fi
    
    echo ""
    echo "🚨 Testando Alertmanager..."
    if curl -s http://localhost:9093/-/healthy > /dev/null; then
        echo "✅ Alertmanager acessível"
    else
        echo "❌ Alertmanager não acessível"
    fi
    
else
    echo "❌ Coletor não está respondendo em http://localhost:9090"
    echo "💡 Verifique se o container está rodando: docker-compose ps"
    exit 1
fi

echo ""
echo "🎉 TESTE DAS EXTENSÕES CONCLUÍDO!"
echo ""
echo "📋 Status das Funcionalidades Prioritárias:"
echo "🔴 Query Performance Monitoring: $(echo "$response" | grep -q "pg_slow_queries" && echo "✅ Ativo" || echo "❌ Inativo")"
echo "🔴 Lock/Wait Analysis: $(echo "$response" | grep -q "pg_total_locks" && echo "✅ Ativo" || echo "❌ Inativo")"  
echo "🟡 Replication Monitoring: $(echo "$response" | grep -q "pg_is_standby" && echo "✅ Ativo" || echo "❌ Inativo")"
echo "🟡 Database Growth Tracking: $(echo "$response" | grep -q "pg_cache_hit_ratio" && echo "✅ Ativo" || echo "❌ Inativo")"
