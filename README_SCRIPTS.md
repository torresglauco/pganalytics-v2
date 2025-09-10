
# 🚀 PGAnalytics V2 - Scripts Automatizados

## Arquivos Criados:
- `master.sh` - Orchestrador principal (executa tudo)
- `auto_deploy.sh` - Deploy automatizado com backup
- `validate_metrics.sh` - Validação completa de métricas
- `troubleshoot.sh` - Diagnóstico e correção de problemas
- `collect_data.sh` - Coleta dados para análise

## 🎯 COMO USAR:

### Opção 1: Execução Completa (Recomendado)
```bash
chmod +x *.sh
./master.sh
```

### Opção 2: Passo a Passo
```bash
# 1. Deploy
./auto_deploy.sh

# 2. Validação (aguarde 30s após deploy)
./validate_metrics.sh

# 3. Se houver problemas
./troubleshoot.sh diagnose

# 4. Coleta para análise
./collect_data.sh
```

## 📊 O QUE OS SCRIPTS FAZEM:

### master.sh
- Executa todo o pipeline automatizado
- Gera relatório final
- Coleta dados se houver problemas

### auto_deploy.sh
- Faz backup da versão atual
- Aplica as correções
- Build e deploy via Docker
- Valida se tudo subiu

### validate_metrics.sh
- Testa conectividade (collector, prometheus, grafana)
- Valida 14 métricas principais
- Testa performance
- Gera JSON com resultados

### troubleshoot.sh
- Diagnóstico completo
- Restart limpo
- Reset total (se necessário)
- Coleta logs detalhados

### collect_data.sh
- Coleta estrutura do projeto
- Logs completos
- Configurações
- Código fonte
- Gera .tar.gz para análise

## 🔍 MÉTRICAS VALIDADAS:
- pg_up
- pg_connections_active/idle/max
- pg_query_duration_seconds
- pg_locks_count
- pg_replication_lag_bytes
- pg_database_size_bytes
- pg_table_size_bytes
- pg_index_size_bytes
- pg_cache_hit_ratio
- pg_checkpoint_time_seconds
- pg_wal_files_count
- pg_slow_queries_count

## 📁 ARQUIVOS GERADOS:
- `validation_results_*.json` - Resultados da validação
- `metrics_sample_*.txt` - Sample das métricas
- `pganalytics_data_*.tar.gz` - Dados para análise
- `RELATORIO_FINAL_*.md` - Relatório completo
- `logs_*/` - Diretório com logs coletados

## 🆘 SE HOUVER PROBLEMAS:
1. Execute: `./troubleshoot.sh diagnose`
2. Envie: `pganalytics_data_*.tar.gz`
3. Inclua: `validation_results_*.json`

## 🌐 URLs PARA TESTE:
- Métricas: http://localhost:8080/metrics
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

---
Execute `./master.sh` para começar! 🚀
