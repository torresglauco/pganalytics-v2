#!/bin/bash

echo "🗑️ REMOVENDO SCRIPTS DE DESENVOLVIMENTO DESNECESSÁRIOS"
echo "===================================================="

# Verificar se estamos no diretório correto
if [ ! -f "go.mod" ]; then
    echo "❌ Execute no diretório raiz do projeto (onde está go.mod)"
    exit 1
fi

# Lista de padrões de scripts a remover
SCRIPT_PATTERNS=(
    "*analyze*"
    "*integrate*" 
    "*test*"
    "*fix*"
    "*debug*"
    "*setup*"
    "*install*"
    "*validate*"
    "*cleanup*"
    "*emergency*"
    "*nuclear*"
    "*final*"
    "*perfect*"
    "*ultimate*"
    "*complete*"
    "*check*"
    "*diagnosis*"
    "*migrate*"
    "*organize*"
    "*update*"
    "*create*"
)

# Scripts específicos a manter (whitelist)
KEEP_SCRIPTS=(
    "start.sh"
    "deploy.sh"
    "build.sh"
)

echo "🔍 Procurando scripts .sh desnecessários..."
echo ""

# Listar todos os scripts .sh
ALL_SCRIPTS=$(ls *.sh 2>/dev/null || true)

if [ -z "$ALL_SCRIPTS" ]; then
    echo "✅ Nenhum script .sh encontrado"
    exit 0
fi

echo "📋 Scripts encontrados:"
echo "$ALL_SCRIPTS" | sed 's/^/  • /'

echo ""
echo "🎯 Identificando scripts a remover..."

TO_REMOVE=""

# Verificar cada script contra os padrões
for script in $ALL_SCRIPTS; do
    SHOULD_REMOVE=false
    
    # Verificar se está na whitelist (manter)
    KEEP=false
    for keep_script in "${KEEP_SCRIPTS[@]}"; do
        if [ "$script" = "$keep_script" ]; then
            KEEP=true
            break
        fi
    done
    
    if [ "$KEEP" = "true" ]; then
        echo "  ✅ Mantendo: $script (whitelist)"
        continue
    fi
    
    # Verificar contra padrões de remoção
    for pattern in "${SCRIPT_PATTERNS[@]}"; do
        if [[ $script == $pattern.sh ]] || [[ $script == $pattern ]]; then
            SHOULD_REMOVE=true
            break
        fi
    done
    
    if [ "$SHOULD_REMOVE" = "true" ]; then
        echo "  ❌ Marcado para remoção: $script"
        TO_REMOVE="$TO_REMOVE $script"
    else
        echo "  ❓ Mantendo: $script (não corresponde aos padrões)"
    fi
done

# Verificar se há scripts para remover
if [ -z "$TO_REMOVE" ]; then
    echo ""
    echo "✅ Nenhum script desnecessário encontrado!"
    exit 0
fi

# Mostrar resumo
echo ""
echo "📊 RESUMO:"
echo "========="
REMOVE_COUNT=$(echo $TO_REMOVE | wc -w)
echo "📄 Scripts a remover: $REMOVE_COUNT"
echo "🗑️ Lista completa:"
echo "$TO_REMOVE" | tr ' ' '\n' | sed 's/^/  • /'

# Confirmar remoção
echo ""
read -p "🤔 Confirmar remoção de $REMOVE_COUNT scripts? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Remoção cancelada pelo usuário"
    exit 1
fi

# Fazer backup antes de remover
BACKUP_DIR=".scripts_backup_$(date +%Y%m%d_%H%M%S)"
echo ""
echo "💾 Criando backup em: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

for script in $TO_REMOVE; do
    if [ -f "$script" ]; then
        cp "$script" "$BACKUP_DIR/"
    fi
done

# Executar remoção
echo ""
echo "🗑️ Removendo scripts..."
REMOVED=0

for script in $TO_REMOVE; do
    if [ -f "$script" ]; then
        echo "  🗑️ Removendo: $script"
        rm -f "$script"
        REMOVED=$((REMOVED + 1))
    else
        echo "  ⚠️ Não encontrado: $script"
    fi
done

# Verificar resultado
echo ""
echo "✅ REMOÇÃO CONCLUÍDA!"
echo "==================="
echo "📊 Scripts removidos: $REMOVED"
echo "💾 Backup salvo em: $BACKUP_DIR"

# Mostrar scripts restantes
REMAINING_SCRIPTS=$(ls *.sh 2>/dev/null || true)
if [ ! -z "$REMAINING_SCRIPTS" ]; then
    echo ""
    echo "📄 Scripts restantes:"
    echo "$REMAINING_SCRIPTS" | sed 's/^/  ✅ /'
else
    echo ""
    echo "🎉 Nenhum script .sh restante!"
fi

echo ""
echo "🚀 Pronto para commit:"
echo "   git add ."
echo "   git commit -m \"Remove development scripts\""
