# Extensões Prioritárias - PostgreSQL Analytics v2

## 🎯 Objetivo
Este pacote adiciona as **funcionalidades prioritárias** ao seu projeto pganalytics-v2 existente.

## 📦 O que está incluído

### 🔴 High-Priority Features
- ✅ **Query Performance Monitoring** - pg_stat_statements integration
- ✅ **Lock/Wait Analysis** - Real-time contention detection  
- ✅ **Email Alerting System** - Enhanced notifications

### 🟡 Moderate-Priority Features  
- ✅ **Replication Monitoring** - Primary/standby health
- ✅ **Database Growth Tracking** - Capacity planning

## 🚀 Instalação Rápida

### 1. Extrair no projeto existente
```bash
# No diretório pganalytics-v2/
unzip pganalytics-v2-EXTENSIONS.zip
```

### 2. Executar instalação automática
```bash
chmod +x install_extensions.sh
./install_extensions.sh
```

### 3. Integração manual do código C
Seguir instruções nos arquivos:
- `monitoring/c-collector/src/collector_extensions.c`
- `monitoring/c-collector/include/collector_extensions.h`

### 4. Recompilar e reiniciar
```bash
docker-compose build pg-collector
docker-compose restart
```

### 5. Testar extensões
```bash
chmod +x scripts/test_extensions.sh
./scripts/test_extensions.sh
```

## 📊 Novas Métricas

### Query Performance
- `pg_slow_queries` - Número de queries lentas
- `pg_avg_query_time_ms` - Tempo médio de execução  
- `pg_max_query_time_ms` - Tempo máximo de execução

### Lock Analysis
- `pg_total_locks` - Total de locks ativos
- `pg_waiting_locks` - Queries aguardando locks
- `pg_deadlocks_total` - Contador de deadlocks

### Replication Health
- `pg_is_standby` - Se é servidor standby
- `pg_active_replication_slots` - Slots ativos
- `pg_max_wal_lag_bytes` - Lag máximo de WAL

### Growth & Maintenance
- `pg_cache_hit_ratio` - Taxa de acerto do cache
- `pg_tables_need_vacuum` - Tabelas precisando vacuum

## 🚨 Alertas Configurados

### Críticos
- Lock contention > 5 queries waiting
- Queries > 30 segundos de execução

### Warnings  
- Slow queries > 10
- Cache hit ratio < 95%
- Replication lag > 100MB

### Info
- Tabelas precisando vacuum > 5
- Crescimento alto do banco

## 🔧 Compatibilidade

- ✅ PostgreSQL 9.5+
- ✅ Mantém código existente
- ✅ Backward compatible
- ✅ Zero downtime upgrade

## 📞 Suporte

1. Verificar logs: `docker-compose logs pg-collector`
2. Testar métricas: `./scripts/test_extensions.sh`
3. Verificar backups: `*.backup files`

---
**Extensões prontas para produção!** 🎉
