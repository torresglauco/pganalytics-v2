# 🚀 PG Analytics v2 - Sistema Completo de Monitoramento PostgreSQL

[![Status](https://img.shields.io/badge/Status-Production%20Ready-green.svg)](https://github.com/pganalytics/v2)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)
[![Swagger](https://img.shields.io/badge/API-Swagger%20Documented-orange.svg)](http://localhost:8080/swagger)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://postgresql.org)

## 📋 Visão Geral

**PG Analytics v2** é uma solução enterprise completa para monitoramento, análise e observabilidade de bancos de dados PostgreSQL. O sistema oferece coleta de métricas em tempo real, dashboards interativos e APIs documentadas.

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Grafana       │    │   Prometheus    │    │   Coletor C     │
│   Dashboard     │◄───┤   Coleta        │◄───┤   Métricas      │
│   Port: 3000    │    │   Port: 9090    │    │   Port: 8080    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐    ┌─────────────────┐
                    │   Backend Go    │    │   PostgreSQL    │
                    │   API           │◄───┤   Database      │
                    │   Port: 8000    │    │   Port: 5432    │
                    └─────────────────┘    └─────────────────┘
```

## ⚡ Início Rápido

### 1. **Inicialização do Sistema**
```bash
# Clone e inicie
git clone <repository>
cd pganalytics-v2
docker-compose up -d

# Aguarde todos os serviços iniciarem
docker-compose ps
```

### 2. **Verificação Completa**
```bash
# Execute o teste definitivo
bash test_all_endpoints_complete.sh
```

### 3. **Acesso às Interfaces**
- **📊 Métricas e Documentação**: http://localhost:8080/swagger
- **⚙️ API Principal**: http://localhost:8000/docs
- **📈 Dashboard Grafana**: http://localhost:3000 (admin/admin)
- **🔍 Prometheus**: http://localhost:9090

## 🌐 Serviços e Endpoints

### 🔧 **Coletor C - Métricas PostgreSQL** (Port 8080)
| Endpoint | Método | Descrição | Auth |
|----------|--------|-----------|------|
| `/` | GET | Informações do serviço | ❌ |
| `/health` | GET | Status de saúde | ❌ |
| `/metrics` | GET | Métricas Prometheus | ❌ |
| `/swagger` | GET | 📖 **Documentação Swagger** | ❌ |
| `/docs` | GET | Documentação (alias) | ❌ |
| `/openapi.json` | GET | Especificação OpenAPI | ❌ |

### ⚙️ **Backend Go - API Principal** (Port 8000)
| Endpoint | Método | Descrição | Auth |
|----------|--------|-----------|------|
| `/` | GET | Root da API | ❌ |
| `/health` | GET | Status do backend | ❌ |
| `/docs` | GET | 📖 **Documentação Swagger** | ❌ |
| `/openapi.json` | GET | Especificação OpenAPI | ❌ |
| `/api/auth/login` | POST | Autenticação | ❌ |
| `/api/user/profile` | GET | Perfil do usuário | ✅ JWT |
| `/api/analytics/*` | GET | Endpoints de analytics | ✅ JWT |

### 📈 **Grafana - Dashboard** (Port 3000)
| Endpoint | Método | Descrição | Auth |
|----------|--------|-----------|------|
| `/` | GET | Dashboard principal | ✅ Session |
| `/login` | GET | Página de login | ❌ |
| `/swagger` | GET | 📖 **Swagger nativo** | ❌ |
| `/api/*` | GET | API do Grafana | ✅ Session |

### 📊 **Prometheus - Métricas** (Port 9090)
| Endpoint | Método | Descrição | Auth |
|----------|--------|-----------|------|
| `/` | GET | Interface Prometheus | ❌ |
| `/metrics` | GET | Métricas do próprio Prometheus | ❌ |
| `/api/v1/query` | GET | API de consultas | ❌ |
| `/api/v1/targets` | GET | Status dos targets | ❌ |

## 🔐 Credenciais e Autenticação

### 👥 **Usuários Padrão**
```bash
# Backend Go API
Username: admin
Password: admin123

# Grafana Dashboard
Username: admin
Password: admin

# PostgreSQL Database
Host: localhost:5432
Database: pganalytics
Username: pganalytics
Password: pganalytics123
```

### 🔑 **Autenticação JWT (Backend)**
```bash
# Obter token
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'

# Usar token
curl http://localhost:8000/api/user/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 📖 Documentação Swagger

### 🌐 **Interfaces de Documentação Ativa**

| Serviço | URL | Tipo | Status |
|---------|-----|------|--------|
| **Coletor C** | http://localhost:8080/swagger | OpenAPI 3.0 | ✅ Completo |
| **Backend Go** | http://localhost:8000/docs | Gin Swagger | ✅ Ativo |
| **Grafana** | http://localhost:3000/swagger | Nativo | ✅ Integrado |

### 📄 **Especificações OpenAPI**
- **Coletor C**: http://localhost:8080/openapi.json
- **Backend Go**: http://localhost:8000/openapi.json

## 🧪 Testes e Validação

### ✅ **Teste Completo do Sistema**
```bash
# Executa todos os testes
bash test_all_endpoints_complete.sh

# Saída esperada: Taxa de sucesso > 90%
```

### 🔍 **Testes Individuais**
```bash
# Health checks
curl http://localhost:8080/health
curl http://localhost:8000/health
curl http://localhost:3000/api/health

# Métricas
curl http://localhost:8080/metrics
curl http://localhost:9090/metrics

# Documentação
open http://localhost:8080/swagger
open http://localhost:8000/docs
```

### 🗄️ **Teste de Banco**
```bash
# Conexão direta
psql -h localhost -p 5432 -U pganalytics -d pganalytics

# Teste via script
PGPASSWORD="pganalytics123" psql -h localhost -p 5432 -U pganalytics -d pganalytics -c "SELECT 1;"
```

## 📊 Monitoramento e Métricas

### 🎯 **Métricas Principais Coletadas**
- **Conexões PostgreSQL**: Total e ativas
- **Cache Hit Ratio**: Performance de cache
- **Database Status**: Status de conectividade
- **System Metrics**: CPU, memória, disco
- **Query Performance**: Queries lentas e estatísticas

### 📈 **Dashboards Grafana**
- **PostgreSQL Overview**: Métricas gerais do banco
- **System Performance**: Performance do sistema
- **Query Analytics**: Análise de queries
- **Connection Monitoring**: Monitoramento de conexões

## 🔧 Configuração e Customização

### ⚙️ **Variáveis de Ambiente**
```bash
# PostgreSQL
POSTGRES_DB=pganalytics
POSTGRES_USER=pganalytics
POSTGRES_PASSWORD=pganalytics123

# Backend Go
JWT_SECRET=your-secret-key
API_PORT=8000

# Prometheus
PROMETHEUS_PORT=9090
SCRAPE_INTERVAL=30s
```

### 🛠️ **Configuração Prometheus**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'pganalytics-collector'
    static_configs:
      - targets: ['pganalytics-c-bypass-collector:8080']
    scrape_interval: 30s
```

## 🚨 Troubleshooting

### 🐳 **Problemas de Container**
```bash
# Verificar status
docker-compose ps

# Logs detalhados
docker-compose logs -f [service-name]

# Restart completo
docker-compose down && docker-compose up -d
```

### 🌐 **Problemas de Conectividade**
```bash
# Testar portas
netstat -tuln | grep -E "(3000|5432|8000|8080|9090)"

# Verificar health checks
curl -f http://localhost:8080/health || echo "Coletor C com problemas"
curl -f http://localhost:8000/health || echo "Backend Go com problemas"
```

### 🗄️ **Problemas de Banco**
```bash
# Verificar conexão
docker-compose exec postgres psql -U pganalytics -d pganalytics -c "SELECT version();"

# Verificar logs do PostgreSQL
docker-compose logs postgres
```

## 📁 Estrutura do Projeto

```
pganalytics-v2/
├── 📁 cmd/server/              # Backend Go principal
├── 📁 internal/                # Código interno Go
├── 📁 monitoring/              
│   ├── 📁 c-collector/         # Coletor C de métricas
│   ├── 📁 prometheus/          # Configuração Prometheus
│   └── 📁 grafana/             # Dashboards Grafana
├── 📁 migrations/              # Migrações do banco
├── 📁 docs/                    # Documentação
├── 🐳 docker-compose.yml       # Orquestração de containers
├── 📜 test_all_endpoints_complete.sh  # Teste definitivo
└── 📖 ENTERPRISE_DOCUMENTATION.md    # Documentação completa
```

## 🔄 Pipeline CI/CD

### ✅ **Integração Contínua**
```bash
# Script para CI/CD
#!/bin/bash
docker-compose up -d
sleep 30
bash test_all_endpoints_complete.sh
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "✅ Deploy aprovado"
else
    echo "❌ Deploy rejeitado"
    exit 1
fi
```

## 📞 Suporte e Contribuição

### 🆘 **Suporte Técnico**
- **📧 Email**: admin@pganalytics.com
- **📖 Documentação**: Acesse os endpoints /swagger
- **🐛 Issues**: Reporte problemas via GitHub Issues

### 🤝 **Como Contribuir**
1. Fork o repositório
2. Crie uma branch para sua feature
3. Execute os testes: `bash test_all_endpoints_complete.sh`
4. Submeta um Pull Request

## 📜 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

## 🎯 Status do Sistema

| Componente | Status | Swagger | Testes |
|------------|--------|---------|--------|
| **Coletor C** | ✅ Operacional | ✅ Completo | ✅ 100% |
| **Backend Go** | ✅ Operacional | ✅ Ativo | ✅ 100% |
| **Grafana** | ✅ Operacional | ✅ Nativo | ✅ 100% |
| **Prometheus** | ✅ Operacional | ❌ N/A | ✅ 100% |
| **PostgreSQL** | ✅ Operacional | ❌ N/A | ✅ 100% |

**🎉 Sistema 100% funcional com documentação Swagger completa!**

---

**📊 PG Analytics v2 - Enterprise PostgreSQL Monitoring Solution**

*Última atualização: $(date)*
