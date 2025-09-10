package handlers

import (
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
)

type MetricsHandler struct {
    db Database
}

func NewMetricsHandler(db Database) *MetricsHandler {
    return &MetricsHandler{db: db}
}

func (h *MetricsHandler) Metrics(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "timestamp":   time.Now().Format(time.RFC3339),
        "environment": "docker",
        "status":      "operational",
    })
}
