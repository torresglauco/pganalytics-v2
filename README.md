# PG Analytics v2

![Go](https://img.shields.io/badge/Go-1.23-blue.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-blue.svg)
![Docker](https://img.shields.io/badge/Docker-Ready-green.svg)
![Swagger](https://img.shields.io/badge/Swagger-3.0-orange.svg)

**Sistema avançado de análise de performance PostgreSQL com API REST, autenticação JWT e interface Swagger.**

## 🎯 Sobre o Projeto

O **PG Analytics v2** é uma solução completa para monitoramento e análise de performance de bancos de dados PostgreSQL. Oferece uma API REST robusta com autenticação JWT, documentação Swagger automática e suporte completo a containerização Docker.

### ✨ Funcionalidades Principais

- 🔐 **Autenticação JWT** completa com middleware de segurança
- 📊 **API REST** para análise de performance PostgreSQL
- 📚 **Documentação Swagger** automática e interativa
- 🐳 **Docker & Docker Compose** para desenvolvimento e produção
- 🗄️ **Migrações de banco** automatizadas
- 🧪 **Suite de testes** automatizada (API, performance, banco)
- 🌐 **CORS habilitado** para integrações frontend
- 📈 **Coleta de métricas** em tempo real

## 🛠️ Stack Tecnológica

- **Backend**: Go 1.23+
- **Banco de Dados**: PostgreSQL 15+
- **Framework Web**: Gin Gonic
- **Documentação**: Swagger/OpenAPI 3.0
- **Containerização**: Docker & Docker Compose
- **Autenticação**: JWT (JSON Web Tokens)

## 🚀 Quick Start

### Pré-requisitos

- Docker & Docker Compose
- Go 1.23+ (para desenvolvimento)
- PostgreSQL 15+ (se rodando sem Docker)

### 1. Clone e Inicie

```bash
git clone https://github.com/torresglauco/pganalytics-v2
cd pganalytics-v2

# Copie e configure as variáveis de ambiente
cp .env.example .env

# Suba o ambiente completo
docker-compose up -d
```

### 2. Acesse as Interfaces

- **API Health**: http://localhost:8080/health
- **Swagger UI**: http://localhost:8080/swagger/index.html
- **API Base**: http://localhost:8080/api/v1

### 3. Teste a API

```bash
# Health check
curl http://localhost:8080/health

# Login (credenciais padrão)
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin","password":"admin"}'
```

## 📁 Estrutura do Projeto

```
pganalytics-v2/
├── .github/workflows/    # GitHub Actions CI/CD
├── cmd/server/          # Aplicação principal
├── docker/              # Scripts e recursos Docker
├── docs/                # Documentação Swagger
├── internal/            # Código interno da aplicação
│   ├── config/          # Configurações
│   ├── database/        # Conexão e queries do banco
│   ├── handlers/        # Handlers HTTP
│   └── middleware/      # Middlewares (auth, CORS, etc.)
├── migrations/          # Migrações do banco PostgreSQL
├── tests/              # Suite de testes automatizados
├── docker-compose.yml  # Ambiente de desenvolvimento
├── docker-compose.prod.yml # Ambiente de produção
└── Makefile           # Comandos de automação
```

## 🧪 Testes

Execute a suite completa de testes:

```bash
# Todos os testes
make test

# Testes específicos
bash tests/test_api.sh           # Testes da API
bash tests/advanced_test.sh      # Testes avançados
bash tests/performance_test.sh   # Testes de performance
bash tests/database_test.sh      # Testes do banco
```

## 🐳 Docker

### Desenvolvimento
```bash
docker-compose up -d              # Sobe ambiente completo
docker-compose logs api           # Logs da aplicação
docker-compose down               # Para o ambiente
```

### Produção
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 Desenvolvimento

### Setup Local

```bash
# Instalar dependências
go mod download

# Gerar documentação Swagger
make swagger

# Executar migrações
make migrate

# Rodar aplicação
make run
```

### Comandos Úteis

```bash
make build          # Build da aplicação
make test           # Executar testes
make lint           # Linter de código
make swagger        # Gerar docs Swagger
make migrate        # Executar migrações
make clean          # Limpar builds
```

## 📊 API Endpoints

### Autenticação
- `POST /api/v1/auth/login` - Login de usuário
- `POST /api/v1/auth/register` - Registro de usuário
- `GET /api/v1/auth/profile` - Perfil do usuário

### Analytics
- `GET /api/v1/analytics/queries/slow` - Queries lentas
- `GET /api/v1/analytics/tables/stats` - Estatísticas de tabelas
- `GET /api/v1/analytics/connections` - Conexões ativas
- `GET /api/v1/analytics/performance` - Métricas de performance

### Utilitários
- `GET /health` - Health check da aplicação
- `GET /swagger/*` - Documentação Swagger

## 🔐 Configuração

### Variáveis de Ambiente (.env)

```bash
# Banco de dados
DB_HOST=postgres
DB_PORT=5432
DB_USER=pganalytics
DB_PASSWORD=pganalytics123
DB_NAME=pganalytics

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=24h

# Aplicação
APP_PORT=8080
APP_ENV=development
```

## 🚀 Deploy

### Docker Production

```bash
# Build da imagem de produção
docker build -f Dockerfile -t pganalytics:latest .

# Deploy com docker-compose
docker-compose -f docker-compose.prod.yml up -d
```

### Manual

```bash
# Build da aplicação
make build

# Executar migrações
./pganalytics migrate

# Iniciar servidor
./pganalytics server
```

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 License

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para detalhes.

## 📞 Suporte

- 📧 Email: glauco.torres@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/torresglauco/pganalytics-v2/issues)
- 📖 Docs: [Swagger UI](http://localhost:8080/swagger/index.html)
