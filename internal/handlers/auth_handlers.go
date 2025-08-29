package handlers

import (
    "net/http"
    "strings"
    
    "github.com/gin-gonic/gin"
    "github.com/go-playground/validator/v10"
    "github.com/google/uuid"
    "pganalytics-backend/internal/models"
    "pganalytics-backend/internal/services"
)

type AuthHandler struct {
    authService *services.AuthService
    validator   *validator.Validate
}

func NewAuthHandler(authService *services.AuthService) *AuthHandler {
    return &AuthHandler{
        authService: authService,
        validator:   validator.New(),
    }
}

// @Summary Register a new user
// @Description Create a new user account
// @Tags auth
// @Accept json
// @Produce json
// @Param user body models.UserCreate true "User registration data"
// @Success 201 {object} models.AuthResponse
// @Failure 400 {object} ErrorResponse
// @Failure 409 {object} ErrorResponse
// @Router /auth/register [post]
func (ah *AuthHandler) Register(c *gin.Context) {
    var userData models.UserCreate
    
    if err := c.ShouldBindJSON(&userData); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Invalid request data",
            Message: err.Error(),
        })
        return
    }
    
    if err := ah.validator.Struct(&userData); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Validation failed",
            Message: err.Error(),
        })
        return
    }
    
    response, err := ah.authService.Register(&userData)
    if err != nil {
        if strings.Contains(err.Error(), "already registered") {
            c.JSON(http.StatusConflict, ErrorResponse{
                Error:   "Email already registered",
                Message: "This email is already associated with an account",
            })
            return
        }
        
        c.JSON(http.StatusInternalServerError, ErrorResponse{
            Error:   "Registration failed",
            Message: "Unable to create account at this time",
        })
        return
    }
    
    c.JSON(http.StatusCreated, response)
}

// @Summary Login user
// @Description Authenticate user and return JWT tokens
// @Tags auth
// @Accept json
// @Produce json
// @Param credentials body models.UserLogin true "User login credentials"
// @Success 200 {object} models.AuthResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Router /auth/login [post]
func (ah *AuthHandler) Login(c *gin.Context) {
    var credentials models.UserLogin
    
    if err := c.ShouldBindJSON(&credentials); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Invalid request data",
            Message: err.Error(),
        })
        return
    }
    
    if err := ah.validator.Struct(&credentials); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Validation failed",
            Message: err.Error(),
        })
        return
    }
    
    response, err := ah.authService.Login(&credentials)
    if err != nil {
        c.JSON(http.StatusUnauthorized, ErrorResponse{
            Error:   "Authentication failed",
            Message: "Invalid email or password",
        })
        return
    }
    
    c.JSON(http.StatusOK, response)
}

// @Summary Refresh access token
// @Description Renew access token using refresh token
// @Tags auth
// @Accept json
// @Produce json
// @Param refresh body models.TokenRefreshRequest true "Refresh token"
// @Success 200 {object} models.AuthResponse
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Router /auth/refresh [post]
func (ah *AuthHandler) RefreshToken(c *gin.Context) {
    var request models.TokenRefreshRequest
    
    if err := c.ShouldBindJSON(&request); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Invalid request data",
            Message: err.Error(),
        })
        return
    }
    
    if err := ah.validator.Struct(&request); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Validation failed",
            Message: err.Error(),
        })
        return
    }
    
    response, err := ah.authService.RefreshToken(request.RefreshToken)
    if err != nil {
        c.JSON(http.StatusUnauthorized, ErrorResponse{
            Error:   "Token refresh failed",
            Message: "Invalid or expired refresh token",
        })
        return
    }
    
    c.JSON(http.StatusOK, response)
}

// @Summary Logout user
// @Description Revoke refresh token and logout user
// @Tags auth
// @Accept json
// @Produce json
// @Param refresh body models.TokenRefreshRequest true "Refresh token"
// @Success 200 {object} SuccessResponse
// @Failure 400 {object} ErrorResponse
// @Router /auth/logout [post]
func (ah *AuthHandler) Logout(c *gin.Context) {
    var request models.TokenRefreshRequest
    
    if err := c.ShouldBindJSON(&request); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Invalid request data",
            Message: err.Error(),
        })
        return
    }
    
    if err := ah.authService.Logout(request.RefreshToken); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Logout failed",
            Message: err.Error(),
        })
        return
    }
    
    c.JSON(http.StatusOK, SuccessResponse{
        Message: "Successfully logged out",
        Success: true,
    })
}

// @Summary Get user profile
// @Description Get current user profile information
// @Tags auth
// @Produce json
// @Security BearerAuth
// @Success 200 {object} models.User
// @Failure 401 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Router /auth/profile [get]
func (ah *AuthHandler) GetProfile(c *gin.Context) {
    userID, exists := c.Get("user_id")
    if !exists {
        c.JSON(http.StatusUnauthorized, ErrorResponse{
            Error:   "Unauthorized",
            Message: "User not found in context",
        })
        return
    }
    
    uid, ok := userID.(uuid.UUID)
    if !ok {
        c.JSON(http.StatusInternalServerError, ErrorResponse{
            Error:   "Internal error",
            Message: "Invalid user ID format",
        })
        return
    }
    
    user, err := ah.authService.GetUserProfile(uid)
    if err != nil {
        c.JSON(http.StatusNotFound, ErrorResponse{
            Error:   "User not found",
            Message: "User profile not found",
        })
        return
    }
    
    c.JSON(http.StatusOK, user)
}

// @Summary Update user profile
// @Description Update current user profile information
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param user body models.UserUpdate true "User update data"
// @Success 200 {object} models.User
// @Failure 400 {object} ErrorResponse
// @Failure 401 {object} ErrorResponse
// @Failure 409 {object} ErrorResponse
// @Router /auth/profile [put]
func (ah *AuthHandler) UpdateProfile(c *gin.Context) {
    userID, exists := c.Get("user_id")
    if !exists {
        c.JSON(http.StatusUnauthorized, ErrorResponse{
            Error:   "Unauthorized",
            Message: "User not found in context",
        })
        return
    }
    
    uid, ok := userID.(uuid.UUID)
    if !ok {
        c.JSON(http.StatusInternalServerError, ErrorResponse{
            Error:   "Internal error",
            Message: "Invalid user ID format",
        })
        return
    }
    
    var updateData models.UserUpdate
    
    if err := c.ShouldBindJSON(&updateData); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Invalid request data",
            Message: err.Error(),
        })
        return
    }
    
    if err := ah.validator.Struct(&updateData); err != nil {
        c.JSON(http.StatusBadRequest, ErrorResponse{
            Error:   "Validation failed",
            Message: err.Error(),
        })
        return
    }
    
    user, err := ah.authService.UpdateUserProfile(uid, &updateData)
    if err != nil {
        if strings.Contains(err.Error(), "already in use") {
            c.JSON(http.StatusConflict, ErrorResponse{
                Error:   "Email already in use",
                Message: "This email is already associated with another account",
            })
            return
        }
        
        c.JSON(http.StatusInternalServerError, ErrorResponse{
            Error:   "Update failed",
            Message: "Unable to update profile at this time",
        })
        return
    }
    
    c.JSON(http.StatusOK, user)
}

// Response structures
type ErrorResponse struct {
    Error   string `json:"error"`
    Message string `json:"message"`
}

type SuccessResponse struct {
    Message string `json:"message"`
    Success bool   `json:"success"`
}
