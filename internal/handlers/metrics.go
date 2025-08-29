package handlers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "pganalytics-backend/internal/models"
)

// GetMetrics retorna métricas do sistema
// @Summary      Obter métricas do sistema
// @Description  Retorna métricas de performance e uso do sistema (rota protegida)
// @Tags         Métricas
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  models.MetricsResponse  "Métricas obtidas com sucesso"
// @Failure      401  {object}  models.ErrorResponse    "Token inválido ou ausente"
// @Failure      500  {object}  models.ErrorResponse    "Erro interno"
// @Router       /metrics [get]
func GetMetrics(c *gin.Context) {
    userID := c.GetInt("user_id")
    email := c.GetString("email")
    role := c.GetString("role")

    c.JSON(http.StatusOK, models.MetricsResponse{
        Success:     true,
        Message:     "Métricas sistema",
        Environment: "production",
        Source:      "api",
        Timestamp:   time.Now().Unix(),
        User: gin.H{
            "id":    userID,
            "email": email,
            "role":  role,
        },
        Metrics: gin.H{
            "uptime":      "24h",
            "requests":    1337,
            "memory_mb":   256,
            "cpu_percent": 12.5,
        },
    })
}
