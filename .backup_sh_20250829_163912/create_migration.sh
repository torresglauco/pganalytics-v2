#!/bin/bash
echo "📝 CRIADOR DE MIGRAÇÕES"

if [ -z "$1" ]; then
    echo "❌ Nome da migração é obrigatório"
    echo "Uso: $0 <nome_da_migracao>"
    echo "Exemplo: $0 add_user_preferences"
    exit 1
fi

MIGRATION_NAME="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MIGRATIONS_DIR="./migrations"

# Encontrar próximo número sequencial
LAST_NUM=$(ls $MIGRATIONS_DIR/*.up.sql 2>/dev/null | sed 's/.*\///' | sed 's/_.*$//' | sort -n | tail -1)
NEXT_NUM=$(printf "%03d" $((10#$LAST_NUM + 1)))

UP_FILE="${MIGRATIONS_DIR}/${NEXT_NUM}_${MIGRATION_NAME}.up.sql"
DOWN_FILE="${MIGRATIONS_DIR}/${NEXT_NUM}_${MIGRATION_NAME}.down.sql"

echo "📄 Criando arquivos de migração:"
echo "  📈 UP:   $UP_FILE"
echo "  📉 DOWN: $DOWN_FILE"

# Criar arquivo UP
cat > "$UP_FILE" << EOF
-- Migration: ${NEXT_NUM}_${MIGRATION_NAME}
-- Created: $(date)
-- Description: [Descreva o que esta migração faz]

-- Adicione seu SQL aqui
-- Exemplo:
-- CREATE TABLE example (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     name VARCHAR(255) NOT NULL,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );
EOF

# Criar arquivo DOWN
cat > "$DOWN_FILE" << EOF
-- Rollback for: ${NEXT_NUM}_${MIGRATION_NAME}
-- Created: $(date)

-- Reverta as mudanças feitas na migração UP
-- Exemplo:
-- DROP TABLE IF EXISTS example;
EOF

echo "✅ Arquivos criados!"
echo ""
echo "📝 Próximos passos:"
echo "1. Edite $UP_FILE"
echo "2. Edite $DOWN_FILE"
echo "3. Execute: bash migrations.sh up"
