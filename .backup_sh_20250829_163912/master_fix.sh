#!/bin/bash

echo "🚀 CORREÇÃO COMPLETA DA INTEGRAÇÃO JWT"
echo "======================================"

# Verificar se estamos no diretório correto
if [ ! -f "go.mod" ]; then
    echo "❌ Execute no diretório raiz do projeto (onde está go.mod)"
    exit 1
fi

echo ""
echo "📋 PLANO DE CORREÇÃO:"
echo "  1. Consolidar modelos duplicados"
echo "  2. Corrigir middleware e handlers"
echo "  3. Atualizar main.go com rotas corretas"
echo "  4. Testar integração completa"

read -p "🤔 Continuar? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelado pelo usuário"
    exit 1
fi

echo ""
echo "🔧 1. CONSOLIDANDO MODELOS..."
chmod +x consolidate_models.sh
./consolidate_models.sh

echo ""
echo "🔐 2. CORRIGINDO MIDDLEWARE E HANDLERS..."
chmod +x fix_auth_middleware.sh
./fix_auth_middleware.sh

echo ""
echo "📝 3. ATUALIZANDO MAIN.GO..."
chmod +x update_main_routes.sh
./update_main_routes.sh

echo ""
echo "🧪 4. TESTANDO INTEGRAÇÃO COMPLETA..."
chmod +x test_fixes.sh
./test_fixes.sh

echo ""
echo "✅ CORREÇÃO COMPLETA FINALIZADA!"
echo ""
echo "🌐 URLs DISPONÍVEIS:"
echo "  • Health: http://localhost:8080/health"
echo "  • Login: POST http://localhost:8080/auth/login"
echo "  • Metrics: GET http://localhost:8080/metrics (protegida)"
echo "  • Profile: GET http://localhost:8080/api/v1/auth/profile (protegida)"
echo "  • Analytics: GET http://localhost:8080/api/v1/analytics/* (protegidas)"
echo ""
echo "🔑 USUÁRIOS FUNCIONAIS:"
echo "  • admin / admin123"
echo "  • admin@docker.local / admin123"
echo "  • admin@pganalytics.local / admin123"
echo "  • user / admin123"
echo "  • test / admin123"
