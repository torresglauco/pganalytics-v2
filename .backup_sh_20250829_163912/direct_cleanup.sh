#!/bin/bash

echo "🧹 LIMPEZA DIRETA DE SCRIPTS .SH"
echo "==============================="

# Comando direto para remover scripts por padrão
echo "💥 Removendo scripts de desenvolvimento..."

# Fazer backup primeiro
mkdir -p .backup_sh_$(date +%Y%m%d_%H%M%S)
cp *.sh .backup_sh_$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true

# Remover diretamente por padrão
rm -f *analyze*.sh 2>/dev/null
rm -f *integrate*.sh 2>/dev/null  
rm -f *test*.sh 2>/dev/null
rm -f *fix*.sh 2>/dev/null
rm -f *debug*.sh 2>/dev/null
rm -f *setup*.sh 2>/dev/null
rm -f *install*.sh 2>/dev/null
rm -f *validate*.sh 2>/dev/null
rm -f *cleanup*.sh 2>/dev/null
rm -f *emergency*.sh 2>/dev/null
rm -f *nuclear*.sh 2>/dev/null
rm -f *final*.sh 2>/dev/null
rm -f *perfect*.sh 2>/dev/null
rm -f *ultimate*.sh 2>/dev/null
rm -f *complete*.sh 2>/dev/null
rm -f *check*.sh 2>/dev/null
rm -f *diagnosis*.sh 2>/dev/null
rm -f *migrate*.sh 2>/dev/null
rm -f *organize*.sh 2>/dev/null
rm -f *update*.sh 2>/dev/null
rm -f *create*.sh 2>/dev/null
rm -f *master*.sh 2>/dev/null
rm -f *force*.sh 2>/dev/null
rm -f *ensure*.sh 2>/dev/null
rm -f *discover*.sh 2>/dev/null
rm -f *improve*.sh 2>/dev/null
rm -f *rollback*.sh 2>/dev/null
rm -f *grant*.sh 2>/dev/null
rm -f *postgres*.sh 2>/dev/null
rm -f *swift*.sh 2>/dev/null
rm -f *macos*.sh 2>/dev/null
rm -f *docker*.sh 2>/dev/null
rm -f *correct*.sh 2>/dev/null
rm -f *simple*.sh 2>/dev/null
rm -f *quick*.sh 2>/dev/null
rm -f *targeted*.sh 2>/dev/null
rm -f *safe*.sh 2>/dev/null
rm -f *clean*.sh 2>/dev/null
rm -f *permission*.sh 2>/dev/null

echo "✅ Scripts de desenvolvimento removidos!"

# Mostrar o que sobrou
echo ""
echo "📄 Scripts restantes:"
ls *.sh 2>/dev/null | sed 's/^/  ✅ /' || echo "  🎉 Nenhum script .sh restante!"

echo ""
echo "🗑️ Outros arquivos desnecessários..."

# Remover outros arquivos desnecessários
rm -f *.log 2>/dev/null
rm -f *.out 2>/dev/null  
rm -f main.go.broken.* 2>/dev/null
rm -f main.go.pre_* 2>/dev/null
rm -f README_*.md 2>/dev/null
rm -f SUCCESS_*.md 2>/dev/null
rm -f ANALYSIS_*.md 2>/dev/null
rm -f INTEGRATION_*.md 2>/dev/null
rm -f TROUBLESHOOTING.md 2>/dev/null
rm -f *.zip 2>/dev/null
rm -f *.tar.gz 2>/dev/null

# Remover diretórios de backup
rm -rf .backup_working_jwt/ 2>/dev/null
rm -rf *backup*/ 2>/dev/null

echo "✅ Arquivos desnecessários removidos!"

echo ""
echo "🎯 LIMPEZA CONCLUÍDA!"
echo "==================="
echo "📊 Repositório limpo e organizado"
echo ""
echo "📋 Estrutura final:"
find . -maxdepth 2 -type f -name "*.go" -o -name "*.md" -o -name "*.yml" -o -name "*.mod" -o -name "Dockerfile*" -o -name "Makefile" | grep -v ".git" | sort

echo ""
echo "🚀 Para finalizar:"
echo "   git add ."
echo "   git commit -m \"Clean repository: remove development files\""
echo "   git push origin oauth"
