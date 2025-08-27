#!/bin/bash
echo "🔍 INSPEÇÃO DETALHADA DO ERRO docs.go"

echo "📋 Verificando linha 40 específica (onde está o erro):"
if [ -f docs/docs.go ]; then
    echo "=== LINHA 40 (com caracteres especiais visíveis) ==="
    sed -n '40p' docs/docs.go | cat -A
    echo ""
    echo "=== LINHAS 39-42 (contexto) ==="
    sed -n '39,42p' docs/docs.go | nl -ba
    echo ""
    echo "=== PROCURANDO PROBLEMAS ESPECÍFICOS ==="
    
    # Verifica strings não fechadas
    if grep -n '`[^`]*$' docs/docs.go >/dev/null; then
        echo "❌ String com backtick não fechada:"
        grep -n '`[^`]*$' docs/docs.go
    fi
    
    # Verifica quebras de linha em strings
    if awk '/`/{flag=1} flag && /[^`]*$/ && !/`$/{print NR ": " $0}' docs/docs.go >/dev/null; then
        echo "❌ Quebras de linha em template string:"
        awk '/`/{flag=1} flag && /[^`]*$/ && !/`$/{print NR ": " $0}' docs/docs.go
    fi
    
    # Procura caracteres de escape problemáticos
    if grep -n '\\\\' docs/docs.go >/dev/null; then
        echo "❌ Caracteres de escape duplicados:"
        grep -n '\\\\' docs/docs.go
    fi
else
    echo "❌ docs/docs.go não encontrado"
fi

echo ""
echo "🔧 Para corrigir execute:"
echo "bash complete_swagger_solution.sh"
