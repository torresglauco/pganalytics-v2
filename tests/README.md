# 🧪 Testes da API PGAnalytics

Este diretório contém scripts para testar a API completa.

## Scripts Disponíveis

### 1. Testes Básicos
```bash
chmod +x test_api.sh
./test_api.sh
```
- Health check
- Login/autenticação
- Endpoints protegidos
- Validação de tokens

### 2. Testes Avançados
```bash
chmod +x advanced_test.sh
./advanced_test.sh
```
- Validações detalhadas
- Códigos de status HTTP
- Casos de erro
- Estrutura de resposta

### 3. Testes de Performance
```bash
chmod +x performance_test.sh
./performance_test.sh
```
- Requisições simultâneas
- Teste de carga básico
- Performance de autenticação

### 4. Testes do Banco
```bash
chmod +x database_test.sh
./database_test.sh
```
- Conectividade PostgreSQL
- Verificação de usuários/tabelas
- Inserção/consulta de dados

## Pré-requisitos

- `curl` instalado
- `jq` para parsing JSON: `brew install jq` ou `apt install jq`
- Docker Compose rodando
- API rodando em localhost:8080

## Executar Todos os Testes

```bash
chmod +x *.sh
./test_api.sh
./advanced_test.sh
./performance_test.sh
./database_test.sh
```

## Credenciais de Teste

- **Username**: admin
- **Password**: admin

## Endpoints Testados

- `GET /health` - Health check
- `POST /auth/login` - Autenticação
- `GET /api/data` - Dados analytics (protegido)
- `POST /api/metrics` - Envio de métricas (protegido)

## Interpretando Resultados

- ✅ **Verde**: Teste passou
- ❌ **Vermelho**: Teste falhou
- 🔄 **Amarelo**: Teste em execução

Se algum teste falhar, verifique:
1. API está rodando: `docker-compose ps`
2. Logs da API: `docker-compose logs api`
3. Conectividade: `curl http://localhost:8080/health`
