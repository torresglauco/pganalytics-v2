package integration

import (
    "testing"
    "net/http"
    "net/http/httptest"
    
    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
)

func TestHealthEndpoint_Integration(t *testing.T) {
    gin.SetMode(gin.TestMode)
    
    // Setup test database connection
    // ... database setup code ...
    
    router := gin.New()
    // ... setup routes ...
    
    req, _ := http.NewRequest("GET", "/health", nil)
    w := httptest.NewRecorder()
    router.ServeHTTP(w, req)
    
    assert.Equal(t, http.StatusOK, w.Code)
    assert.Contains(t, w.Body.String(), "status")
}
