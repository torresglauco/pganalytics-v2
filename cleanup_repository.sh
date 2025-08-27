#!/bin/bash

echo "🧹 PGAnalytics v2 - Script de Limpeza do Repositório"
echo "=================================================="
echo ""

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    log_error "Execute este script no diretório raiz do projeto PGAnalytics v2"
    exit 1
fi

log_info "Iniciando limpeza do repositório..."

# ===========================================
# FASE 1: BACKUP DE SEGURANÇA
# ===========================================
echo ""
log_info "FASE 1: Criando backup de segurança antes da limpeza..."

CLEANUP_BACKUP="cleanup_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$CLEANUP_BACKUP"

# Listar arquivos que serão removidos
echo "Arquivos que serão removidos:" > "$CLEANUP_BACKUP/removed_files.txt"

log_success "Backup de segurança criado: $CLEANUP_BACKUP"

# ===========================================
# FASE 2: REMOVER ARQUIVOS DOCKER-COMPOSE DESNECESSÁRIOS
# ===========================================
echo ""
log_info "FASE 2: Removendo arquivos Docker Compose desnecessários..."

declare -a docker_files=(
    "docker-compose.yml.backup"
    "docker-compose.yml.bak"
    "docker-compose.yml.bak2"
    "docker-compose.backup.yml"
    "docker-compose.broken.yml"
    "docker-compose.manual-backup.yml"
    "docker-compose.simple.yml"
)

for file in "${docker_files[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$CLEANUP_BACKUP/" 2>/dev/null
        echo "$file" >> "$CLEANUP_BACKUP/removed_files.txt"
        rm "$file"
        log_success "Removido: $file"
    fi
done

# ===========================================
# FASE 3: REMOVER DIRETÓRIO DE BACKUP
# ===========================================
echo ""
log_info "FASE 3: Removendo diretório de backup antigo..."

if [ -d "backup_20250827_093756" ]; then
    cp -r "backup_20250827_093756" "$CLEANUP_BACKUP/" 2>/dev/null
    echo "backup_20250827_093756/" >> "$CLEANUP_BACKUP/removed_files.txt"
    rm -rf "backup_20250827_093756"
    log_success "Removido: backup_20250827_093756/"
else
    log_info "Diretório backup_20250827_093756 não encontrado"
fi

# ===========================================
# FASE 4: REMOVER ARQUIVOS SQL DUPLICADOS
# ===========================================
echo ""
log_info "FASE 4: Verificando arquivos SQL duplicados..."

if [ -f "init-db.sql" ]; then
    cp "init-db.sql" "$CLEANUP_BACKUP/" 2>/dev/null
    echo "init-db.sql" >> "$CLEANUP_BACKUP/removed_files.txt"
    rm "init-db.sql"
    log_success "Removido: init-db.sql"
fi

if [ -f "init-postgres.sql" ]; then
    cp "init-postgres.sql" "$CLEANUP_BACKUP/" 2>/dev/null
    echo "init-postgres.sql" >> "$CLEANUP_BACKUP/removed_files.txt"
    rm "init-postgres.sql"
    log_success "Removido: init-postgres.sql"
fi

# ===========================================
# FASE 5: REMOVER ARQUIVOS ENV DUPLICADOS
# ===========================================
echo ""
log_info "FASE 5: Removendo arquivos .env duplicados..."

if [ -f "env.example" ]; then
    cp "env.example" "$CLEANUP_BACKUP/" 2>/dev/null
    echo "env.example" >> "$CLEANUP_BACKUP/removed_files.txt"
    rm "env.example"
    log_success "Removido: env.example (duplicado de .env.example)"
fi

# ===========================================
# FASE 6: CORRIGIR ARQUIVO GITIGNORE
# ===========================================
echo ""
log_info "FASE 6: Corrigindo arquivo gitignore..."

if [ -f "gitignore" ] && [ -f ".gitignore" ]; then
    cp "gitignore" "$CLEANUP_BACKUP/" 2>/dev/null
    echo "gitignore" >> "$CLEANUP_BACKUP/removed_files.txt"
    rm "gitignore"
    log_success "Removido: gitignore (sem ponto - mantendo .gitignore)"
elif [ -f "gitignore" ] && [ ! -f ".gitignore" ]; then
    mv "gitignore" ".gitignore"
    log_success "Renomeado: gitignore → .gitignore"
fi

# ===========================================
# FASE 7: VERIFICAR ARQUIVO .env SENSÍVEL
# ===========================================
echo ""
log_info "FASE 7: Verificando arquivo .env sensível..."

if [ -f ".env" ]; then
    log_warning "⚠️  ATENÇÃO: Arquivo .env encontrado no repositório!"
    echo ""
    echo "O arquivo .env contém credenciais sensíveis e NÃO deveria estar no Git."
    echo ""
    read -p "Deseja remover .env do repositório? [y/N]: " remove_env
    
    if [[ $remove_env =~ ^[Yy]$ ]]; then
        cp ".env" "$CLEANUP_BACKUP/" 2>/dev/null
        echo ".env" >> "$CLEANUP_BACKUP/removed_files.txt"
        rm ".env"
        log_success "Arquivo .env removido do repositório"
        
        # Adicionar .env ao .gitignore se não estiver
        if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
            echo "" >> .gitignore
            echo "# Environment files" >> .gitignore
            echo ".env" >> .gitignore
            log_success "Adicionado .env ao .gitignore"
        fi
        
        log_warning "IMPORTANTE: Recrie o arquivo .env localmente com:"
        log_warning "cp .env.example .env"
        log_warning "E configure suas credenciais locais."
    else
        log_warning "Arquivo .env mantido (mas deveria ser removido)"
    fi
else
    log_info "Arquivo .env não encontrado (correto)"
fi

# ===========================================
# FASE 8: VERIFICAR DIRETÓRIO MONITORING
# ===========================================
echo ""
log_info "FASE 8: Verificando diretório monitoring..."

if [ -d "monitoring" ]; then
    if [ -z "$(ls -A monitoring)" ]; then
        echo "monitoring/ (vazio)" >> "$CLEANUP_BACKUP/removed_files.txt"
        rmdir "monitoring"
        log_success "Removido diretório monitoring vazio"
    else
        log_info "Diretório monitoring contém arquivos - mantendo"
    fi
else
    log_info "Diretório monitoring não encontrado"
fi

# ===========================================
# FASE 9: ATUALIZAR .gitignore
# ===========================================
echo ""
log_info "FASE 9: Atualizando .gitignore..."

# Verificar se .gitignore tem todas as entradas necessárias
cat > .gitignore_updated << 'EOF'
# Environment files
.env
.env.local
.env.*.local

# Dependencies
node_modules/
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv/
pip-log.txt
pip-delete-this-directory.txt

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Build artifacts
dist/
build/
*.egg-info/
.coverage
.pytest_cache/

# Docker
.dockerignore

# Logs
*.log
logs/

# Temporary files
*.tmp
*.temp
.cache/

# Backup files
*.backup
*.bak
*.old

# Local database
*.db
*.sqlite
*.sqlite3

# Frontend specific
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.next/
.nuxt/
.vuepress/dist

# Backend specific
*.pyc
__pycache__/
instance/
.webassets-cache

# Monitoring
prometheus_data/
grafana_data/
EOF

# Backup do .gitignore atual se existir
if [ -f ".gitignore" ]; then
    cp ".gitignore" "$CLEANUP_BACKUP/.gitignore.backup"
fi

mv .gitignore_updated .gitignore
log_success "Arquivo .gitignore atualizado"

# ===========================================
# FASE 10: ESTATÍSTICAS FINAIS
# ===========================================
echo ""
log_info "FASE 10: Gerando estatísticas da limpeza..."

files_removed=$(wc -l < "$CLEANUP_BACKUP/removed_files.txt" 2>/dev/null || echo "0")

echo ""
log_success "🎉 Limpeza do repositório concluída!"
echo ""
echo "📊 ESTATÍSTICAS DA LIMPEZA:"
echo "==========================="
echo "• Arquivos removidos: $files_removed"
echo "• Backup criado em: $CLEANUP_BACKUP"
echo "• .gitignore atualizado"
echo ""
echo "📋 ARQUIVOS REMOVIDOS:"
echo "====================="
if [ -f "$CLEANUP_BACKUP/removed_files.txt" ]; then
    cat "$CLEANUP_BACKUP/removed_files.txt"
else
    echo "Nenhum arquivo foi removido"
fi

echo ""
echo "✅ ESTRUTURA FINAL RECOMENDADA:"
echo "==============================="
echo "pganalytics-v2/"
echo "├── backend/              # API FastAPI"
echo "├── frontend/             # App React"
echo "├── monitoring/           # Prometheus/Grafana (se usado)"
echo "├── docker-compose.yml    # Configuração Docker"
echo "├── .env.example          # Template de variáveis"
echo "├── .gitignore           # Arquivos ignorados"
echo "├── README.md            # Documentação"
echo "├── Makefile             # Comandos úteis"
echo "└── LICENSE              # Licença (recomendado)"

echo ""
log_warning "🔧 PRÓXIMOS PASSOS RECOMENDADOS:"
echo "1. Recrie o arquivo .env: cp .env.example .env"
echo "2. Configure suas credenciais no .env"
echo "3. Teste a aplicação: docker-compose up -d"
echo "4. Commit das mudanças: git add . && git commit -m 'Clean up repository'"
echo "5. Push para o GitHub: git push origin main"

echo ""
log_info "📁 Backup dos arquivos removidos: $CLEANUP_BACKUP"
log_warning "Mantenha este backup até confirmar que tudo está funcionando!"
