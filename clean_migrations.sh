#!/bin/bash
echo "🧹 LIMPANDO E REORGANIZANDO MIGRAÇÕES"

MIGRATIONS_DIR="./migrations"

echo "📊 1. Analisando arquivos de migração..."

# Backup do diretório atual
if [ -d "$MIGRATIONS_DIR" ]; then
    BACKUP_DIR="migrations_backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$MIGRATIONS_DIR" "$BACKUP_DIR"
    echo "  💾 Backup criado: $BACKUP_DIR"
fi

echo ""
echo "🔍 2. Removendo migrações duplicadas e incorretas..."

cd "$MIGRATIONS_DIR" || exit 1

# Remover arquivos com nomes incorretos
echo "  🗑️ Removendo arquivos _v0..."
rm -f *_v0.sql
rm -f 001_initial_schema.up.sql 2>/dev/null  # Duplicata
rm -f 004_insert_default_users.up.sql 2>/dev/null  # Duplicata

echo ""
echo "📋 3. Listando migrações finais..."
echo "  📊 Arquivos UP:"
ls -1 *.up.sql 2>/dev/null | sort | sed 's/^/    ✅ /' || echo "    ❌ Nenhum arquivo .up.sql"

echo "  📊 Arquivos DOWN:"
ls -1 *.down.sql 2>/dev/null | sort | sed 's/^/    ✅ /' || echo "    ❌ Nenhum arquivo .down.sql"

cd - >/dev/null

echo ""
echo "✅ Limpeza concluída!"
echo "📋 Para executar migrações: bash migrations.sh up"
