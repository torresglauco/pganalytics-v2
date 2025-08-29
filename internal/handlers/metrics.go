package handlers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
)

func GetMetrics(c *gin.Context) {
    userID := c.GetInt("user_id")
    email := c.GetString("email")
    role := c.GetString("role")

    c.JSON(http.StatusOK, gin.H{
        "success":     true,
        "message":     "Métricas sistema Docker",
        "environment": "docker",
        "source":      "docker_api",
        "timestamp":   time.Now().Unix(),
        "user": gin.H{
            "id":    userID,
            "email": email,
            "role":  role,
        },
        "metrics": gin.H{
            "uptime":      "24h",
            "requests":    1337,
            "memory_mb":   256,
            "cpu_percent": 12.5,
        },
    })
}
