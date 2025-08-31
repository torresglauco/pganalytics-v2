#!/bin/bash
echo "🔍 PG Analytics Health Check"
echo "============================"
echo "Date: $(date)"
echo ""

echo "🐳 Container Status:"
docker-compose ps

echo ""
echo "🌐 Service Connectivity:"

# PostgreSQL
if docker exec pganalytics-postgres pg_isready -U admin -d pganalytics >/dev/null 2>&1; then
    echo "✅ PostgreSQL: Connected"
else
    echo "❌ PostgreSQL: Connection failed"
fi

# C Collector
if curl -sf http://localhost:8080/health >/dev/null; then
    echo "✅ C Collector: Healthy"
    COLLECTOR_VERSION=$(curl -s http://localhost:8080/metrics | grep collector_info | head -1)
    echo "   📊 $COLLECTOR_VERSION"
else
    echo "❌ C Collector: Health check failed"
fi

# Prometheus
if curl -sf http://localhost:9090/-/ready >/dev/null; then
    echo "✅ Prometheus: Ready"
    TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"health":"[^"]*"' | wc -l)
    echo "   🎯 Monitoring $TARGETS targets"
else
    echo "❌ Prometheus: Not ready"
fi

# Grafana
if curl -sf http://localhost:3000/api/health >/dev/null; then
    echo "✅ Grafana: Healthy"
else
    echo "❌ Grafana: Health check failed"
fi

echo ""
echo "📊 Quick Metrics Sample:"
curl -s http://localhost:8080/metrics | grep -E "(connections|cache_hit)" | head -3

echo ""
echo "🌐 Access URLs:"
echo "  • Grafana: http://localhost:3000 (admin/admin)"
echo "  • Prometheus: http://localhost:9090"
echo "  • Collector: http://localhost:8080/metrics"
