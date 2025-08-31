# PG Analytics OpenTelemetry Integration

## 🎯 Visão Geral

Este sistema implementa coleta de métricas PostgreSQL usando **OpenTelemetry** com:
- Coletor customizado em Go
- Métricas nativas do PostgreSQL
- Integração com Prometheus/Grafana
- Alertas automatizados

## 🏗️ Arquitetura

```
PostgreSQL ➜ OpenTelemetry Collector ➜ Prometheus ➜ Grafana
                    ↓
                Alertmanager
```

## 📊 Métricas Coletadas

### Conexões
- `postgres_connections_total{state}` - Total de conexões por estado
- Estados: active, idle, idle_in_transaction

### Performance
- `postgres_slow_queries_total` - Total de slow queries
- `postgres_query_duration_seconds` - Duração das queries
- `postgres_cache_hit_ratio` - Taxa de acerto do cache

### Problemas
- `postgres_deadlocks_total` - Total de deadlocks
- `postgres_replication_lag_bytes` - Lag de replicação

## 🚀 Comandos Rápidos

### Deploy Completo
```bash
chmod +x deploy-otel.sh
./deploy-otel.sh
```

### Apenas Coletor
```bash
cd monitoring/otel-collector
make deploy
```

### Testes
```bash
chmod +x test-otel.sh
./test-otel.sh
```

### Logs
```bash
# Coletor
docker logs -f pganalytics-otel

# Todos os serviços
docker-compose -f docker-compose-monitoring.yml logs -f
```

## 🔧 Configuração

### Variáveis de Ambiente
```bash
DATABASE_URL="postgres://user:pass@host:port/db"
PORT="9188"
```

### Customização
- Editar `monitoring/otel-collector/main.go`
- Rebuild: `make docker-build`
- Restart: `docker-compose restart otel-collector`

## 📈 Dashboards Grafana

### Dashboard Padrão
- **Conexões Ativas**: Número atual
- **Cache Hit Ratio**: Eficiência do cache
- **Slow Queries**: Queries por minuto
- **Deadlocks**: Total acumulado

### Queries Úteis
```promql
# Conexões por estado
postgres_connections_total

# Taxa de slow queries
rate(postgres_slow_queries_total[5m])

# Cache hit ratio
postgres_cache_hit_ratio

# Deadlocks por hora
increase(postgres_deadlocks_total[1h])
```

## 🚨 Alertas

### Configurados
1. **Muitas Conexões**: > 80 ativas
2. **Slow Queries**: > 10 em 5min
3. **Cache Baixo**: < 95%
4. **Deadlocks**: > 5 em 10min
5. **Coletor Inativo**: Down por 1min

### Configurar Notificações
Editar `monitoring/alertmanager/alertmanager.yml`:

```yaml
route:
  receiver: 'web.hook'
receivers:
- name: 'web.hook'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK'
    channel: '#alerts'
```

## 🔍 Endpoints API

### Health Check
```bash
curl http://localhost:9188/health
```

### Métricas Prometheus
```bash
curl http://localhost:9188/metrics
```

### Slow Queries
```bash
curl "http://localhost:9188/slow-queries?limit=5"
```

### Informações de Conexão
```bash
curl http://localhost:9188/connections
```

## 🛠️ Troubleshooting

### Coletor Não Inicia
```bash
# Verificar logs
docker logs pganalytics-otel

# Verificar conectividade PostgreSQL
docker exec pganalytics-otel ping postgres
```

### Métricas Não Aparecem
```bash
# Verificar targets Prometheus
curl http://localhost:9090/api/v1/targets

# Verificar métricas manualmente
curl http://localhost:9188/metrics | grep postgres
```

### PostgreSQL Permissões
```sql
-- Habilitar pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Verificar usuário
SELECT current_user, session_user;
```

## 🔄 Atualizações

### Atualizar Coletor
```bash
cd monitoring/otel-collector
# Editar main.go
make docker-build
docker-compose restart otel-collector
```

### Adicionar Métricas
1. Editar `main.go` - adicionar nova métrica
2. Implementar coleta em `collectMetrics()`
3. Rebuild e restart

## 📚 Referências

- [OpenTelemetry Go](https://opentelemetry.io/docs/instrumentation/go/)
- [PostgreSQL Statistics](https://www.postgresql.org/docs/current/monitoring-stats.html)
- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)
