# PGAnalytics v2 - Setup Completo

## 🚀 Inicialização Rápida

### Pré-requisitos
- Docker e Docker Compose instalados
- Portas 3000, 5432, 8080, 8081, 9090, 9100, 9187 disponíveis

### 1. Inicialização Automática
```bash
# Inicializar stack completo
bash scripts/start_complete_stack.sh

# Ou com limpeza de volumes
bash scripts/start_complete_stack.sh --clean
```

### 2. Validação Manual
```bash
# Executar validação completa
bash scripts/validate_complete_stack.sh
```

## 📊 Endpoints Disponíveis

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Grafana** | http://localhost:3000 | Dashboards (admin/admin123) |
| **Prometheus** | http://localhost:9090 | Métricas e alertas |
| **C Collector** | http://localhost:8080/metrics | Métricas PostgreSQL |
| **Go Backend** | http://localhost:8081/health | API e autenticação |
| **PostgreSQL** | localhost:5432 | Banco de dados |
| **Postgres Exporter** | http://localhost:9187/metrics | Métricas PostgreSQL extras |
| **Node Exporter** | http://localhost:9100/metrics | Métricas do sistema |

## 🛠️ Comandos Úteis

### Monitoramento
```bash
# Ver todos os containers
docker-compose -f docker-compose-complete.yml ps

# Ver logs
docker logs pganalytics-c-collector
docker logs pganalytics-go-backend
docker logs pganalytics-prometheus

# Ver métricas
curl http://localhost:8080/metrics
curl http://localhost:9187/metrics
```

### Banco de Dados
```bash
# Conectar no PostgreSQL
docker exec -it pganalytics-postgres psql -U admin -d pganalytics

# Ver conexões ativas
docker exec pganalytics-postgres psql -U admin -d pganalytics -c "SELECT * FROM pg_stat_activity;"
```

### Prometheus
```bash
# Ver targets do Prometheus
curl http://localhost:9090/api/v1/targets

# Ver métricas coletadas
curl http://localhost:9090/api/v1/query?query=pganalytics_total_connections
```

## 🔧 Troubleshooting

### Problemas Comuns

1. **Porta já em uso**
   ```bash
   # Verificar portas em uso
   netstat -tulpn | grep :3000
   
   # Parar containers
   docker-compose -f docker-compose-complete.yml down
   ```

2. **Container não inicia**
   ```bash
   # Ver logs detalhados
   docker-compose -f docker-compose-complete.yml logs [service-name]
   
   # Rebuild container
   docker-compose -f docker-compose-complete.yml up -d --build [service-name]
   ```

3. **Métricas não aparecem**
   ```bash
   # Verificar conectividade
   curl http://localhost:8080/health
   
   # Ver logs do collector
   docker logs pganalytics-c-collector
   
   # Verificar targets no Prometheus
   curl http://localhost:9090/api/v1/targets
   ```

## 📈 Configuração de Alertas

Os alertas estão configurados automaticamente no Prometheus:
- Conexões altas
- Queries lentas
- Cache hit ratio baixo
- Deadlocks
- Serviços indisponíveis

## 🔒 Segurança

- JWT_SECRET é gerado automaticamente
- Credenciais de fallback desabilitadas por padrão
- Todas as comunicações internas via rede Docker

## 🎯 Próximos Passos

1. Acesse o Grafana em http://localhost:3000
2. Configure dashboards personalizados
3. Ajuste regras de alerta conforme necessário
4. Monitore logs e métricas regularmente
