package main

import (
    "log"
    "fmt"
    
    "github.com/gin-gonic/gin"
    
    "pganalytics-v2/internal/config"
    "pganalytics-v2/internal/database"
    "pganalytics-v2/internal/handlers"
    "pganalytics-v2/internal/middleware"
)

func main() {
    log.Println("Starting pganalytics-v2 server...")
    
    // Load configuration
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("Failed to load configuration: %v", err)
    }
    
    // Initialize database
    db, err := database.New(
        cfg.Database.Host,
        cfg.Database.User,
        cfg.Database.Password,
        cfg.Database.Name,
        cfg.Database.Port,
    )
    if err != nil {
        log.Fatalf("Failed to connect to database: %v", err)
    }
    defer db.Close()
    
    // Initialize handlers
    authHandler := handlers.NewAuthHandler(db, cfg.Auth.JWTSecret)
    healthHandler := handlers.NewHealthHandler(db)
    metricsHandler := handlers.NewMetricsHandler(db)
    
    // Setup router
    router := setupRouter(authHandler, healthHandler, metricsHandler, cfg.Auth.JWTSecret)
    
    // Start server
    port := fmt.Sprintf(":%d", cfg.Server.Port)
    log.Printf("Server starting on port %d", cfg.Server.Port)
    if err := router.Run(port); err != nil {
        log.Fatalf("Failed to start server: %v", err)
    }
}

func setupRouter(auth *handlers.AuthHandler, health *handlers.HealthHandler, metrics *handlers.MetricsHandler, jwtSecret string) *gin.Engine {
    router := gin.Default()
    
    // CORS middleware
    router.Use(func(c *gin.Context) {
        c.Header("Access-Control-Allow-Origin", "*")
        c.Header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")
        
        if c.Request.Method == "OPTIONS" {
            c.AbortWithStatus(204)
            return
        }
        c.Next()
    })
    
    // Public routes
    router.GET("/health", health.Health)
    router.POST("/auth/login", auth.Login)
    
    // Protected routes
    protected := router.Group("/")
    protected.Use(middleware.AuthMiddleware(jwtSecret))
    {
        protected.GET("/metrics", metrics.Metrics)
    }
    
    return router
}
