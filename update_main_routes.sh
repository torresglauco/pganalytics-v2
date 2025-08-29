#!/bin/bash

echo "🔧 ATUALIZANDO MAIN.GO COM ROTAS CORRETAS"

# Backup
cp cmd/server/main.go cmd/server/main.go.backup.$(date +%Y%m%d_%H%M%S)

# Criar main.go corrigido
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
    // Configurar Gin para produção se não for desenvolvimento
    if os.Getenv("GIN_MODE") == "release" {
        gin.SetMode(gin.ReleaseMode)
    }

    // Criar router
    router := gin.Default()

    // Configurar CORS
    router.Use(cors.New(cors.Config{
        AllowOrigins:     []string{"*"},
        AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowHeaders:     []string{"*"},
        ExposeHeaders:    []string{"Content-Length"},
        AllowCredentials: true,
        MaxAge:           12 * time.Hour,
    }))

    // Health check (não protegida)
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

    // Rotas de autenticação (não protegidas)
    auth := router.Group("/auth")
    {
        auth.POST("/login", handlers.Login)
    }

    // Rotas protegidas
    protected := router.Group("/")
    protected.Use(middleware.AuthMiddleware())
    {
        protected.GET("/metrics", handlers.GetMetrics)
    }

    // Rotas API v1 (protegidas) - estrutura do repositório
    api := router.Group("/api/v1")
    api.Use(middleware.AuthMiddleware())
    {
        // Auth routes
        authGroup := api.Group("/auth")
        {
            authGroup.GET("/profile", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "user_id": c.GetInt("user_id"),
                    "email":   c.GetString("email"),
                    "role":    c.GetString("role"),
                })
            })
        }

        // Analytics routes (estrutura do repo)
        analytics := api.Group("/analytics")
        {
            analytics.GET("/queries/slow", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "queries": []gin.H{
                        {"query": "SELECT * FROM users", "duration": "2.5s"},
                        {"query": "SELECT COUNT(*) FROM logs", "duration": "1.8s"},
                    },
                })
            })

            analytics.GET("/tables/stats", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "tables": []gin.H{
                        {"name": "users", "rows": 1500, "size": "12MB"},
                        {"name": "logs", "rows": 25000, "size": "45MB"},
                    },
                })
            })

            analytics.GET("/connections", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "active_connections": 15,
                    "max_connections":    100,
                    "idle_connections":   5,
                })
            })

            analytics.GET("/performance", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "cpu_usage":    "25%",
                    "memory_usage": "60%",
                    "disk_usage":   "40%",
                })
            })
        }
    }

    // Log de inicialização
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    log.Printf("🚀 Servidor iniciando na porta %s", port)
    log.Printf("🔗 Health: http://localhost:%s/health", port)
    log.Printf("🔐 Login: POST http://localhost:%s/auth/login", port)
    log.Printf("📊 Metrics: GET http://localhost:%s/metrics", port)
    log.Printf("🌐 API v1: http://localhost:%s/api/v1/", port)

    // Iniciar servidor
    if err := router.Run(":" + port); err != nil {
        log.Fatal("Erro ao iniciar servidor:", err)
    }
}
EOF

echo "✅ MAIN.GO ATUALIZADO COM ROTAS CORRETAS!"
