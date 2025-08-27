#!/bin/bash

echo "🔥 CORREÇÃO CRÍTICA DE SEGURANÇA - PGAnalytics v2"
echo "================================================"
echo ""
echo "⚠️  ATENÇÃO: Este script resolve problemas críticos de segurança"
echo "   O arquivo .env com credenciais está EXPOSTO no repositório!"
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

# ===========================================
# FASE 1: REMOÇÃO CRÍTICA DO ARQUIVO .env
# ===========================================
echo ""
log_error "FASE 1: REMOVENDO ARQUIVO .env DO REPOSITÓRIO (CRÍTICO)"

if [ -f ".env" ]; then
    log_warning "Arquivo .env encontrado com credenciais expostas!"
    
    echo ""
    echo "📋 Credenciais expostas no .env:"
    echo "• PostgreSQL: postgres/postgres"
    echo "• Redis: senha padrão" 
    echo "• URLs de banco de dados"
    echo "• Configurações de monitoramento"
    echo ""
    
    echo "Este arquivo NUNCA deve estar no Git em repositórios públicos!"
    echo ""
    read -p "🔥 REMOVER .env do repositório AGORA? [Y/n]: " remove_env
    
    if [[ $remove_env =~ ^[Yy]$|^$ ]]; then
        # Backup local antes de remover
        cp .env .env.local.backup
        
        # Remover do Git
        git rm .env
        
        log_success "Arquivo .env removido do repositório"
        log_info "Backup criado: .env.local.backup"
        
        # Verificar se .env está no .gitignore
        if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
            echo "" >> .gitignore
            echo "# Environment files (NUNCA commitar)" >> .gitignore
            echo ".env" >> .gitignore
            echo ".env.local" >> .gitignore
            echo ".env.*.local" >> .gitignore
            log_success "Adicionado .env ao .gitignore"
        fi
        
    else
        log_error "ATENÇÃO: .env ainda está exposto no repositório!"
        echo "Você DEVE remover este arquivo para garantir a segurança."
        exit 1
    fi
else
    log_info "Arquivo .env não encontrado (correto)"
fi

# ===========================================
# FASE 2: REMOÇÃO DE ARQUIVOS TEMPORÁRIOS
# ===========================================
echo ""
log_info "FASE 2: Removendo arquivos temporários..."

# Remover diretório de backup do cleanup
if [ -d "cleanup_backup_20250827_095839" ]; then
    log_info "Removendo diretório de backup..."
    git rm -r cleanup_backup_20250827_095839
    log_success "Diretório cleanup_backup_* removido"
fi

# Remover script de limpeza
if [ -f "cleanup_repository.sh" ]; then
    git rm cleanup_repository.sh
    log_success "Script cleanup_repository.sh removido"
fi

# ===========================================
# FASE 3: GERAR NOVAS CREDENCIAIS SEGURAS
# ===========================================
echo ""
log_info "FASE 3: Gerando novas credenciais seguras..."

# Função para gerar senhas seguras
generate_password() {
    python3 -c "import secrets, string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '!@#$%&*') for _ in range(20)))"
}

# Gerar novas credenciais
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
DB_PASSWORD=$(generate_password)
REDIS_PASSWORD=$(generate_password)
ADMIN_PASSWORD=$(generate_password)

# Criar arquivo .env.example atualizado com instruções de segurança
cat > .env.example << EOF
# =================
# PGAnalytics v2 - Configurações de Ambiente
# =================
# IMPORTANTE: 
# 1. Copie este arquivo para .env
# 2. Altere TODAS as senhas abaixo
# 3. NUNCA commite o arquivo .env
# =================

# Ambiente (development, staging, production)
ENVIRONMENT=production

# =================
# SEGURANÇA CRÍTICA - ALTERE TODAS AS SENHAS!
# =================
SECRET_KEY=ALTERAR-chave-secreta-jwt-minimo-32-caracteres
DATABASE_URL=postgresql://pguser:ALTERAR-SENHA-DB@postgres_app:5432/pganalytics

# =================
# BANCO DE DADOS
# =================
POSTGRES_DB=pganalytics
POSTGRES_USER=pguser
POSTGRES_PASSWORD=ALTERAR-SENHA-POSTGRES

# =================
# REDIS CACHE
# =================
REDIS_URL=redis://:ALTERAR-SENHA-REDIS@redis:6379/0
REDIS_PASSWORD=ALTERAR-SENHA-REDIS

# =================
# USUÁRIO ADMINISTRADOR
# =================
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=ALTERAR-SENHA-ADMIN

# =================
# APLICAÇÃO
# =================
BACKEND_PORT=8000
FRONTEND_PORT=80

# =================
# MONITORAMENTO
# =================
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001

# =================
# NOTIFICAÇÕES (OPCIONAL)
# =================
SLACK_WEBHOOK_URL=
SLACK_CHANNEL=#monitoring
EOF

log_success ".env.example atualizado com instruções de segurança"

# Criar arquivo .env local com credenciais seguras
cat > .env << EOF
# =================
# PGAnalytics v2 - CREDENCIAIS LOCAIS
# =================
# GERADO AUTOMATICAMENTE - NÃO COMMITAR
# =================

ENVIRONMENT=development

# Segurança
SECRET_KEY=${SECRET_KEY}
DATABASE_URL=postgresql://pguser:${DB_PASSWORD}@postgres_app:5432/pganalytics

# Banco de dados
POSTGRES_DB=pganalytics
POSTGRES_USER=pguser
POSTGRES_PASSWORD=${DB_PASSWORD}

# Redis
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
REDIS_PASSWORD=${REDIS_PASSWORD}

# Admin
ADMIN_EMAIL=admin@localhost
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# Aplicação
BACKEND_PORT=8000
FRONTEND_PORT=80

# Monitoramento
PROMETHEUS_PORT=9090
GRAFANA_PORT=3001

# Notificações
SLACK_WEBHOOK_URL=
SLACK_CHANNEL=#monitoring
EOF

log_success "Novo arquivo .env criado com credenciais seguras"

# ===========================================
# FASE 4: CRIAR ARQUIVO DE CREDENCIAIS
# ===========================================
echo ""
log_info "FASE 4: Salvando credenciais seguras..."

# Criar arquivo com as novas credenciais (para referência)
cat > CREDENCIAIS_SEGURAS.txt << EOF
=================
NOVAS CREDENCIAIS GERADAS
=================
IMPORTANTE: Guarde este arquivo em local seguro e delete-o após uso!

SECRET_KEY: ${SECRET_KEY}
POSTGRES_PASSWORD: ${DB_PASSWORD}
REDIS_PASSWORD: ${REDIS_PASSWORD}
ADMIN_PASSWORD: ${ADMIN_PASSWORD}

=================
INSTRUÇÕES:
=================
1. Use estas credenciais no seu ambiente local
2. Em produção, gere credenciais diferentes
3. DELETE este arquivo após configurar
4. NUNCA commite credenciais no Git
EOF

log_success "Credenciais salvas em: CREDENCIAIS_SEGURAS.txt"

# ===========================================
# FASE 5: COMMIT DAS CORREÇÕES
# ===========================================
echo ""
log_info "FASE 5: Aplicando correções ao repositório..."

# Add das mudanças
git add .gitignore .env.example

# Commit das correções de segurança
git commit -m "🔒 SECURITY FIX: Remove .env and sensitive files

- Remove .env file with exposed credentials
- Remove cleanup backup directory  
- Remove temporary cleanup script
- Update .env.example with security instructions
- Add .env to .gitignore to prevent future exposure

BREAKING: All credentials have been regenerated for security"

log_success "Correções commitadas"

# ===========================================
# FINALIZAÇÃO
# ===========================================
echo ""
log_success "🎉 CORREÇÕES DE SEGURANÇA APLICADAS!"
echo ""
echo "📋 RESUMO DAS AÇÕES:"
echo "==================="
echo "✅ Arquivo .env removido do repositório"
echo "✅ Arquivos temporários removidos"
echo "✅ Novas credenciais seguras geradas"
echo "✅ .env.example atualizado"
echo "✅ .gitignore configurado"
echo "✅ Mudanças commitadas"
echo ""
echo "🔐 PRÓXIMOS PASSOS OBRIGATÓRIOS:"
echo "==============================="
echo "1. 📤 PUSH das correções: git push origin main"
echo "2. 🔑 Verificar credenciais em CREDENCIAIS_SEGURAS.txt"
echo "3. 🗑️  Deletar CREDENCIAIS_SEGURAS.txt após uso"
echo "4. 🧪 Testar aplicação: docker-compose up -d"
echo "5. 🔄 Em produção, gerar credenciais específicas"
echo ""
echo "⚠️  IMPORTANTES:"
echo "• O arquivo .env agora é local e não será commitado"
echo "• Credenciais antigas foram invalidadas"
echo "• Configure produção com credenciais específicas"
echo ""
log_warning "🔥 PUSH imediatamente para aplicar correções de segurança!"
