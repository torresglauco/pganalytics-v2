# 🏆 PG Analytics v2 - Sistema Profissional de Monitoramento PostgreSQL

[![Go](https://img.shields.io/badge/Go-1.23.0-blue.svg)](https://golang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13+-blue.svg)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-Enabled-orange.svg)](https://opentelemetry.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Metrics-red.svg)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Dashboards-orange.svg)](https://grafana.com/)

> 🚀 **Sistema enterprise de monitoramento PostgreSQL** com observabilidade completa, métricas em tempo real e arquitetura OpenTelemetry.

## 📊 **Visão Geral**

O **PG Analytics v2** é uma solução completa e moderna para monitoramento de bancos de dados PostgreSQL, oferecendo:

- 🔒 **Autenticação JWT segura**
- 📊 **Métricas em tempo real** (conexões, performance, queries lentas)
- 🔍 **Observabilidade completa** com OpenTelemetry
- 📈 **Dashboards interativos** via Grafana
- 🐳 **Arquitetura containerizada** com Docker
- 📚 **Documentação Swagger** interativa
- 🚨 **Sistema de alertas** configurável

---

## 🏗️ **Arquitetura do Sistema**

```
┌─────────────────────────────────────────────────────────────────┐
│                        PG ANALYTICS v2                         │
│                   Sistema de Monitoramento                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    OTLP     ┌──────────────────────────────┐
│   CLIENT SIDE   │ ────────→   │         SERVER SIDE          │
│                 │             │                              │
│ Coletor C       │             │ API Go → Prometheus         │
│ (OpenTelemetry) │             │ ↓                            │
│ Port: 8080      │             │ Grafana ← PostgreSQL        │
└─────────────────┘             └──────────────────────────────┘
```

### **Componentes Principais:**

- **🔧 API Go**: Backend REST com autenticação JWT
- **📊 Coletor C**: Coleta métricas PostgreSQL via OpenTelemetry  
- **🎯 Prometheus**: Armazenamento e consulta de métricas
- **📈 Grafana**: Visualização e dashboards
- **🐘 PostgreSQL**: Base de dados e fonte de métricas

---

## ⚡ **Quick Start**

### **🐳 Opção 1: Docker (Recomendado)**

```bash
# Clone o repositório
git clone https://github.com/torresglauco/pganalytics-v2.git
cd pganalytics-v2

# Inicie o sistema completo
docker-compose -f docker-compose-bypass.yml up -d

# Verifique o status
docker ps | grep pganalytics
```

### **🛠️ Opção 2: Desenvolvimento Local**

```bash
# Instale dependências
go mod download

# Configure o ambiente
cp .env.example .env

# Execute migrações
make migrate-up

# Inicie a API
make run
```

---

## 🌐 **Endpoints e Acesso**

| **Serviço** | **URL** | **Credenciais** | **Descrição** |
|-------------|---------|-----------------|---------------|
| 🏠 **API Principal** | [http://localhost:8080](http://localhost:8080) | - | API REST principal |
| 📚 **Documentação** | [http://localhost:8080/swagger/index.html](http://localhost:8080/swagger/index.html) | - | Swagger UI |
| 📊 **Métricas** | [http://localhost:8080/metrics](http://localhost:8080/metrics) | - | Métricas Prometheus |
| 📈 **Grafana** | [http://localhost:3000](http://localhost:3000) | \`admin/admin\` | Dashboards |
| 🎯 **Prometheus** | [http://localhost:9090](http://localhost:9090) | - | Console métricas |

---

## 🔐 **Autenticação**

### **Login:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "admin123"
  }'
```

### **Uso do Token:**
```bash
curl -H "Authorization: Bearer <seu-jwt-token>" \
     http://localhost:8080/api/v1/analytics/connections
```

---

## 📊 **Métricas Disponíveis**

### **🔗 Conexões PostgreSQL:**
```prometheus
# Conexões ativas, idle e total
pganalytics_postgresql_connections{state="active"} 5
pganalytics_postgresql_connections{state="idle"} 2
pganalytics_postgresql_connections{state="total"} 7
```

### **💾 Performance:**
```prometheus
# Cache hit ratio
pganalytics_postgresql_cache_hit_ratio 0.98

# Queries lentas
pganalytics_postgresql_slow_queries_total 3
```

### **ℹ️ Sistema:**
```prometheus
# Informações do coletor
pganalytics_collector_info{version="1.0",type="c-bypass"} 1

# Última atualização
pganalytics_collector_last_update 1756512573
```

---

## 🗂️ **Estrutura do Projeto**

```
pganalytics-v2/
├── 📁 cmd/server/              # Entry point da aplicação
├── 📁 docker/                  # Configurações Docker
├── 📁 docs/                    # Documentação Swagger
├── 📁 internal/                # Lógica de negócio
│   ├── handlers/               # Handlers HTTP
│   ├── middleware/             # Middlewares (auth, CORS)
│   ├── models/                 # Modelos de dados
│   └── services/               # Serviços de negócio
├── 📁 migrations/              # Migrações PostgreSQL
├── 📁 monitoring/              # Sistema de monitoramento
│   ├── c-collector/            # Coletor C OpenTelemetry
│   ├── grafana/                # Configurações Grafana
│   ├── prometheus/             # Configurações Prometheus
│   └── alertmanager/           # Sistema de alertas
├── 📁 tests/                   # Scripts de teste
├── 🐳 docker-compose-*.yml     # Diferentes setups Docker
├── 📄 go.mod                   # Dependências Go
├── 📄 Makefile                 # Comandos de build
└── 📄 README.md                # Documentação principal
```

---

## 🔧 **Comandos Úteis**

### **🐳 Docker:**
```bash
# Iniciar todos os serviços
docker-compose -f docker-compose-bypass.yml up -d

# Ver logs específicos
docker logs pganalytics-c-bypass-collector

# Parar serviços
docker-compose -f docker-compose-bypass.yml down

# Rebuild
docker-compose -f docker-compose-bypass.yml up --build
```

### **🛠️ Desenvolvimento:**
```bash
# Build da aplicação
make build

# Executar testes
make test

# Executar migrações
make migrate-up

# Reverter migrações
make migrate-down

# Live reload (desenvolvimento)
make dev
```

### **📊 Monitoramento:**
```bash
# Verificar métricas
curl http://localhost:8080/metrics

# Status dos containers
docker ps | grep pganalytics

# Health check da API
curl http://localhost:8080/health
```

---

## 🛠️ **Tecnologias Utilizadas**

### **Backend:**
- **Go 1.23.0** - Linguagem principal
- **Gin Framework** - Framework web
- **PostgreSQL** - Banco de dados
- **JWT** - Autenticação segura
- **SQLX** - ORM Go

### **Monitoramento:**
- **OpenTelemetry** - Observabilidade
- **Prometheus** - Métricas
- **Grafana** - Visualização
- **AlertManager** - Alertas

### **DevOps:**
- **Docker & Docker Compose** - Containerização
- **GitHub Actions** - CI/CD
- **Multi-stage Builds** - Otimização

### **Documentação:**
- **Swagger/OpenAPI 3.0** - Documentação API
- **Swaggo** - Geração automática

---

## 📈 **Dashboards Grafana**

### **📊 Dashboard Principal:**
- Conexões PostgreSQL em tempo real
- Performance de queries
- Cache hit ratio
- Uso de recursos

### **🚨 Alertas Configurados:**
- Conexões acima de 80%
- Cache hit ratio abaixo de 95%
- Queries lentas acima de 1s
- Sistema indisponível

---

## 🧪 **Testes**

### **Executar testes completos:**
```bash
# Testes unitários
make test

# Testes de integração
make test-integration

# Testes de API
./tests/api_test.sh

# Verificação de sistema
./final-elegant-status.sh
```

---

## 🚀 **Deploy em Produção**

### **📋 Checklist de Deploy:**

✅ **Configuração:**
- [ ] Configurar \`.env\` com dados reais
- [ ] SSL/TLS configurado
- [ ] Firewall configurado
- [ ] Backup strategy definida

✅ **Segurança:**
- [ ] Senhas fortes definidas
- [ ] JWT secret seguro
- [ ] RBAC configurado
- [ ] Logs de auditoria ativos

✅ **Monitoramento:**
- [ ] Alertas configurados
- [ ] Dashboards personalizados
- [ ] Retention policy definida
- [ ] Backup de configurações

### **🔧 Deploy Docker:**
```bash
# Produção
docker-compose -f docker-compose-bypass.yml up -d

# Com recursos limitados
docker-compose -f docker-compose-bypass.yml up -d \
  --scale c-bypass-collector=2
```

---

## 🔮 **Roadmap**

### **🎯 Próximas Funcionalidades:**
- [ ] **Multi-tenant support**
- [ ] **API GraphQL**
- [ ] **Backup automático**
- [ ] **Distributed tracing**
- [ ] **Mobile app**
- [ ] **AI-powered insights**

### **🔧 Melhorias Técnicas:**
- [ ] **Kubernetes support**
- [ ] **Redis caching**
- [ ] **Rate limiting**
- [ ] **API versioning**
- [ ] **Health checks avançados**

---

## 🤝 **Contribuição**

1. **Fork** o projeto
2. **Crie** uma branch para sua feature (\`git checkout -b feature/AmazingFeature\`)
3. **Commit** suas mudanças (\`git commit -m 'Add some AmazingFeature'\`)
4. **Push** para a branch (\`git push origin feature/AmazingFeature\`)
5. **Abra** um Pull Request

---

## 📞 **Suporte**

### **🐛 Issues:**
- [GitHub Issues](https://github.com/torresglauco/pganalytics-v2/issues)

### **📚 Documentação:**
- [Swagger API](http://localhost:8080/swagger/index.html)
- [Grafana Dashboards](http://localhost:3000)

### **🔧 Debug:**
```bash
# Verificar logs
docker logs pganalytics-c-bypass-collector

# Status detalhado
./final-elegant-status.sh

# Métricas demo
./metrics-demo.sh
```

---

## 📄 **Licença**

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 🏆 **Créditos**

Desenvolvido com ❤️ por **Glauco Torres** usando as melhores práticas de desenvolvimento Go e arquitetura de microserviços.

### **🌟 Tecnologias de Destaque:**
- **Go** para performance e simplicidade
- **OpenTelemetry** para observabilidade moderna
- **Prometheus + Grafana** para monitoramento enterprise
- **Docker** para portabilidade e escalabilidade

---

**🚀 Pronto para produção! Sistema de monitoramento PostgreSQL de nível enterprise.** 

Para começar: \`docker-compose -f docker-compose-bypass.yml up -d\` 🎯
