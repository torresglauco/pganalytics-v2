package middleware

import (
    "strconv"
    "time"
    
    "github.com/gin-gonic/gin"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    httpRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
    
    httpRequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request duration in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )
    
    activeConnections = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "http_active_connections",
            Help: "Number of active HTTP connections",
        },
    )
)

func PrometheusMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        activeConnections.Inc()
        
        defer func() {
            activeConnections.Dec()
            duration := time.Since(start).Seconds()
            status := strconv.Itoa(c.Writer.Status())
            
            httpRequestsTotal.WithLabelValues(
                c.Request.Method,
                c.FullPath(),
                status,
            ).Inc()
            
            httpRequestDuration.WithLabelValues(
                c.Request.Method,
                c.FullPath(),
            ).Observe(duration)
        }()
        
        c.Next()
    }
}
