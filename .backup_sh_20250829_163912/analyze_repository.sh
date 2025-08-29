#!/bin/bash

echo "🔍 ANÁLISE DO REPOSITÓRIO - BRANCH OAUTH"
echo "========================================"

# 1. Analisar estrutura atual
echo ""
echo "📁 ESTRUTURA ATUAL DO REPOSITÓRIO:"
echo "=================================="

# Listar estrutura principal
echo "🗂️ Arquivos na raiz:"
ls -la | grep -E "^-" | awk '{print "  • " $9}' | head -20

echo ""
echo "📂 Diretórios principais:"
ls -la | grep -E "^d" | awk '{print "  • " $9}' | grep -v "^\.\.$\|^\.$"

# 2. Identificar arquivos desnecessários
echo ""
echo "🧹 ARQUIVOS DESNECESSÁRIOS IDENTIFICADOS:"
echo "========================================="

echo ""
echo "❌ Scripts de desenvolvimento/teste (manter apenas essenciais):"
ls -la *.sh 2>/dev/null | grep -E "(test|fix|debug|setup|install|analyze|integrate|validate)" | awk '{print "  • " $9}' || echo "  Nenhum encontrado"

echo ""
echo "❌ Backups e arquivos temporários:"
ls -la | grep -E "(backup|tmp|temp|\.bak|\.old|\.broken)" | awk '{print "  • " $9}' || echo "  Nenhum encontrado"

echo ""
echo "❌ Logs e arquivos de saída:"
ls -la *.log *.out 2>/dev/null | awk '{print "  • " $1}' || echo "  Nenhum encontrado"

echo ""
echo "❌ READMEs duplicados:"
ls -la README* 2>/dev/null | grep -v "^.*README\.md$" | awk '{print "  • " $9}' || echo "  Nenhum encontrado"

echo ""
echo "❌ Dockerfiles duplicados:"
ls -la Dockerfile* 2>/dev/null | grep -v "^.*Dockerfile$\|^.*Dockerfile\.dev$" | awk '{print "  • " $9}' || echo "  Nenhum encontrado"

echo ""
echo "❌ Docker-compose duplicados:"
ls -la docker-compose* 2>/dev/null | grep -v "^.*docker-compose\.yml$" | awk '{print "  • " $9}' || echo "  Nenhum encontrado"

# 3. Verificar diretórios internos desnecessários
echo ""
echo "🔍 DIRETÓRIOS INTERNOS A VERIFICAR:"
echo "=================================="

if [ -d "internal" ]; then
    echo "📂 internal/:"
    find internal/ -type d | sed 's/^/  • /'
    
    echo ""
    echo "📄 Arquivos em internal/:"
    find internal/ -name "*.go" | sed 's/^/  • /'
fi

if [ -d ".backup_working_jwt" ]; then
    echo ""
    echo "❌ Backup directory encontrado: .backup_working_jwt/"
    ls -la .backup_working_jwt/ | grep -E "^-" | awk '{print "  • " $9}'
fi

# 4. Verificar arquivos de configuração
echo ""
echo "⚙️ ARQUIVOS DE CONFIGURAÇÃO:"
echo "============================"

echo "✅ Essenciais (manter):"
for file in "go.mod" "go.sum" ".env.example" "Dockerfile" "Dockerfile.dev" "docker-compose.yml" "README.md" "Makefile" ".gitignore"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (não encontrado)"
    fi
done

echo ""
echo "❓ Opcionais (avaliar):"
for file in "docker-compose.prod.yml" ".air.toml" ".dockerignore"; do
    if [ -f "$file" ]; then
        echo "  ❓ $file"
    fi
done

# 5. Sugerir estrutura limpa
echo ""
echo "🎯 ESTRUTURA RECOMENDADA (LIMPA):"
echo "================================="
echo "pganalytics-v2/"
echo "├── cmd/"
echo "│   └── server/"
echo "│       └── main.go"
echo "├── internal/"
echo "│   ├── handlers/"
echo "│   │   ├── auth.go"
echo "│   │   └── metrics.go"
echo "│   ├── middleware/"
echo "│   │   └── auth.go"
echo "│   └── models/"
echo "│       └── models.go"
echo "├── migrations/"
echo "│   └── (SQL files if needed)"
echo "├── docs/"
echo "│   └── (documentation if needed)"
echo "├── .env.example"
echo "├── .gitignore"
echo "├── .dockerignore"
echo "├── Dockerfile"
echo "├── Dockerfile.dev"
echo "├── docker-compose.yml"
echo "├── go.mod"
echo "├── go.sum"
echo "├── Makefile"
echo "└── README.md"

echo ""
echo "✅ ANÁLISE CONCLUÍDA!"
echo ""
echo "🚀 Próximo passo: Execute cleanup_repository.sh para limpeza"
