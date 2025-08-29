#!/bin/bash

echo "🧹 LIMPEZA DO REPOSITÓRIO - REMOVENDO DESNECESSÁRIOS"
echo "=================================================="

# Verificar se estamos no diretório correto
if [ ! -f "go.mod" ]; then
    echo "❌ Execute no diretório raiz do projeto (onde está go.mod)"
    exit 1
fi

# Fazer backup antes da limpeza
echo "💾 Criando backup de segurança..."
BACKUP_DIR=".cleanup_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Listar o que será removido
echo ""
echo "📋 ARQUIVOS QUE SERÃO REMOVIDOS:"
echo "==============================="

TO_REMOVE=""

# 1. Scripts de desenvolvimento/teste (manter apenas os essenciais)
echo ""
echo "🔧 Scripts de desenvolvimento/teste:"
SCRIPTS_TO_REMOVE=$(ls *.sh 2>/dev/null | grep -E "(analyze|integrate|test|fix|debug|setup|install|validate|cleanup|emergency|nuclear|final|perfect|ultimate)" || true)
if [ ! -z "$SCRIPTS_TO_REMOVE" ]; then
    echo "$SCRIPTS_TO_REMOVE" | sed 's/^/  ❌ /'
    TO_REMOVE="$TO_REMOVE $SCRIPTS_TO_REMOVE"
else
    echo "  ✅ Nenhum script desnecessário encontrado"
fi

# 2. Backups e arquivos temporários
echo ""
echo "💾 Backups e arquivos temporários:"
BACKUP_FILES=$(ls -la | grep -E "(backup|tmp|temp|\.bak|\.old|\.broken)" | awk '{print $9}' || true)
if [ ! -z "$BACKUP_FILES" ]; then
    echo "$BACKUP_FILES" | sed 's/^/  ❌ /'
    TO_REMOVE="$TO_REMOVE $BACKUP_FILES"
else
    echo "  ✅ Nenhum backup/temp encontrado"
fi

# 3. Logs e arquivos de saída
echo ""
echo "📄 Logs e arquivos de saída:"
LOG_FILES=$(ls *.log *.out 2>/dev/null || true)
if [ ! -z "$LOG_FILES" ]; then
    echo "$LOG_FILES" | sed 's/^/  ❌ /'
    TO_REMOVE="$TO_REMOVE $LOG_FILES"
else
    echo "  ✅ Nenhum log encontrado"
fi

# 4. READMEs duplicados (manter apenas README.md)
echo ""
echo "📖 READMEs duplicados:"
README_DUPLICATES=$(ls README* 2>/dev/null | grep -v "^README\.md$" || true)
if [ ! -z "$README_DUPLICATES" ]; then
    echo "$README_DUPLICATES" | sed 's/^/  ❌ /'
    TO_REMOVE="$TO_REMOVE $README_DUPLICATES"
else
    echo "  ✅ Apenas README.md encontrado"
fi

# 5. Dockerfiles duplicados
echo ""
echo "🐳 Dockerfiles duplicados:"
DOCKERFILE_DUPLICATES=$(ls Dockerfile* 2>/dev/null | grep -v "^Dockerfile$\|^Dockerfile\.dev$" || true)
if [ ! -z "$DOCKERFILE_DUPLICATES" ]; then
    echo "$DOCKERFILE_DUPLICATES" | sed 's/^/  ❌ /'
    TO_REMOVE="$TO_REMOVE $DOCKERFILE_DUPLICATES"
else
    echo "  ✅ Apenas Dockerfile e Dockerfile.dev encontrados"
fi

# 6. Docker-compose duplicados
echo ""
echo "🐙 Docker-compose duplicados:"
COMPOSE_DUPLICATES=$(ls docker-compose* 2>/dev/null | grep -v "^docker-compose\.yml$\|^docker-compose\.prod\.yml$" || true)
if [ ! -z "$COMPOSE_DUPLICATES" ]; then
    echo "$COMPOSE_DUPLICATES" | sed 's/^/  ❌ /'
    TO_REMOVE="$TO_REMOVE $COMPOSE_DUPLICATES"
else
    echo "  ✅ Apenas docker-compose.yml encontrado"
fi

# 7. Diretórios de backup
echo ""
echo "📂 Diretórios desnecessários:"
BACKUP_DIRS=$(ls -la | grep -E "^d.*backup" | awk '{print $9}' || true)
if [ ! -z "$BACKUP_DIRS" ]; then
    echo "$BACKUP_DIRS" | sed 's/^/  ❌ /'
    TO_REMOVE="$TO_REMOVE $BACKUP_DIRS"
else
    echo "  ✅ Nenhum diretório de backup encontrado"
fi

# 8. Arquivos específicos desnecessários
echo ""
echo "📄 Outros arquivos específicos:"
OTHER_FILES=""
for file in "main.go.broken.*" "main.go.pre_*" "*.zip" "*.tar.gz" "ANALYSIS_*" "INTEGRATION_*" "TROUBLESHOOTING.md" "SUCCESS_DOCUMENTATION.md"; do
    if ls $file 1> /dev/null 2>&1; then
        OTHER_FILES="$OTHER_FILES $(ls $file)"
    fi
done

if [ ! -z "$OTHER_FILES" ]; then
    echo "$OTHER_FILES" | tr ' ' '\n' | sed 's/^/  ❌ /'
    TO_REMOVE="$TO_REMOVE $OTHER_FILES"
else
    echo "  ✅ Nenhum arquivo específico desnecessário encontrado"
fi

# Confirmar limpeza
echo ""
echo "⚠️ CONFIRMAÇÃO DE LIMPEZA:"
echo "========================="

if [ -z "$TO_REMOVE" ]; then
    echo "✅ Nenhum arquivo desnecessário encontrado!"
    echo "🎉 Repositório já está limpo!"
    exit 0
fi

echo "📊 Total de itens para remover: $(echo $TO_REMOVE | wc -w)"
echo ""
read -p "🤔 Confirmar limpeza? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Limpeza cancelada pelo usuário"
    rm -rf "$BACKUP_DIR"
    exit 1
fi

# Fazer backup dos arquivos que serão removidos
echo ""
echo "💾 Fazendo backup dos arquivos..."
for item in $TO_REMOVE; do
    if [ -e "$item" ]; then
        cp -r "$item" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# Executar limpeza
echo ""
echo "🧹 Executando limpeza..."
REMOVED_COUNT=0

for item in $TO_REMOVE; do
    if [ -e "$item" ]; then
        echo "  🗑️ Removendo: $item"
        rm -rf "$item"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
done

# Limpar diretórios vazios
echo ""
echo "📁 Removendo diretórios vazios..."
find . -type d -empty -delete 2>/dev/null || true

# Relatório final
echo ""
echo "✅ LIMPEZA CONCLUÍDA!"
echo "==================="
echo "📊 Itens removidos: $REMOVED_COUNT"
echo "💾 Backup salvo em: $BACKUP_DIR"

# Verificar estrutura final
echo ""
echo "🏗️ ESTRUTURA FINAL:"
echo "=================="
echo "📂 Diretórios:"
find . -type d -not -path "./.git*" -not -path "./$BACKUP_DIR*" | head -10 | sed 's/^/  /'

echo ""
echo "📄 Arquivos principais na raiz:"
ls -la | grep -E "^-.*\.(md|yml|yaml|mod|sum|go|toml|ignore|example)$" | awk '{print "  • " $9}'

echo ""
echo "🎯 REPOSITÓRIO LIMPO E ORGANIZADO!"
echo ""
echo "🚀 Próximo passo: Commit das mudanças"
echo "   git add ."
echo "   git commit -m \"Clean repository - remove unnecessary files\""
echo "   git push origin oauth"
