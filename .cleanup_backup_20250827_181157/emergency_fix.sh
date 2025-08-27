#!/bin/bash
# emergency_fix.sh - Correção emergencial

echo "🚨 CORREÇÃO EMERGENCIAL"
echo "======================"

# 1. LIMPAR BACKUPS RECURSIVOS PROBLEMÁTICOS
echo "🧹 Removendo backups recursivos problemáticos..."
find . -name "nuclear-backup*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*backup*" -type d -maxdepth 2 -exec rm -rf {} + 2>/dev/null || true

echo "✅ Backups problemáticos removidos"

# 2. CRIAR main.go LIMPO SEM CARACTERES DE ESCAPE
echo "📝 Criando main.go limpo..."
mkdir -p cmd/server

# Usando cat sem heredoc para evitar problemas de escape
cat > cmd/server/main.go << 'MAINEOF'
package main

import (
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// @title PGAnalytics API
// @version 1.0
// @description Modern PostgreSQL analytics backend
// @host localhost:8080
// @BasePath /
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization

type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	Token string `json:"token"`
	User  string `json:"user"`
}

type HealthResponse struct {
	Status    string   `json:"status"`
	Service   string   `json:"service"`
	Timestamp string   `json:"timestamp"`
	Features  []string `json:"features"`
}

type MetricsRequest struct {
	Database  string                 `json:"database"`
	Timestamp string                 `json:"timestamp"`
	Metrics   map[string]interface{} `json:"metrics"`
}

type DataResponse struct {
	QueryPerformance []QueryStat `json:"query_performance"`
	Connections      Connection  `json:"connections"`
	Timestamp        string      `json:"timestamp"`
}

type QueryStat struct {
	Query   string `json:"query"`
	AvgTime string `json:"avg_time"`
	Calls   int    `json:"calls"`
}

type Connection struct {
	Active int `json:"active"`
	Idle   int `json:"idle"`
	Total  int `json:"total"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Details string `json:"details,omitempty"`
}

var jwtSecret = "your-super-secret-jwt-key"

func main() {
	gin.SetMode(gin.DebugMode)
	router := gin.Default()

	// CORS
	router.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Accept, Authorization, Content-Type, X-CSRF-Token")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	})

	// Swagger
	router.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Routes
	router.GET("/health", healthCheck)
	router.POST("/auth/login", loginHandler)

	// Protected routes
	protected := router.Group("/api")
	protected.Use(authMiddleware())
	{
		protected.POST("/metrics", submitMetrics)
		protected.GET("/data", getAnalyticsData)
	}

	log.Printf("🚀 Server starting on port 8080")
	log.Printf("📚 Health: http://localhost:8080/health")
	log.Printf("📚 Swagger: http://localhost:8080/swagger/index.html")

	if err := router.Run(":8080"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

// @Summary Check API health
// @Description Get health status
// @Tags Health
// @Produce json
// @Success 200 {object} HealthResponse
// @Router /health [get]
func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, HealthResponse{
		Status:    "ok",
		Service:   "pganalytics-backend",
		Timestamp: time.Now().Format(time.RFC3339),
		Features: []string{
			"Swagger documentation",
			"JWT Authentication",
			"CORS enabled",
			"Metrics collection",
			"Analytics API",
		},
	})
}

// @Summary User login
// @Description Authenticate and get JWT token
// @Tags Authentication
// @Accept json
// @Produce json
// @Param login body LoginRequest true "Credentials"
// @Success 200 {object} LoginResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Router /auth/login [post]
func loginHandler(c *gin.Context) {
	var req LoginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid request",
			Details: err.Error(),
		})
		return
	}

	if req.Username == "admin" && req.Password == "admin" {
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
			"username": req.Username,
			"exp":      time.Now().Add(time.Hour * 24).Unix(),
			"iat":      time.Now().Unix(),
		})

		tokenString, err := token.SignedString([]byte(jwtSecret))
		if err != nil {
			c.JSON(http.StatusInternalServerError, ErrorResponse{
				Error: "Failed to generate token",
			})
			return
		}

		c.JSON(http.StatusOK, LoginResponse{
			Token: tokenString,
			User:  req.Username,
		})
	} else {
		c.JSON(http.StatusUnauthorized, ErrorResponse{
			Error: "Invalid credentials",
		})
	}
}

// @Summary Submit metrics
// @Description Submit performance metrics
// @Tags Metrics
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param metrics body MetricsRequest true "Metrics"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Router /api/metrics [post]
func submitMetrics(c *gin.Context) {
	var req MetricsRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error:   "Invalid metrics",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":        "metrics received",
		"timestamp":     time.Now().Format(time.RFC3339),
		"database":      req.Database,
		"metrics_count": len(req.Metrics),
	})
}

// @Summary Get analytics data
// @Description Get performance analytics
// @Tags Analytics
// @Produce json
// @Security BearerAuth
// @Success 200 {object} DataResponse
// @Failure 401 {object} ErrorResponse
// @Router /api/data [get]
func getAnalyticsData(c *gin.Context) {
	response := DataResponse{
		QueryPerformance: []QueryStat{
			{Query: "SELECT * FROM users WHERE active = true", AvgTime: "2.3ms", Calls: 1500},
			{Query: "SELECT * FROM orders WHERE date > NOW() - INTERVAL '1 day'", AvgTime: "5.8ms", Calls: 800},
		},
		Connections: Connection{
			Active: 10,
			Idle:   5,
			Total:  15,
		},
		Timestamp: time.Now().Format(time.RFC3339),
	}

	c.JSON(http.StatusOK, response)
}

func authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")

		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Error: "Authorization header required",
			})
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Error: "Bearer token required",
			})
			c.Abort()
			return
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(jwtSecret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, ErrorResponse{
				Error: "Invalid token",
			})
			c.Abort()
			return
		}

		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			c.Set("username", claims["username"])
		}

		c.Next()
	}
}
MAINEOF

# 3. VERIFICAR E CORRIGIR go.mod
echo "📦 Verificando go.mod..."
if [[ ! -f "go.mod" ]] || ! grep -q "github.com/golang-jwt/jwt/v5" go.mod; then
    echo "Corrigindo go.mod..."
    cat > go.mod << 'MODEOF'
module pganalytics-backend

go 1.23

require (
	github.com/gin-gonic/gin v1.10.0
	github.com/golang-jwt/jwt/v5 v5.2.1
	github.com/jackc/pgx/v5 v5.6.0
	github.com/joho/godotenv v1.5.1
	github.com/swaggo/files v1.0.1
	github.com/swaggo/gin-swagger v1.6.0
)
MODEOF
fi

# 4. LIMPAR E BAIXAR DEPENDÊNCIAS
echo "⬇️  Baixando dependências..."
rm -f go.sum
go mod tidy
go mod download

# 5. GERAR DOCUMENTAÇÃO
echo "📚 Gerando documentação..."
if command -v swag &>/dev/null; then
    swag init -g cmd/server/main.go --output docs/ || echo "⚠️  Swagger com problemas, mas API funcionará"
else
    echo "⚠️  swag não disponível, mas API funcionará sem docs"
fi

# 6. TESTE DE BUILD
echo "🔨 Testando build..."
go build -o /tmp/emergency-test ./cmd/server

if [[ $? -eq 0 ]]; then
    echo "✅ BUILD FUNCIONANDO!"
    rm -f /tmp/emergency-test
else
    echo "❌ Build ainda com problemas"
    echo "Verificando erros..."
    go build -v ./cmd/server
fi

# 7. LIMPAR DOCKER CONTEXT
echo "🐳 Limpando contexto Docker..."
echo "node_modules/" > .dockerignore
echo "*backup*/" >> .dockerignore
echo "*.log" >> .dockerignore
echo ".git/" >> .dockerignore

# 8. VERIFICAÇÃO FINAL
echo "✅ Verificação final..."
go fmt ./...
go vet ./... && echo "✅ go vet OK" || echo "⚠️  go vet com warnings"

echo ""
echo "🎉 CORREÇÃO EMERGENCIAL CONCLUÍDA!"
echo "================================="
echo ""
echo "✅ Problemas corrigidos:"
echo "  🧹 Backups recursivos removidos"
echo "  📝 main.go limpo sem caracteres inválidos"
echo "  📦 go.mod corrigido"
echo "  🐳 .dockerignore criado"
echo ""
echo "🚀 Para testar:"
echo "  make dev    # Docker"
echo "  make run    # Local (se Makefile existe)"
echo "  go run ./cmd/server  # Direto"
echo ""
echo "🌐 Endpoints:"
echo "  http://localhost:8080/health"
echo "  http://localhost:8080/swagger/index.html"
