package main

import (
    "log"
    "net/http"
    "os"
    "time"
    
    "github.com/gin-contrib/cors"
    "github.com/gin-gonic/gin"
    swaggerFiles "github.com/swaggo/files"
    ginSwagger "github.com/swaggo/gin-swagger"
    
    "pganalytics-backend/internal/handlers"
    "pganalytics-backend/internal/middleware"
    "pganalytics-backend/internal/models"
    
    // Import docs for swagger
    _ "pganalytics-backend/docs"
)

// @title           PG Analytics API
// @version         1.0
// @description     API REST moderna para análise de PostgreSQL com autenticação JWT
// @termsOfService  https://pganalytics.com/terms

// @contact.name   Suporte PG Analytics
// @contact.url    https://pganalytics.com/support
// @contact.email  suporte@pganalytics.com

// @license.name  MIT
// @license.url   https://github.com/torresglauco/pganalytics-v2/blob/main/LICENSE

// @host      localhost:8080
// @BasePath  /

// @securityDefinitions.apikey  BearerAuth
// @in                          header
// @name                        Authorization
// @description                 Digite 'Bearer ' seguido do seu token JWT

// @tag.name         Autenticação
// @tag.description  Endpoints para autenticação e gestão de usuários

// @tag.name         Métricas
// @tag.description  Endpoints para obter métricas e dados de análise

// @tag.name         Analytics
// @tag.description  Endpoints para análise avançada do PostgreSQL

// @tag.name         Sistema
// @tag.description  Endpoints de sistema e health checks

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

    // Swagger documentation
    router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

    // Health check
    // @Summary      Health Check
    // @Description  Verifica o status de saúde da API
    // @Tags         Sistema
    // @Accept       json
    // @Produce      json
    // @Success      200  {object}  models.HealthResponse  "API funcionando"
    // @Router       /health [get]
    router.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, models.HealthResponse{
            Status:      "healthy",
            Message:     "PG Analytics API funcionando",
            Environment: "production",
            Version:     "1.0",
            Port:        "8080",
            Database:    "connected",
        })
    })

    // Auth routes
    auth := router.Group("/auth")
    {
        auth.POST("/login", handlers.Login)
    }

    // Protected routes
    protected := router.Group("/")
    protected.Use(middleware.AuthMiddleware())
    {
        protected.GET("/metrics", handlers.GetMetrics)
    }

    // API v1
    api := router.Group("/api/v1")
    api.Use(middleware.AuthMiddleware())
    {
        // Auth profile
        authGroup := api.Group("/auth")
        {
            // @Summary      Obter perfil do usuário
            // @Description  Retorna dados do perfil do usuário autenticado
            // @Tags         Autenticação
            // @Accept       json
            // @Produce      json
            // @Security     BearerAuth
            // @Success      200  {object}  models.ProfileResponse  "Perfil obtido"
            // @Failure      401  {object}  models.ErrorResponse    "Token inválido"
            // @Router       /api/v1/auth/profile [get]
            authGroup.GET("/profile", func(c *gin.Context) {
                c.JSON(http.StatusOK, models.ProfileResponse{
                    UserID:  c.GetInt("user_id"),
                    Email:   c.GetString("email"),
                    Role:    c.GetString("role"),
                    Message: "Profile data",
                })
            })
        }

        // Analytics routes
        analytics := api.Group("/analytics")
        {
            // @Summary      Obter queries lentas
            // @Description  Retorna as consultas SQL mais lentas do PostgreSQL
            // @Tags         Analytics
            // @Accept       json
            // @Produce      json
            // @Security     BearerAuth
            // @Success      200  {object}  object  "Queries lentas"
            // @Failure      401  {object}  models.ErrorResponse  "Token inválido"
            // @Router       /api/v1/analytics/queries/slow [get]
            analytics.GET("/queries/slow", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "queries": []gin.H{
                        {"query": "SELECT * FROM users", "duration": "2.5s"},
                        {"query": "SELECT COUNT(*) FROM logs", "duration": "1.8s"},
                    },
                    "user": c.GetString("email"),
                })
            })

            // @Summary      Obter estatísticas de tabelas
            // @Description  Retorna estatísticas das tabelas do PostgreSQL
            // @Tags         Analytics
            // @Accept       json
            // @Produce      json
            // @Security     BearerAuth
            // @Success      200  {object}  object  "Estatísticas de tabelas"
            // @Failure      401  {object}  models.ErrorResponse  "Token inválido"
            // @Router       /api/v1/analytics/tables/stats [get]
            analytics.GET("/tables/stats", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "tables": []gin.H{
                        {"name": "users", "rows": 1500, "size": "12MB"},
                        {"name": "logs", "rows": 25000, "size": "45MB"},
                    },
                    "user": c.GetString("email"),
                })
            })

            // @Summary      Obter conexões ativas
            // @Description  Retorna informações sobre conexões ativas do PostgreSQL
            // @Tags         Analytics
            // @Accept       json
            // @Produce      json
            // @Security     BearerAuth
            // @Success      200  {object}  object  "Conexões ativas"
            // @Failure      401  {object}  models.ErrorResponse  "Token inválido"
            // @Router       /api/v1/analytics/connections [get]
            analytics.GET("/connections", func(c *gin.Context) {
                c.JSON(http.StatusOK, gin.H{
                    "active_connections": 15,
                    "max_connections":    100,
                    "idle_connections":   5,
                    "user": c.GetString("email"),
                })
            })

            // @Summary      Obter métricas de performance
            // @Description  Retorna métricas de performance do PostgreSQL
            // @Tags         Analytics
            // @Accept       json
            // @Produce      json
            // @Security     BearerAuth
            // @Success      200  {object}  object  "Métricas de performance"
            // @Failure      401  {object}  models.ErrorResponse  "Token inválido"
            // @Router       /api/v1/analytics/performance [get]
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
    log.Printf("📖 Swagger: http://localhost:%s/swagger/index.html", port)

    if err := router.Run(":" + port); err != nil {
        log.Fatal("Erro ao iniciar servidor:", err)
    }
}
