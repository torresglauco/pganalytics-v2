#!/bin/bash
echo "🔍 ANALISANDO IMPLEMENTAÇÃO ATUAL DO LOGIN"

MAIN_GO="cmd/server/main.go"

echo "📄 1. Analisando main.go atual..."
if [ -f "$MAIN_GO" ]; then
    echo "  📊 Tamanho: $(wc -l < "$MAIN_GO") linhas"
    
    echo ""
    echo "🔍 2. Procurando implementação de login..."
    
    # Procurar função de login
    echo "  🔍 Funções relacionadas a login:"
    grep -n "func.*[Ll]ogin\|loginHandler\|handleLogin" "$MAIN_GO" | head -5 | sed 's/^/    /'
    
    echo ""
    echo "  🔍 Estruturas de request/response:"
    grep -n "type.*Request\|type.*Response\|type.*Login" "$MAIN_GO" | head -5 | sed 's/^/    /'
    
    echo ""
    echo "  🔍 Rotas de autenticação registradas:"
    grep -n "auth/login\|POST.*login\|router.*auth" "$MAIN_GO" | head -5 | sed 's/^/    /'
    
    echo ""
    echo "  🔍 Validação de campos:"
    grep -A 5 -B 5 "Username\|Email.*required\|password.*required" "$MAIN_GO" | head -10 | sed 's/^/    /'
    
    echo ""
    echo "  🔍 Imports relacionados a auth:"
    grep -n "jwt\|bcrypt\|auth\|crypto" "$MAIN_GO" | head -5 | sed 's/^/    /'
    
else
    echo "  ❌ main.go não encontrado"
fi

echo ""
echo "📊 3. Verificando handlers existentes..."

# Verificar handlers no internal/handlers
echo "  📄 Handlers disponíveis:"
if [ -d "internal/handlers" ]; then
    ls -la internal/handlers/ | grep "\.go" | sed 's/^/    /'
    
    echo ""
    echo "  🔍 Verificando handlers.go original:"
    if [ -f "internal/handlers/handlers.go" ]; then
        echo "    📊 handlers.go existe ($(wc -l < internal/handlers/handlers.go) linhas)"
        
        # Procurar estruturas de login em handlers.go
        echo "    🔍 Estruturas de login em handlers.go:"
        grep -n "LoginRequest\|Username\|Email.*json" internal/handlers/handlers.go | head -3 | sed 's/^/      /'
    fi
    
    echo ""
    echo "  🔍 Verificando auth_handlers.go novo:"
    if [ -f "internal/handlers/auth_handlers.go" ]; then
        echo "    📊 auth_handlers.go existe ($(wc -l < internal/handlers/auth_handlers.go) linhas)"
        
        # Procurar estruturas de login em auth_handlers.go
        echo "    🔍 Estruturas de login em auth_handlers.go:"
        grep -n "UserLogin\|Email.*json\|Password.*json" internal/handlers/auth_handlers.go | head -3 | sed 's/^/      /'
    fi
else
    echo "  ❌ Diretório internal/handlers não encontrado"
fi

echo ""
echo "🔧 4. Identificando qual implementação está ativa..."

# Verificar qual handler está sendo usado no main.go
if grep -q "internal/handlers" "$MAIN_GO" 2>/dev/null; then
    echo "  ✅ main.go importa internal/handlers"
    
    if grep -q "auth_handlers\|AuthHandler" "$MAIN_GO" 2>/dev/null; then
        echo "  ✅ Usando novos auth_handlers (nossa implementação)"
    else
        echo "  ⚠️ Usando handlers.go original (implementação antiga)"
    fi
else
    echo "  ⚠️ main.go pode não estar importando handlers internos"
fi

echo ""
echo "📋 5. Recomendações baseadas na análise..."

if grep -q "Username.*required" "$MAIN_GO" 2>/dev/null; then
    echo "  💡 API atual espera 'username', use:"
    echo '    {"username":"admin@pganalytics.local","password":"admin123"}'
elif grep -q "Email.*required" "$MAIN_GO" 2>/dev/null; then
    echo "  💡 API atual espera 'email', use:"
    echo '    {"email":"admin@pganalytics.local","password":"admin123"}'
else
    echo "  🔍 Formato não identificado, teste ambos formatos"
fi

echo ""
echo "✅ Análise da implementação atual concluída!"
