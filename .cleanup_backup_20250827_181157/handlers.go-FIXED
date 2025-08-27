package handlers

import (
	"net/http"
	"time"
	"pganalytics-backend/internal/config"
	"pganalytics-backend/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func SetupRoutes(router *gin.Engine, cfg *config.Config, db *pgxpool.Pool) {
	// Health check
	router.GET("/health", healthCheck)

	// Auth routes
	auth := router.Group("/auth")
	{
		auth.POST("/login", loginHandler(cfg.JWTSecret))
	}

	// Protected API routes
	api := router.Group("/api")
	api.Use(middleware.AuthMiddleware(cfg.JWTSecret))
	{
		api.POST("/metrics", metricsHandler(db))
		api.GET("/data", dataHandler(db))
	}
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "ok",
		"service":   "pganalytics-backend",
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

func loginHandler(jwtSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		var loginReq struct {
			Username string `json:"username"`
			Password string `json:"password"`
		}

		if err := c.ShouldBindJSON(&loginReq); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		// Simple authentication (replace with your logic)
		if loginReq.Username == "admin" && loginReq.Password == "admin" {
			// Create JWT token
			token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
				"username": loginReq.Username,
				"exp":      time.Now().Add(time.Hour * 24).Unix(),
			})

			tokenString, err := token.SignedString([]byte(jwtSecret))
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"token": tokenString,
				"user":  loginReq.Username,
			})
		} else {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		}
	}
}

func metricsHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var metrics interface{}
		if err := c.ShouldBindJSON(&metrics); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid metrics data"})
			return
		}

		// TODO: Process and store metrics in database
		c.JSON(http.StatusOK, gin.H{
			"status":    "metrics received",
			"timestamp": time.Now().Format(time.RFC3339),
			"data":      metrics,
		})
	}
}

func dataHandler(db *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		// TODO: Fetch analytics data from database
		c.JSON(http.StatusOK, gin.H{
			"data": gin.H{
				"message": "Analytics data will be available here",
				"query_performance": []gin.H{
					{"query": "SELECT * FROM users", "avg_time": "2.3ms"},
					{"query": "SELECT * FROM orders", "avg_time": "5.1ms"},
				},
				"connections": gin.H{
					"active": 10,
					"idle":   5,
					"total":  15,
				},
			},
			"timestamp": time.Now().Format(time.RFC3339),
		})
	}
}
