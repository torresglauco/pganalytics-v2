package middleware

import (
    "net/http"
    "strings"
    
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "pganalytics-backend/internal/services"
)

type AuthMiddleware struct {
    tokenService *services.TokenService
}

func NewAuthMiddleware(tokenService *services.TokenService) *AuthMiddleware {
    return &AuthMiddleware{
        tokenService: tokenService,
    }
}

// RequireAuth middleware que requer autenticação válida
func (am *AuthMiddleware) RequireAuth() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := am.extractToken(c)
        if token == "" {
            c.JSON(http.StatusUnauthorized, gin.H{
                "error":   "Unauthorized",
                "message": "Missing or invalid authorization header",
            })
            c.Abort()
            return
        }
        
        claims, err := am.tokenService.ValidateAccessToken(token)
        if err != nil {
            c.JSON(http.StatusUnauthorized, gin.H{
                "error":   "Unauthorized", 
                "message": "Invalid or expired token",
            })
            c.Abort()
            return
        }
        
        // Adicionar informações do usuário ao contexto
        c.Set("user_id", claims.UserID)
        c.Set("user_email", claims.Email)
        c.Set("user_role", claims.Role)
        
        c.Next()
    }
}

// RequireRole middleware que requer role específica
func (am *AuthMiddleware) RequireRole(allowedRoles ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        userRole, exists := c.Get("user_role")
        if !exists {
            c.JSON(http.StatusUnauthorized, gin.H{
                "error":   "Unauthorized",
                "message": "User role not found in context",
            })
            c.Abort()
            return
        }
        
        role, ok := userRole.(string)
        if !ok {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error":   "Internal error",
                "message": "Invalid role format",
            })
            c.Abort()
            return
        }
        
        // Verificar se o role está permitido
        for _, allowedRole := range allowedRoles {
            if role == allowedRole {
                c.Next()
                return
            }
        }
        
        c.JSON(http.StatusForbidden, gin.H{
            "error":   "Forbidden",
            "message": "Insufficient permissions for this action",
        })
        c.Abort()
    }
}

// RequireAdmin middleware que requer role de admin
func (am *AuthMiddleware) RequireAdmin() gin.HandlerFunc {
    return am.RequireRole("admin")
}

// RequireUserOrAdmin middleware que permite user ou admin
func (am *AuthMiddleware) RequireUserOrAdmin() gin.HandlerFunc {
    return am.RequireRole("admin", "user")
}

// OptionalAuth middleware que permite acesso com ou sem autenticação
func (am *AuthMiddleware) OptionalAuth() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := am.extractToken(c)
        if token == "" {
            c.Next()
            return
        }
        
        claims, err := am.tokenService.ValidateAccessToken(token)
        if err != nil {
            // Token inválido, mas continue sem autenticação
            c.Next()
            return
        }
        
        // Adicionar informações do usuário ao contexto se token válido
        c.Set("user_id", claims.UserID)
        c.Set("user_email", claims.Email)
        c.Set("user_role", claims.Role)
        c.Set("authenticated", true)
        
        c.Next()
    }
}

// RequireOwnership middleware que verifica se o usuário é dono do recurso
func (am *AuthMiddleware) RequireOwnership(resourceUserIDParam string) gin.HandlerFunc {
    return func(c *gin.Context) {
        currentUserID, exists := c.Get("user_id")
        if !exists {
            c.JSON(http.StatusUnauthorized, gin.H{
                "error":   "Unauthorized",
                "message": "User not authenticated",
            })
            c.Abort()
            return
        }
        
        currentUID, ok := currentUserID.(uuid.UUID)
        if !ok {
            c.JSON(http.StatusInternalServerError, gin.H{
                "error":   "Internal error",
                "message": "Invalid user ID format",
            })
            c.Abort()
            return
        }
        
        // Verificar se é admin (admin pode acessar qualquer recurso)
        userRole, _ := c.Get("user_role")
        if role, ok := userRole.(string); ok && role == "admin" {
            c.Next()
            return
        }
        
        // Obter ID do recurso do parâmetro da URL
        resourceUserIDStr := c.Param(resourceUserIDParam)
        if resourceUserIDStr == "" {
            c.JSON(http.StatusBadRequest, gin.H{
                "error":   "Bad request",
                "message": "Resource user ID not provided",
            })
            c.Abort()
            return
        }
        
        resourceUserID, err := uuid.Parse(resourceUserIDStr)
        if err != nil {
            c.JSON(http.StatusBadRequest, gin.H{
                "error":   "Bad request",
                "message": "Invalid resource user ID format",
            })
            c.Abort()
            return
        }
        
        // Verificar ownership
        if currentUID != resourceUserID {
            c.JSON(http.StatusForbidden, gin.H{
                "error":   "Forbidden",
                "message": "You can only access your own resources",
            })
            c.Abort()
            return
        }
        
        c.Next()
    }
}

// extractToken extrai o token do header Authorization
func (am *AuthMiddleware) extractToken(c *gin.Context) string {
    authHeader := c.GetHeader("Authorization")
    if authHeader == "" {
        return ""
    }
    
    // Formato esperado: "Bearer <token>"
    parts := strings.SplitN(authHeader, " ", 2)
    if len(parts) != 2 || parts[0] != "Bearer" {
        return ""
    }
    
    return parts[1]
}

// GetCurrentUserID helper para obter user ID do contexto
func GetCurrentUserID(c *gin.Context) (uuid.UUID, bool) {
    userID, exists := c.Get("user_id")
    if !exists {
        return uuid.Nil, false
    }
    
    uid, ok := userID.(uuid.UUID)
    return uid, ok
}

// GetCurrentUserRole helper para obter role do contexto
func GetCurrentUserRole(c *gin.Context) (string, bool) {
    userRole, exists := c.Get("user_role")
    if !exists {
        return "", false
    }
    
    role, ok := userRole.(string)
    return role, ok
}

// IsAuthenticated helper para verificar se usuário está autenticado
func IsAuthenticated(c *gin.Context) bool {
    _, exists := c.Get("user_id")
    return exists
}

// IsAdmin helper para verificar se usuário é admin
func IsAdmin(c *gin.Context) bool {
    role, exists := GetCurrentUserRole(c)
    return exists && role == "admin"
}
