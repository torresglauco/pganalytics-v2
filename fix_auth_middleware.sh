#!/bin/bash

echo "🔐 CORRIGINDO MIDDLEWARE E AUTENTICAÇÃO"

# 1. Atualizar middleware para usar modelos corretos
echo "🔧 Atualizando middleware..."
cat > internal/middleware/auth.go << 'EOF'
package middleware

import (
    "net/http"
    "strings"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "pganalytics-backend/internal/models"
)

var jwtSecret = []byte("your-secret-key-2024")

// AuthMiddleware valida tokens JWT
func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
            c.Abort()
            return
        }

        // Extrair token do header "Bearer TOKEN"
        tokenString := strings.TrimPrefix(authHeader, "Bearer ")
        if tokenString == authHeader {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization format"})
            c.Abort()
            return
        }

        // Validar token
        token, err := jwt.ParseWithClaims(tokenString, &models.Claims{}, func(token *jwt.Token) (interface{}, error) {
            return jwtSecret, nil
        })

        if err != nil || !token.Valid {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
            c.Abort()
            return
        }

        if claims, ok := token.Claims.(*models.Claims); ok {
            c.Set("user_id", claims.UserID)
            c.Set("email", claims.Email)
            c.Set("role", claims.Role)
        }

        c.Next()
    }
}
EOF

# 2. Atualizar handlers para suportar múltiplos usuários
echo "📝 Atualizando handlers..."
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
    
    // Tentar por username primeiro
    if u, ok := testUsers[req.Username]; ok && u.Password == req.Password {
        user = u
        found = true
    } else {
        // Tentar por email
        for _, u := range testUsers {
            if u.Email == req.Username && u.Password == req.Password {
                user = u
                found = true
                break
            }
        }
    }

    if !found {
        c.JSON(http.StatusUnauthorized, models.ErrorResponse{Error: "Invalid credentials"})
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

# 3. Corrigir rota de métricas
echo "📊 Corrigindo handler de métricas..."
cat > internal/handlers/metrics.go << 'EOF'
package handlers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
)

// GetMetrics retorna métricas do sistema (rota protegida)
func GetMetrics(c *gin.Context) {
    // Dados do usuário autenticado
    userID := c.GetInt("user_id")
    email := c.GetString("email")
    role := c.GetString("role")

    c.JSON(http.StatusOK, gin.H{
        "success":     true,
        "message":     "Métricas sistema Docker",
        "environment": "docker",
        "source":      "docker_api",
        "timestamp":   time.Now().Unix(),
        "user": gin.H{
            "id":    userID,
            "email": email,
            "role":  role,
        },
        "metrics": gin.H{
            "uptime":      "24h",
            "requests":    1337,
            "memory_mb":   256,
            "cpu_percent": 12.5,
        },
    })
}
EOF

echo "✅ MIDDLEWARE E HANDLERS CORRIGIDOS!"
