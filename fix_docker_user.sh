#!/bin/bash

echo "🔐 CORRIGINDO USUÁRIO admin@docker.local"

# Atualizar handler de auth para incluir admin@docker.local corretamente
cat > internal/handlers/auth.go << 'EOF'
package handlers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "pganalytics-backend/internal/models"
)

var jwtSecret = []byte("your-secret-key-2024")

// Usuários de teste (em produção, viria do banco)
var testUsers = map[string]models.User{
    "admin": {
        ID: 1, Username: "admin", Email: "admin@docker.local", 
        Password: "admin123", Role: "admin",
    },
    "admin@docker.local": {
        ID: 1, Username: "admin", Email: "admin@docker.local", 
        Password: "admin123", Role: "admin",
    },
    "admin@pganalytics.local": {
        ID: 2, Username: "admin", Email: "admin@pganalytics.local", 
        Password: "admin123", Role: "admin",
    },
    "user": {
        ID: 3, Username: "user", Email: "user@docker.local", 
        Password: "admin123", Role: "user",
    },
    "test": {
        ID: 4, Username: "test", Email: "test@docker.local", 
        Password: "admin123", Role: "user",
    },
}

// Login autentica usuário e retorna JWT
func Login(c *gin.Context) {
    var req models.LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Invalid request format"})
        return
    }

    // Verificar credenciais (suporta username ou email)
    var user models.User
    var found bool
    
    // Debug: log da tentativa
    username := req.Username
    
    // Primeiro: busca exata por username/email
    if u, ok := testUsers[username]; ok && u.Password == req.Password {
        user = u
        found = true
    } else {
        // Segundo: busca por email em todos os usuários
        for key, u := range testUsers {
            if (u.Email == username || u.Username == username) && u.Password == req.Password {
                user = u
                found = true
                break
            }
        }
    }

    if !found {
        // Resposta amigável com dica
        c.JSON(http.StatusUnauthorized, gin.H{
            "error": "Invalid credentials",
            "hint": "Usuários válidos: admin, admin@pganalytics.local, user, test",
            "environment": "docker",
        })
        return
    }

    // Gerar token JWT
    claims := &models.Claims{
        UserID: user.ID,
        Email:  user.Email,
        Role:   user.Role,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    tokenString, err := token.SignedString(jwtSecret)
    if err != nil {
        c.JSON(http.StatusInternalServerError, models.ErrorResponse{Error: "Could not generate token"})
        return
    }

    c.JSON(http.StatusOK, models.LoginResponse{
        Token:     tokenString,
        ExpiresIn: 86400, // 24 horas
        User:      user.Email,
    })
}
EOF

echo "✅ USUÁRIO admin@docker.local CORRIGIDO!"
