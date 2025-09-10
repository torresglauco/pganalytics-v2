# 📊 Monitoring System - PG Analytics v2

> 🔍 **Sistema completo de monitoramento PostgreSQL** com OpenTelemetry, Prometheus e Grafana

## 🎯 **Visão Geral**

Este diretório contém toda a infraestrutura de monitoramento do **PG Analytics v2**, implementando uma arquitetura moderna de observabilidade com:

- 🚀 **Coletores OpenTelemetry** para métricas PostgreSQL
- 📊 **Prometheus** para armazenamento de métricas
- 📈 **Grafana** para visualização e dashboards
- 🚨 **AlertManager** para sistema de alertas
- 🐘 **PostgreSQL Exporter** para métricas avançadas

---

## 🏗️ **Arquitetura de Monitoramento**

```
┌─────────────────────────────────────────────────────────────────┐
│                    MONITORING ARCHITECTURE                     │
└─────────────────────────────────────────────────────────────────┘

    PostgreSQL                 Coletores               Métricas
    Database                   OpenTelemetry           Storage
       │                           │                       │
       ▼                           ▼                       ▼
┌─────────────┐    OTLP      ┌─────────────┐   HTTP   ┌─────────────┐
│ PostgreSQL  │ ◄────────────│ C-Collector │ ────────►│ Prometheus  │
│   Source    │              │ (Port 8080) │          │ (Port 9090) │
└─────────────┘              └─────────────┘          └─────────────┘
                                    │                       │
                                    │                       ▼
                                    │              ┌─────────────┐
                                    └─────────────►│   Grafana   │
                                                   │ (Port 3000) │
                                                   └─────────────┘
```

---

## 📁 **Estrutura de Diretórios**

```
monitoring/
├── 📁 alertmanager/           # Sistema de alertas
│   ├── alertmanager.yml       # Configuração AlertManager
│   └── alerts.yml             # Regras de alertas
├── 📁 c-collector/            # Coletor C OpenTelemetry
│   ├── Dockerfile             # Build do coletor C
│   ├── main.c                 # Código fonte principal
│   ├── otel_config.h          # Configurações OpenTelemetry
│   └── README.md              # Documentação específica
├── 📁 collector-c-otel/       # Versão alternativa do coletor
│   ├── Dockerfile             # Build alternativo
│   └── collector.c            # Implementação alternativa
├── 📁 grafana/                # Configurações Grafana
│   ├── dashboards/            # Dashboards customizados
│   ├── datasources/           # Fontes de dados
│   └── grafana.ini            # Configuração principal
├── 📁 otel-collector/         # OpenTelemetry Collector
│   ├── config.yaml            # Configuração OTEL
│   ├── Dockerfile             # Build do collector
│   └── otel-collector.yml     # Docker Compose específico
├── 📁 otel-collector-service/ # Serviço OTEL Collector
│   ├── main.go                # Implementação em Go
│   └── go.mod                 # Dependências Go
├── 📁 postgres-exporter/      # PostgreSQL Exporter
│   ├── queries.yaml           # Queries customizadas
│   └── exporter.yml           # Configuração do exporter
├── 📁 prometheus/             # Configurações Prometheus
│   ├── prometheus.yml         # Configuração principal
│   ├── alerts.yml             # Regras de alertas
│   └── rules/                 # Regras customizadas
└── 📄 postgres-setup.sql      # Setup inicial PostgreSQL
```

---

## 🚀 **Quick Start**

### **🐳 Iniciar Monitoramento Completo:**

```bash
# Do diretório raiz do projeto
cd pganalytics-v2

# Iniciar stack de monitoramento
docker-compose -f docker-compose-bypass.yml up -d

# Verificar status dos serviços
docker ps | grep -E "(prometheus|grafana|collector)"
```

### **🔧 Iniciar Componentes Individuais:**

```bash
# Apenas Prometheus
docker-compose -f docker-compose-bypass.yml up -d prometheus

# Apenas Grafana
docker-compose -f docker-compose-bypass.yml up -d grafana

# Apenas Coletor
docker-compose -f docker-compose-bypass.yml up -d c-bypass-collector
```

---

## 📊 **Métricas Coletadas**

### **🔗 Conexões PostgreSQL:**
- **Active Connections**: Conexões ativas no momento
- **Idle Connections**: Conexões inativas
- **Total Connections**: Total de conexões
- **Max Connections**: Limite máximo configurado

### **💾 Performance:**
- **Cache Hit Ratio**: Taxa de acerto do cache
- **Buffer Hit Ratio**: Taxa de acerto do buffer
- **Checkpoint Statistics**: Estatísticas de checkpoint
- **WAL Statistics**: Estatísticas de Write-Ahead Log

### **🐌 Queries:**
- **Slow Queries**: Queries que excedem tempo limite
- **Query Duration**: Duração média das queries
- **Query Frequency**: Frequência de execução
- **Lock Waits**: Esperas por locks

### **💽 Storage:**
- **Database Size**: Tamanho do banco de dados
- **Table Sizes**: Tamanho das tabelas
- **Index Usage**: Uso de índices
- **Bloat Statistics**: Estatísticas de bloat

### **⚡ Sistema:**
- **CPU Usage**: Uso de CPU
- **Memory Usage**: Uso de memória
- **Disk I/O**: Operações de disco
- **Network I/O**: Tráfego de rede

---

## 🎨 **Dashboards Grafana**

### **📈 Dashboard Principal - PostgreSQL Overview:**
- Métricas gerais do banco
- Gráficos de conexões em tempo real
- Performance de queries
- Uso de recursos

### **🔍 Dashboard Detalhado - PostgreSQL Performance:**
- Análise detalhada de queries lentas
- Estatísticas de cache e buffer
- Monitoring de locks e waits
- Análise de checkpoint

### **🚨 Dashboard de Alertas:**
- Status de todos os alertas
- História de alertas disparados
- Métricas críticas em tempo real

### **📊 Dashboard de Capacidade:**
- Crescimento do banco de dados
- Projeções de armazenamento
- Análise de índices
- Estatísticas de bloat

---

## 🚨 **Sistema de Alertas**

### **🔴 Alertas Críticos:**
- **Database Down**: PostgreSQL indisponível
- **High Connection Usage**: Uso de conexões > 90%
- **Low Cache Hit Ratio**: Cache hit ratio < 95%
- **Long Running Queries**: Queries rodando > 5 minutos

### **🟡 Alertas de Warning:**
- **Medium Connection Usage**: Uso de conexões > 70%
- **Slow Queries**: Queries lentas detectadas
- **High Lock Waits**: Muitas esperas por locks
- **Disk Space Low**: Espaço em disco < 20%

### **🔵 Alertas Informativos:**
- **Backup Completed**: Backup realizado com sucesso
- **Configuration Changed**: Configuração alterada
- **Maintenance Window**: Janela de manutenção iniciada

---

## 🔧 **Configuração**

### **📊 Prometheus Configuration:**

```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'pganalytics-collector'
    static_configs:
      - targets: ['c-bypass-collector:8080']
    scrape_interval: 10s
    metrics_path: /metrics

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']
```

### **📈 Grafana Configuration:**

```ini
# monitoring/grafana/grafana.ini
[server]
http_port = 3000
domain = localhost

[security]
admin_user = admin
admin_password = admin

[auth.anonymous]
enabled = true
org_role = Viewer
```

### **🚨 AlertManager Configuration:**

```yaml
# monitoring/alertmanager/alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@pganalytics.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://localhost:5001/'
```

---

## 🛠️ **Desenvolvimento**

### **🔨 Build do Coletor C:**

```bash
# Entrar no diretório do coletor
cd monitoring/c-collector

# Build manual
gcc -o collector main.c -lpq -ljson-c -lcurl

# Build via Docker
docker build -t pganalytics-c-collector .
```

### **🐹 Build do Coletor Go:**

```bash
# Entrar no diretório do serviço
cd monitoring/otel-collector-service

# Build
go build -o otel-collector main.go

# Run
./otel-collector
```

### **🧪 Testes:**

```bash
# Testar métricas do coletor
curl http://localhost:8080/metrics

# Testar Prometheus
curl http://localhost:9090/api/v1/query?query=up

# Testar Grafana API
curl http://admin:admin@localhost:3000/api/health
```

---

## 📋 **Troubleshooting**

### **🔍 Problemas Comuns:**

#### **Coletor não conecta ao PostgreSQL:**
```bash
# Verificar conectividade
docker exec -it c-bypass-collector psql -h postgres -U pganalytics -d pganalytics

# Verificar logs
docker logs c-bypass-collector
```

#### **Prometheus não coleta métricas:**
```bash
# Verificar targets no Prometheus
curl http://localhost:9090/api/v1/targets

# Verificar métricas disponíveis
curl http://localhost:8080/metrics
```

#### **Grafana não mostra dados:**
```bash
# Verificar datasource
curl http://admin:admin@localhost:3000/api/datasources

# Testar conectividade com Prometheus
curl http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=up
```

### **🚨 Comandos de Debug:**

```bash
# Status de todos os serviços
docker-compose -f docker-compose-bypass.yml ps

# Logs detalhados
docker-compose -f docker-compose-bypass.yml logs -f

# Reiniciar serviços problemáticos
docker-compose -f docker-compose-bypass.yml restart c-bypass-collector

# Verificar recursos
docker stats
```

---

## 📊 **Métricas Personalizadas**

### **🔧 Adicionando Nova Métrica:**

1. **No Coletor C** (\`monitoring/c-collector/main.c\`):
```c
// Adicionar nova query
char *custom_query = "SELECT count(*) as custom_metric FROM pg_stat_activity";

// Processar resultado
printf("# HELP custom_metric Custom metric description\n");
printf("# TYPE custom_metric gauge\n");
printf("custom_metric %s\n", result);
```

2. **No Prometheus** (\`monitoring/prometheus/prometheus.yml\`):
```yaml
# Configuração já coleta automaticamente
# Métricas expostas no endpoint /metrics
```

3. **No Grafana**:
- Criar painel com query: \`custom_metric\`
- Configurar visualização apropriada

---

## 🔮 **Próximos Passos**

### **🎯 Funcionalidades Planejadas:**
- [ ] **Alertas via Slack/Teams**
- [ ] **Métricas de aplicação**
- [ ] **Distributed tracing**
- [ ] **Machine learning insights**
- [ ] **Automated tuning recommendations**

### **🚀 Melhorias Técnicas:**
- [ ] **High availability setup**
- [ ] **Multi-region monitoring**
- [ ] **Custom exporters**
- [ ] **Advanced alerting rules**
- [ ] **Performance optimization**

---

## 📞 **Suporte**

### **📚 Documentação:**
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/)
- [OpenTelemetry Docs](https://opentelemetry.io/docs/)

### **🔧 Scripts Úteis:**
```bash
# Status do sistema
../final-elegant-status.sh

# Demo de métricas
../metrics-demo.sh

# Backup de configurações
tar -czf monitoring-backup.tar.gz monitoring/
```

---

**🏆 Sistema de monitoramento enterprise pronto para produção!**

Para começar: \`docker-compose -f docker-compose-bypass.yml up -d\` 🚀
