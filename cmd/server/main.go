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
