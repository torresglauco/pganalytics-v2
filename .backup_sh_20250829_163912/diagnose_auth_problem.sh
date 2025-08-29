#!/bin/bash

echo "🔍 DIAGNÓSTICO COMPLETO DA AUTENTICAÇÃO"
echo "=" * 50

echo "📄 1. Verificando estrutura do main.go..."
if [ -f "main.go" ]; then
    echo "  📊 Linhas totais: $(wc -l < main.go)"
    echo "  🔍 Verificando imports..."
    grep -n "import" main.go | head -10
    echo ""
    echo "  🔍 Verificando handlers de auth..."
    grep -n "loginHandler\|authHandler\|Login\|POST.*auth" main.go
    echo ""
    echo "  🔍 Verificando conexão com banco..."
    grep -n "db\|database\|sql" main.go | head -5
    echo ""
    echo "  🔍 Verificando se usa handlers internos..."
    grep -n "internal/\|handlers\.\|services\." main.go
else
    echo "  ❌ main.go não encontrado"
fi

echo ""
echo "📄 2. Verificando implementações de auth disponíveis..."
echo "  🔍 Handlers encontrados:"
ls -la *handlers*.go 2>/dev/null || echo "    ❌ Nenhum handler encontrado"

echo ""
echo "  🔍 Verificando implementação no main.go..."
if [ -f "main.go" ]; then
    echo "    📝 loginHandler implementado diretamente no main.go:"
    grep -A 20 "func loginHandler" main.go | head -15
fi

echo ""
echo "📄 3. Verificando conexão e usuários no banco..."
if command -v psql >/dev/null 2>&1; then
    echo "  🔍 Testando conexão com banco..."
    export PGPASSWORD="pganalytics123"
    psql -h localhost -U pganalytics -d pganalytics -c "\dt" 2>/dev/null | grep -E "users|refresh_tokens" || echo "    ❌ Tabelas de auth não encontradas"
    
    echo "  🔍 Verificando usuários cadastrados..."
    psql -h localhost -U pganalytics -d pganalytics -c "SELECT id, username, email, created_at FROM users LIMIT 5;" 2>/dev/null || echo "    ❌ Não foi possível consultar usuários"
else
    echo "  ⚠️ psql não disponível para teste"
fi

echo ""
echo "📄 4. Verificando arquivos de configuração..."
echo "  🔍 Variáveis de ambiente:"
[ -f ".env" ] && echo "    ✅ .env existe" || echo "    ⚠️ .env não existe"
[ -f ".env.example" ] && echo "    ✅ .env.example existe" || echo "    ⚠️ .env.example não existe"

echo ""
echo "  🔍 Configuração do banco no main.go:"
grep -n "DB_\|DATABASE\|postgres" main.go | head -5

echo ""
echo "📋 5. RESUMO DO DIAGNÓSTICO:"
echo "  🔍 Implementação ativa: $(grep -q "internal/handlers" main.go && echo "NOVA (internal/handlers)" || echo "ANTIGA (main.go)")"
echo "  🔍 Conexão com banco: $(grep -q "sql\.Open\|gorm\.Open" main.go && echo "CONFIGURADA" || echo "NÃO CONFIGURADA")"
echo "  🔍 Middleware de auth: $(grep -q "authMiddleware" main.go && echo "ATIVO" || echo "INATIVO")"

echo ""
echo "✅ Diagnóstico concluído!"
