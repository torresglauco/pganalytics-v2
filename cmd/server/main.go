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
	
	"pganalytics-backend/internal/database"
	"pganalytics-backend/internal/handlers"
	"pganalytics-backend/internal/middleware"
	"pganalytics-backend/internal/models"
	"pganalytics-backend/internal/repositories"
	"pganalytics-backend/internal/services"
	
	// Import docs for swagger
	_ "pganalytics-backend/docs"
)

// @title           PG Analytics API
// @version         1.0
// @description     API REST moderna para análise de PostgreSQL com autenticação JWT

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

	// Inicializar banco de dados
	db, err := database.NewDB()
	if err != nil {
		log.Printf("⚠️ Banco de dados não disponível: %v", err)
		log.Printf("⚠️ Utilizando dados mock para desenvolvimento")
	} else {
		log.Printf("✅ Banco de dados conectado com sucesso")
	}

	// Inicializar repositórios
	analyticsRepo := repositories.NewAnalyticsRepository(db)

	// Inicializar serviços
	analyticsService := services.NewAnalyticsService(analyticsRepo)

	// Inicializar handlers
	analyticsHandler := handlers.NewAnalyticsHandler(analyticsService)

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
		dbStatus := "not connected"
		if db != nil {
			if err := db.Ping(); err == nil {
				dbStatus = "connected"
			}
		}

		c.JSON(http.StatusOK, models.HealthResponse{
			Status:      "healthy",
			Message:     "PG Analytics API funcionando",
			Environment: getEnvironment(),
			Version:     "1.0",
			Port:        getPort(),
			Database:    dbStatus,
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

	// API v1 (protected)
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
			// @Success      200  {object}  models.ProfileResponse
			// @Failure      401  {object}  models.ErrorResponse
			// @Router       /api/v1/auth/profile [get]
			authGroup.GET("/profile", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{
					"user_id": c.GetInt("user_id"),
					"email":   c.GetString("email"),
					"role":    c.GetString("role"),
					"message": "Profile data",
				})
			})
		}

		// Analytics routes (real PostgreSQL)
		analytics := api.Group("/analytics")
		{
			analytics.GET("/queries/slow", analyticsHandler.GetSlowQueries)
			analytics.GET("/tables/stats", analyticsHandler.GetTableStats)
			analytics.GET("/connections", analyticsHandler.GetConnectionStats)
			analytics.GET("/database/size", analyticsHandler.GetDatabaseSize)
			analytics.GET("/performance", analyticsHandler.GetPerformanceStats)
			analytics.GET("/all", analyticsHandler.GetFullAnalytics)
		}
	}

	port := getPort()
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

// Função helper para obter porta
func getPort() string {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	return port
}

// Função helper para obter ambiente
func getEnvironment() string {
	env := os.Getenv("APP_ENV")
	if env == "" {
		env = "development"
	}
	return env
}
