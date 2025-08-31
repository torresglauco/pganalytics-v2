# 🐳 Docker Enterprise Configuration

## 📁 Estrutura Organizada
```
docker/
├── Dockerfile.dev              # Desenvolvimento com live reload
├── Dockerfile.c-collector      # Coletor C OpenTelemetry
├── Dockerfile.otel-collector   # OpenTelemetry Collector
└── compose/                    # Configurações por ambiente
    ├── bypass.yml              # 🔄 Bypass (Recomendado)
    ├── monitoring.yml          # 📊 Monitoramento Completo
    ├── otel.yml               # 🔍 OpenTelemetry Completo
    ├── integrated.yml         # 🔧 Desenvolvimento Integrado
    └── production.yml         # 🚀 Produção Enterprise
```

## 🚀 Quick Start Enterprise

### Setup Recomendado (Bypass)
```bash
make compose-bypass
```
**Componentes:** PostgreSQL + Coletor C + Prometheus + Grafana

### Setup Monitoramento Completo
```bash
make compose-monitoring  
```
**Componentes:** Bypass + AlertManager + PostgreSQL Exporter

### Setup Produção
```bash
make compose-prod
```
**Componentes:** Multi-stage builds + Health checks + Security

## 📊 Setups Detalhados

| Setup | Uso | Componentes | Portas |
|-------|-----|-------------|--------|
| **bypass** | Desenvolvimento | PostgreSQL, Coletor C, Prometheus, Grafana | 8080, 9090, 3000, 5432 |
| **monitoring** | Staging/Prod | Bypass + AlertManager + Exporter | + 9093, 9187 |
| **otel** | Observabilidade | OpenTelemetry Collector completo | + 4317, 14268 |
| **production** | Enterprise | Otimizado + Security + HA | Load balanced |

## 🔧 Comandos Úteis

```bash
# Gerenciamento
make compose-down        # Parar todos
make logs               # Ver logs
make clean-docker       # Limpeza completa

# Status e Debug
make status             # Status detalhado
make health            # Health checks
docker-compose ps      # Containers ativos
```

## 🔒 Segurança Enterprise

### Produção
- Multi-stage builds otimizados
- Non-root users
- Read-only filesystems
- Resource limits
- Health checks

### Desenvolvimento
- Hot reload habilitado
- Debug ports expostos
- Volume mounts para desenvolvimento
