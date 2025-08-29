# 🛠️ Troubleshooting - PG Analytics

## 🚨 Problemas Comuns

### 1. Build Docker Falhando

**Erro**: `no required module provides package github.com/gin-contrib/cors`

**Solução**:
```bash
go get github.com/gin-contrib/cors
go mod tidy
docker-compose build --no-cache
```

### 2. Usuário não consegue fazer login

**Erro**: `Invalid credentials`

**Verificar**:
- Username correto: `admin`, `user`, `test`, `admin@pganalytics.local`
- Password: sempre `admin123`
- Content-Type: `application/json`

### 3. Token inválido

**Erro**: `Invalid token`

**Verificar**:
- Header: `Authorization: Bearer TOKEN`
- Token não expirou (24h)
- Espaço após "Bearer"

### 4. Containers não sobem

**Solução**:
```bash
docker-compose down
docker system prune -f
docker-compose up -d
```

## 🔍 Debug Commands

### Ver logs da API
```bash
docker-compose logs -f api
```

### Testar conectividade
```bash
curl http://localhost:8080/health
```

### Verificar containers
```bash
docker-compose ps
docker-compose top
```

## 🆘 Reset Completo

Se nada funcionar:
```bash
# Parar tudo
docker-compose down

# Limpar containers e imagens
docker system prune -a -f

# Rebuild from scratch
docker-compose build --no-cache
docker-compose up -d
```
