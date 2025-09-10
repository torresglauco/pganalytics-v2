package handlers

import (
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
    db        Database
    jwtSecret string
}

type Database interface {
    QueryRow(query string, args ...interface{}) *sql.Row
    Health() error
}

type Credentials struct {
    Username string `json:"username" binding:"required,min=3,max=50"`
    Password string `json:"password" binding:"required,min=6"`
}

func NewAuthHandler(db Database, jwtSecret string) *AuthHandler {
    return &AuthHandler{
        db:        db,
        jwtSecret: jwtSecret,
    }
}

func (h *AuthHandler) Login(c *gin.Context) {
    var creds Credentials
    if err := c.ShouldBindJSON(&creds); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request format"})
        return
    }
    
    // Validate credentials
    if !h.validateCredentials(creds.Username, creds.Password) {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
        return
    }
    
    // Generate JWT token
    token, err := h.generateToken(creds.Username)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
        return
    }
    
    c.JSON(http.StatusOK, gin.H{"token": token})
}

func (h *AuthHandler) validateCredentials(username, password string) bool {
    var hashedPassword string
    err := h.db.QueryRow("SELECT password FROM users WHERE username = $1", username).Scan(&hashedPassword)
    if err == nil {
        return bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password)) == nil
    }
    return false
}

func (h *AuthHandler) generateToken(username string) (string, error) {
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "username": username,
        "exp":      time.Now().Add(time.Hour * 24).Unix(),
    })
    
    return token.SignedString([]byte(h.jwtSecret))
}
