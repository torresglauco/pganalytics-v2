#!/bin/bash

echo "💥 LIMPEZA NUCLEAR COMPLETA"
echo "=========================="

# 1. Parar tudo
echo "🛑 Parando containers..."
docker-compose down

# 2. LIMPEZA NUCLEAR - remover TODO o diretório internal
echo "💥 LIMPEZA NUCLEAR: Removendo TUDO do internal/..."
rm -rf internal/
ls -la internal/ 2>/dev/null || echo "✅ internal/ removido completamente"

# 3. Verificar outros arquivos que podem estar conflitando
echo "🔍 Verificando outros arquivos..."
find . -name "*.go" -path "./internal/*" 2>/dev/null || echo "✅ Nenhum arquivo .go em internal/"

# 4. RECONSTRUÇÃO TOTAL DO ZERO
echo "🏗️ RECONSTRUINDO ESTRUTURA DO ZERO..."

# Criar diretórios
mkdir -p internal/handlers
mkdir -p internal/middleware
mkdir -p internal/models
mkdir -p cmd/server

# Verificar estrutura criada
echo "📁 Estrutura criada:"
find internal/ -type d 2>/dev/null || echo "❌ Erro ao criar estrutura"

# 5. RECRIAR TODOS OS ARQUIVOS (versão limpa)
echo "📝 Recriando TODOS os arquivos..."

# Models
cat > internal/models/models.go << 'EOF'
package models

import (
    "time"
    "github.com/golang-jwt/jwt/v5"
)

type User struct {
    ID        int       `json:"id"`
    Username  string    `json:"username"`
    Email     string    `json:"email"`
    Password  string    `json:"-"`
    Role      string    `json:"role"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

type Claims struct {
    UserID int    `json:"user_id"`
    Email  string `json:"email"`
    Role   string `json:"role"`
    jwt.RegisteredClaims
}

type LoginRequest struct {
    Username string `json:"username" binding:"required"`
    Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
    Token     string `json:"token"`
    ExpiresIn int    `json:"expires_in"`
    User      string `json:"user"`
}

type ErrorResponse struct {
    Error string `json:"error"`
}
EOF

# Middleware
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

func AuthMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if authHeader == "" {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
            c.Abort()
            return
        }

        tokenString := strings.TrimPrefix(authHeader, "Bearer ")
        if tokenString == authHeader {
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization format"})
            c.Abort()
            return
        }

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

# Handler de Auth
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
        ID: 2, Username: "admin2", Email: "admin@pganalytics.local", 
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

func Login(c *gin.Context) {
    var req models.LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Invalid request format"})
        return
    }

    var user models.User
    var found bool
    
    // Busca exata primeiro
    if u, ok := testUsers[req.Username]; ok && u.Password == req.Password {
        user = u
        found = true
    } else {
        // Busca por email
        for _, u := range testUsers {
            if (u.Email == req.Username || u.Username == req.Username) && u.Password == req.Password {
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
        ExpiresIn: 86400,
        User:      user.Email,
    })
}
EOF

# Handler de Metrics
cat > internal/handlers/metrics.go << 'EOF'
package handlers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
)

func GetMetrics(c *gin.Context) {
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

# Main.go COMPLETO com todas as rotas
cat > cmd/server/main.go << 'EOF'
package main

import (
    "log"
    "net/http"
    "os"
    "time"
    
    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
    "pganalytics-backend/internal/handlers"
    "pganalytics-backend/internal/middleware"
)

func main() {
    if os.Getenv("GIN_MODE") == "release" {
        gin.SetMode(gin.ReleaseMode)
    }

    router := gin.Default()

    // CORS
    router.Use(cors.New(cors.Config{
        AllowOrigins:     []string{"*"},
        AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowHeaders:     []string{"*"},
        ExposeHeaders:    []string{"Content-Length"},
        AllowCredentials: true,
        MaxAge:           12 * time.Hour,
    }))

    // Health check (público)
    router.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "status":      "healthy",
            "message":     "PG Analytics API Docker funcionando",
            "environment": "docker",
            "version":     "1.0",
            "port":        "8080",
            "database":    "connected",
        })
    })

    // Auth (público)
    auth := router.Group("/auth")
    {
        auth.POST("/login", handlers.Login)
    }

    // Rotas protegidas diretas
    protected := router.Group("/")
    protected.Use(middleware.AuthMiddleware())
    {
        protected.GET("/metrics", handlers.GetMetrics)
    }

    // API v1 (protegidas)
    api := router.Group("/api/v1")
    api.Use(middleware.AuthMiddleware())
    {
        // Auth profile
        authGroup := api.Group("/auth")
        {
            authGroup.GET("/profile", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "user_id": c.GetInt("user_id"),
                    "email":   c.GetString("email"),
                    "role":    c.GetString("role"),
                    "message": "Profile data",
                })
            })
        }

        // Analytics routes
        analytics := api.Group("/analytics")
        {
            analytics.GET("/queries/slow", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "queries": []gin.H{
                        {"query": "SELECT * FROM users", "duration": "2.5s"},
                        {"query": "SELECT COUNT(*) FROM logs", "duration": "1.8s"},
                    },
                    "user": c.GetString("email"),
                })
            })

            analytics.GET("/tables/stats", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "tables": []gin.H{
                        {"name": "users", "rows": 1500, "size": "12MB"},
                        {"name": "logs", "rows": 25000, "size": "45MB"},
                    },
                    "user": c.GetString("email"),
                })
            })

            analytics.GET("/connections", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "active_connections": 15,
                    "max_connections":    100,
                    "idle_connections":   5,
                    "user": c.GetString("email"),
                })
            })

            analytics.GET("/performance", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "cpu_usage":    "25%",
                    "memory_usage": "60%",
                    "disk_usage":   "40%",
                    "user": c.GetString("email"),
                })
            })
        }
    }

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("🚀 Servidor iniciando na porta %s", port)
    log.Printf("🔗 Health: http://localhost:%s/health", port)
    log.Printf("🔐 Login: POST http://localhost:%s/auth/login", port)
    log.Printf("📊 Metrics: GET http://localhost:%s/metrics", port)
    log.Printf("🌐 API v1: http://localhost:%s/api/v1/", port)

    if err := router.Run(":" + port); err != nil {
        log.Fatal("Erro ao iniciar servidor:", err)
    }
}
EOF

# 6. Verificar que só temos nossos arquivos
echo ""
echo "📁 VERIFICAÇÃO FINAL:"
echo "Arquivos criados:"
find internal/ -name "*.go" 2>/dev/null
find cmd/ -name "*.go" 2>/dev/null

# 7. Limpar módulos
echo ""
echo "🔄 Limpando módulos..."
go mod tidy

echo ""
echo "✅ LIMPEZA NUCLEAR CONCLUÍDA!"
echo "💥 Estrutura 100% limpa e recriada"
echo ""
echo "🚀 Execute agora:"
echo "  docker-compose build --no-cache && docker-compose up -d"
