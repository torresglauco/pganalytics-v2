package handlers

import (
    "net/http"
    "time"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
    "pganalytics-backend/internal/models"
)

var jwtSecret = []byte("your-secret-key-2024")

var testUsers = map[string]models.User{
    "admin": {
        ID: 1, Username: "admin", Email: "admin@docker.local", 
        Password: "admin123", Role: "admin",
    },
    "admin@docker.local": {
        ID: 1, Username: "admin", Email: "admin@docker.local", 
        Password: "admin123", Role: "admin",
    },
    "admin@pganalytics.local": {
        ID: 2, Username: "admin2", Email: "admin@pganalytics.local", 
        Password: "admin123", Role: "admin",
    },
    "user": {
        ID: 3, Username: "user", Email: "user@docker.local", 
        Password: "admin123", Role: "user",
    },
    "test": {
        ID: 4, Username: "test", Email: "test@docker.local", 
        Password: "admin123", Role: "user",
    },
}

// Login autentica um usuário e retorna um token JWT
// @Summary      Autenticar usuário
// @Description  Autentica um usuário com username/email e senha, retornando um token JWT
// @Tags         Autenticação
// @Accept       json
// @Produce      json
// @Param        credentials  body      models.LoginRequest   true  "Credenciais de login"
// @Success      200          {object}  models.LoginResponse  "Login bem-sucedido"
// @Failure      400          {object}  models.ErrorResponse  "Dados inválidos"
// @Failure      401          {object}  models.ErrorResponse  "Credenciais inválidas"
// @Failure      500          {object}  models.ErrorResponse  "Erro interno"
// @Router       /auth/login [post]
func Login(c *gin.Context) {
    var req models.LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, models.ErrorResponse{Error: "Invalid request format"})
        return
    }

    var user models.User
    var found bool
    
    if u, ok := testUsers[req.Username]; ok && u.Password == req.Password {
        user = u
        found = true
    } else {
        for _, u := range testUsers {
            if (u.Email == req.Username || u.Username == req.Username) && u.Password == req.Password {
                user = u
                found = true
                break
            }
        }
    }

    if !found {
        c.JSON(http.StatusUnauthorized, models.ErrorResponse{Error: "Invalid credentials"})
        return
    }

    claims := &models.Claims{
        UserID: user.ID,
        Email:  user.Email,
        Role:   user.Role,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
            IssuedAt:  jwt.NewNumericDate(time.Now()),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    tokenString, err := token.SignedString(jwtSecret)
    if err != nil {
        c.JSON(http.StatusInternalServerError, models.ErrorResponse{Error: "Could not generate token"})
        return
    }

    c.JSON(http.StatusOK, models.LoginResponse{
        Token:     tokenString,
        ExpiresIn: 86400,
        User:      user.Email,
    })
}
