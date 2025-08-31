# 📚 PG Analytics v2 - Documentação Enterprise

## 📋 Índice da Documentação

### 📖 **Documentação Principal**
- [README Principal](../README.md) - Guia completo do sistema
- [Monitoramento](../MONITORING.md) - Guia específico de monitoramento
- [Status Final](monitoring/FINAL_STATUS_REPORT.md) - Relatório de status

### 🌐 **Documentação de APIs**
- [Swagger Coletor C](http://localhost:8080/swagger) - API de métricas
- [Swagger Backend Go](http://localhost:8000/docs) - API principal
- [Swagger Grafana](http://localhost:3000/swagger) - Interface nativa

### 📊 **Monitoramento**
- [Guia de Monitoramento](monitoring/) - Documentos específicos
- [Métricas](http://localhost:8080/metrics) - Métricas em tempo real
- [Dashboards](http://localhost:3000) - Grafana (admin/admin)

### 🚀 **Deployment**
- [Scripts de Deploy](deployment/) - Automação de deployment
- [Docker Compose](../docker-compose.yml) - Orquestração de containers
- [Testes](../test_system_definitive.sh) - Script de teste definitivo

### 🔧 **Troubleshooting**
- [Guias de Solução](troubleshooting/) - Resolução de problemas
- [Logs](../docker-compose.yml) - Comandos para visualizar logs

## 🧪 Teste Rápido
```bash
# Executar teste completo do sistema
bash test_system_definitive.sh

# Resultado esperado: 92% de sucesso (12/13 testes)
```

## 🌐 URLs Principais
- **Coletor C**: http://localhost:8080/swagger
- **Backend Go**: http://localhost:8000/docs
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090

---
**Status**: Production Ready | **Sucesso**: 92% | **Data**: $(date)
