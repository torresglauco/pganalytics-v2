package handlers

import (
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
)

type HealthHandler struct {
    db Database
}

func NewHealthHandler(db Database) *HealthHandler {
    return &HealthHandler{db: db}
}

func (h *HealthHandler) Health(c *gin.Context) {
    status := "connected"
    if err := h.db.Health(); err != nil {
        status = "disconnected"
    }
    
    c.JSON(http.StatusOK, gin.H{
        "status":      "healthy",
        "database":    status,
        "port":        "8080",
        "environment": "docker",
        "version":     "2.0",
        "timestamp":   time.Now().Format(time.RFC3339),
    })
}
