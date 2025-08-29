#!/bin/bash

echo "💥 REMOÇÃO NUCLEAR DE SCRIPTS .SH DESNECESSÁRIOS"
echo "=============================================="

# Verificar diretório
if [ ! -f "go.mod" ]; then
    echo "❌ Execute no diretório raiz do projeto"
    exit 1
fi

# Listar TODOS os scripts .sh
echo "🔍 Scripts .sh encontrados:"
ls -la *.sh 2>/dev/null | awk '{print "  • " $9}' || echo "  Nenhum script encontrado"

# Scripts a MANTER (whitelist muito restrita)
KEEP_WHITELIST=(
    "start.sh"
    "deploy.sh" 
    "build.sh"
    "run.sh"
)

echo ""
echo "✅ Scripts que serão MANTIDOS (whitelist):"
for script in "${KEEP_WHITELIST[@]}"; do
    if [ -f "$script" ]; then
        echo "  ✅ $script"
    fi
done

echo ""
echo "❌ Scripts que serão REMOVIDOS:"

# Encontrar scripts para remover (todos exceto whitelist)
TO_REMOVE=""
for script in *.sh; do
    # Verificar se o arquivo existe
    if [ ! -f "$script" ]; then
        continue
    fi
    
    # Verificar se está na whitelist
    KEEP=false
    for keep_script in "${KEEP_WHITELIST[@]}"; do
        if [ "$script" = "$keep_script" ]; then
            KEEP=true
            break
        fi
    done
    
    # Se não está na whitelist, remover
    if [ "$KEEP" = "false" ]; then
        echo "  ❌ $script"
        TO_REMOVE="$TO_REMOVE $script"
    fi
done

if [ -z "$TO_REMOVE" ]; then
    echo "  ✅ Nenhum script para remover"
    exit 0
fi

# Contar scripts
REMOVE_COUNT=$(echo $TO_REMOVE | wc -w)

echo ""
echo "📊 Total para remoção: $REMOVE_COUNT scripts"

# Confirmação
echo ""
read -p "💥 REMOVER TODOS os $REMOVE_COUNT scripts? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada"
    exit 1
fi

# Backup rápido
BACKUP_DIR=".nuclear_scripts_backup_$(date +%Y%m%d_%H%M%S)"
echo ""
echo "💾 Backup em: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Fazer backup e remover
echo ""
echo "💥 REMOVENDO SCRIPTS..."

REMOVED=0
for script in $TO_REMOVE; do
    if [ -f "$script" ]; then
        # Backup
        cp "$script" "$BACKUP_DIR/"
        # Remover
        rm -f "$script"
        echo "  💥 REMOVIDO: $script"
        REMOVED=$((REMOVED + 1))
    fi
done

echo ""
echo "✅ REMOÇÃO NUCLEAR CONCLUÍDA!"
echo "============================"
echo "💥 Scripts removidos: $REMOVED"
echo "💾 Backup em: $BACKUP_DIR"

# Verificar o que sobrou
echo ""
echo "📄 Scripts restantes:"
REMAINING=$(ls *.sh 2>/dev/null || true)
if [ ! -z "$REMAINING" ]; then
    echo "$REMAINING" | sed 's/^/  ✅ /'
else
    echo "  🎉 NENHUM SCRIPT .SH RESTANTE!"
fi

echo ""
echo "🧹 REPOSITÓRIO LIMPO!"
echo ""
echo "📋 Para finalizar:"
echo "   git add ."
echo "   git commit -m \"Nuclear cleanup: remove all dev scripts\""
echo "   git status"
