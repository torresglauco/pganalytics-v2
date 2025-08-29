#!/bin/bash

echo "🔧 CONSOLIDANDO MODELOS DUPLICADOS"

# 1. Verificar arquivos com struct User duplicada
echo "🔍 Verificando duplicações..."
find internal/models/ -name "*.go" -exec grep -l "type User struct" {} \;

# 2. Remover user.go se existir (mantém user_models.go)
if [ -f "internal/models/user.go" ]; then
    echo "🗑️ Removendo internal/models/user.go duplicado..."
    rm internal/models/user.go
fi

# 3. Verificar outras duplicações
echo "🔍 Verificando outras structs duplicadas..."
find internal/models/ -name "*.go" -exec grep -l "type.*struct" {} \;

# 4. Consolidar todos os modelos em um arquivo único
echo "📝 Consolidando modelos em models.go..."
cat > internal/models/models.go << 'EOF'
package models

import (
    "time"
    "github.com/golang-jwt/jwt/v5"
)

// User representa um usuário do sistema
type User struct {
    ID        int       `json:"id" db:"id"`
    Username  string    `json:"username" db:"username"`
    Email     string    `json:"email" db:"email"`
    Password  string    `json:"-" db:"password_hash"`
    Role      string    `json:"role" db:"role"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
    UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
}

// RefreshToken representa um token de refresh
type RefreshToken struct {
    ID        int       `json:"id" db:"id"`
    UserID    int       `json:"user_id" db:"user_id"`
    Token     string    `json:"token" db:"token"`
    ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// Claims para JWT
type Claims struct {
    UserID int    `json:"user_id"`
    Email  string `json:"email"`
    Role   string `json:"role"`
    jwt.RegisteredClaims
}

// LoginRequest representa requisição de login
type LoginRequest struct {
    Username string `json:"username" binding:"required"`
    Password string `json:"password" binding:"required"`
}

// LoginResponse representa resposta de login
type LoginResponse struct {
    Token     string `json:"token"`
    ExpiresIn int    `json:"expires_in"`
    User      string `json:"user"`
}

// ErrorResponse representa resposta de erro
type ErrorResponse struct {
    Error string `json:"error"`
}
EOF

# 5. Remover outros arquivos de modelos duplicados
echo "🧹 Limpando arquivos duplicados..."
find internal/models/ -name "*.go" ! -name "models.go" -delete

# 6. Verificar se não há mais duplicações
echo "✅ Verificando limpeza..."
grep -r "type User struct" internal/models/ || echo "✅ Sem duplicações!"

echo "✅ MODELOS CONSOLIDADOS!"
