package main

import (
    "net/http"
    "regexp"
    "strings"
    "github.com/gin-gonic/gin"
)

// Input validation middleware
func validationMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Validate request size (1MB limit)
        if c.Request.ContentLength > 1024*1024 {
            c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "Request too large"})
            c.Abort()
            return
        }
        
        // Validate Content-Type for POST requests
        if c.Request.Method == "POST" {
            contentType := c.GetHeader("Content-Type")
            if !strings.Contains(contentType, "application/json") {
                c.JSON(http.StatusBadRequest, gin.H{"error": "Content-Type must be application/json"})
                c.Abort()
                return
            }
        }
        
        // Validate User-Agent header length
        if userAgent := c.GetHeader("User-Agent"); len(userAgent) > 200 {
            c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid User-Agent header"})
            c.Abort()
            return
        }
        
        // Add security headers
        c.Header("X-Content-Type-Options", "nosniff")
        c.Header("X-Frame-Options", "DENY")
        c.Header("X-XSS-Protection", "1; mode=block")
        
        c.Next()
    }
}

// Validate tenant name format (alphanumeric, underscore, hyphen only)
func isValidTenantName(name string) bool {
    if len(name) == 0 || len(name) > 50 {
        return false
    }
    matched, _ := regexp.MatchString("^[a-zA-Z0-9_-]+$", name)
    return matched
}

// Validate username format
func isValidUsername(username string) bool {
    if len(username) < 3 || len(username) > 50 {
        return false
    }
    matched, _ := regexp.MatchString("^[a-zA-Z0-9_.-]+$", username)
    return matched
}

// Validate password strength
func isValidPassword(password string) bool {
    if len(password) < 8 || len(password) > 100 {
        return false
    }
    
    // Check for at least one uppercase, lowercase, digit
    hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
    hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
    hasDigit := regexp.MustCompile(`[0-9]`).MatchString(password)
    
    return hasUpper && hasLower && hasDigit
}
