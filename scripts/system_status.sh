#!/bin/bash
echo "📊 Status Enterprise - PG Analytics v2"
echo "====================================="

# Containers
echo "🐳 CONTAINERS:"
echo "=============="
if command -v docker >/dev/null 2>&1; then
    containers=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pganalytics || echo "❌ Nenhum container")
    echo "$containers"
else
    echo "❌ Docker não disponível"
fi

echo ""
echo "🌐 SERVIÇOS:"
echo "============"
for service in "8080:API" "9090:Prometheus" "3000:Grafana" "5432:PostgreSQL"; do
    IFS=':' read -r port name <<< "$service"
    if command -v curl >/dev/null 2>&1; then
        case $port in
            8080) url="http://localhost:8080/health" ;;
            9090) url="http://localhost:9090/-/ready" ;;
            3000) url="http://localhost:3000/api/health" ;;
            5432) 
                if command -v pg_isready >/dev/null 2>&1; then
                    pg_isready -h localhost -p 5432 >/dev/null 2>&1 && echo "✅ $name" || echo "❌ $name"
                else
                    netstat -tln 2>/dev/null | grep -q ":$port " && echo "✅ $name" || echo "❌ $name"
                fi
                continue ;;
        esac
        if curl -s "$url" >/dev/null 2>&1; then
            echo "✅ $name ($url)"
        else
            echo "❌ $name ($url)"
        fi
    else
        netstat -tln 2>/dev/null | grep -q ":$port " && echo "✅ $name" || echo "❌ $name"
    fi
done

echo ""
echo "📊 MÉTRICAS:"
echo "============"
if command -v curl >/dev/null 2>&1; then
    if curl -s http://localhost:8080/metrics >/dev/null 2>&1; then
        metrics_count=$(curl -s http://localhost:8080/metrics | grep -c "^# HELP" || echo "0")
        echo "✅ $metrics_count métricas disponíveis"
        
        # Verificar métricas específicas
        metrics_response=$(curl -s http://localhost:8080/metrics)
        if echo "$metrics_response" | grep -q "pganalytics_postgresql_connections"; then
            connections=$(echo "$metrics_response" | grep 'pganalytics_postgresql_connections{state="total"}' | awk '{print $2}' || echo "N/A")
            echo "🔗 Conexões PostgreSQL: $connections"
        fi
        
        if echo "$metrics_response" | grep -q "pganalytics_postgresql_cache_hit_ratio"; then
            cache_ratio=$(echo "$metrics_response" | grep 'pganalytics_postgresql_cache_hit_ratio' | awk '{print $2}' || echo "N/A")
            echo "💾 Cache Hit Ratio: $cache_ratio"
        fi
    else
        echo "❌ Endpoint de métricas offline"
    fi
else
    echo "⚠️  curl não disponível"
fi

echo ""
echo "💾 RECURSOS:"
echo "============"
if command -v docker >/dev/null 2>&1; then
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | grep pganalytics || echo "❌ Nenhum container monitorado"
fi

echo ""
echo "🎯 RESUMO:"
echo "=========="
services_up=0
for port in 8080 9090 3000 5432; do
    if netstat -tln 2>/dev/null | grep -q ":$port "; then
        ((services_up++))
    fi
done

echo "Serviços ativos: $services_up/4"
if [[ $services_up -eq 4 ]]; then
    echo "🎉 Sistema funcionando perfeitamente!"
elif [[ $services_up -gt 1 ]]; then
    echo "⚠️  Sistema funcionando parcialmente"
else
    echo "❌ Sistema com problemas"
fi

echo ""
echo "🔧 COMANDOS ÚTEIS:"
echo "  make compose-bypass  # Iniciar sistema"
echo "  make status         # Status detalhado"
echo "  make logs          # Ver logs"
echo "  make health        # Health check"
echo "  make help          # Todos os comandos"
