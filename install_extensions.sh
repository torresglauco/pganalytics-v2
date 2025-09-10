#!/bin/bash
# Script de instalação das EXTENSÕES prioritárias
# Para o projeto pganalytics-v2 EXISTENTE

echo "🔧 Instalando Extensões Prioritárias no pganalytics-v2"
echo "===================================================="

# Verificar se estamos no diretório correto
if [ ! -d "monitoring/c-collector" ]; then
    echo "❌ Erro: Execute este script no diretório raiz do pganalytics-v2"
    echo "📁 Estrutura esperada: pganalytics-v2/monitoring/c-collector/"
    exit 1
fi

echo "✅ Diretório pganalytics-v2 detectado"

# 1. Backup do coletor atual
echo "📦 Fazendo backup do coletor atual..."
cp monitoring/c-collector/src/collector.c monitoring/c-collector/src/collector.c.backup
cp monitoring/c-collector/include/collector.h monitoring/c-collector/include/collector.h.backup
echo "✅ Backup criado (.backup files)"

# 2. Integrar extensões do código C
echo "🔧 Integrando extensões de código C..."
echo ""
echo "INSTRUÇÕES MANUAIS:"
echo "1. Adicionar os novos campos do collector_extensions.h ao seu metrics_data_t"
echo "2. Adicionar as funções do collector_extensions.c ao seu collector.c"
echo "3. Substituir chamadas collect_metrics() por collect_detailed_metrics_extended()"
echo "4. Adicionar export_enhanced_metrics() ao handle_metrics_request()"
echo ""

# 3. Configurações estendidas
echo "⚙️ Instalando configurações estendidas..."
if [ -f "monitoring/c-collector/config/collector.conf" ]; then
    echo "" >> monitoring/c-collector/config/collector.conf
    echo "# EXTENSÕES PRIORITÁRIAS ADICIONADAS" >> monitoring/c-collector/config/collector.conf
    cat monitoring/c-collector/config/collector_extensions.conf >> monitoring/c-collector/config/collector.conf
    echo "✅ Configurações estendidas adicionadas"
else
    echo "⚠️ Arquivo collector.conf não encontrado, criando..."
    cp monitoring/c-collector/config/collector_extensions.conf monitoring/c-collector/config/collector.conf
fi

# 4. Regras de alerta Prometheus
echo "📊 Instalando regras de alerta estendidas..."
mkdir -p monitoring/prometheus/rules
cp monitoring/prometheus/rules/postgresql_extensions_alerts.yml monitoring/prometheus/rules/
echo "✅ Regras de alerta instaladas"

# 5. Dashboard Grafana estendido
echo "📈 Instalando dashboard estendido..."
mkdir -p monitoring/grafana/dashboards
cp monitoring/grafana/dashboards/postgresql_extensions_dashboard.json monitoring/grafana/dashboards/
echo "✅ Dashboard estendido instalado"

# 6. Configuração Alertmanager estendida
echo "📧 Configurando alertas estendidos..."
if [ -f "monitoring/alertmanager/alertmanager.yml" ]; then
    echo "" >> monitoring/alertmanager/alertmanager.yml
    echo "# EXTENSÕES DE ALERTAS" >> monitoring/alertmanager/alertmanager.yml
    cat monitoring/alertmanager/alertmanager_extensions.yml >> monitoring/alertmanager/alertmanager.yml
    echo "✅ Alertas estendidos configurados"
else
    echo "⚠️ Criando configuração de alertas..."
    cp monitoring/alertmanager/alertmanager_extensions.yml monitoring/alertmanager/alertmanager.yml
fi

echo ""
echo "🎉 EXTENSÕES INSTALADAS COM SUCESSO!"
echo ""
echo "📋 PRÓXIMOS PASSOS MANUAIS:"
echo "1. 🔧 Integrar o código C (seguir instruções nos arquivos *_extensions.*)"
echo "2. 🐳 Recompilar: docker-compose build pg-collector"
echo "3. 🚀 Reiniciar: docker-compose restart"
echo "4. 🧪 Testar: ./scripts/test_extensions.sh"
echo ""
echo "📊 NOVAS MÉTRICAS DISPONÍVEIS:"
echo "- pg_slow_queries (Query Performance)"
echo "- pg_total_locks, pg_waiting_locks (Lock Analysis)"  
echo "- pg_is_standby, pg_max_wal_lag_bytes (Replication)"
echo "- pg_cache_hit_ratio, pg_tables_need_vacuum (Growth/Maintenance)"
echo ""
echo "📧 ALERTAS CONFIGURADOS:"
echo "- Slow queries > 10"
echo "- Lock contention > 5 waiting"
echo "- Replication lag > 100MB"
echo "- Cache hit ratio < 95%"
