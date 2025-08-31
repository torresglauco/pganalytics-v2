#!/bin/bash
echo "🔒 Verificação de Segurança Enterprise"
echo "====================================="

ISSUES=0

echo "🔍 Verificando arquivos sensíveis..."
for pattern in "*.env" "*.pem" "*.key" "*.credentials" "CREDENCIAIS_*"; do
    if find . -name "$pattern" -not -path "./.git/*" -not -path "./backup_*/*" 2>/dev/null | grep -q .; then
        echo "❌ Arquivos sensíveis encontrados: $pattern"
        find . -name "$pattern" -not -path "./.git/*" -not -path "./backup_*/*" 2>/dev/null
        ((ISSUES++))
    fi
done

echo "🔍 Verificando secrets hardcoded..."
if grep -r -E -i "(password|secret|api_key|token).*=.*["'][^"']{8,}["']" \
   --include="*.go" --include="*.yml" --include="*.yaml" . 2>/dev/null | \
   grep -v ".env.example" | grep -q .; then
    echo "⚠️  Possíveis secrets hardcoded:"
    grep -r -E -i "(password|secret|api_key|token).*=.*["'][^"']{8,}["']" \
        --include="*.go" --include="*.yml" --include="*.yaml" . 2>/dev/null | \
        grep -v ".env.example" | head -5
    ((ISSUES++))
fi

echo "🔍 Verificando vulnerabilidades..."
if command -v govulncheck >/dev/null 2>&1; then
    govulncheck ./... || echo "⚠️  Vulnerabilidades encontradas"
else
    echo "⚠️  govulncheck não disponível"
fi

echo ""
if [[ $ISSUES -eq 0 ]]; then
    echo "✅ VERIFICAÇÃO APROVADA!"
    echo "🛡️  Nenhum problema crítico encontrado"
else
    echo "❌ $ISSUES PROBLEMA(S) ENCONTRADO(S)"
    echo "🔧 Revise os itens acima"
fi

echo ""
echo "🛡️  Dicas de Segurança:"
echo "  • Use .env.example como template"
echo "  • Configure secrets no deploy"
echo "  • Execute este script regularmente"
echo "  • Mantenha dependências atualizadas"
