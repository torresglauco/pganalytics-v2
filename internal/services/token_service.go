package services

import (
    "crypto/rand"
    "encoding/hex"
    "fmt"
    "time"
    
    "github.com/golang-jwt/jwt/v5"
    "github.com/google/uuid"
    "pganalytics-backend/internal/models"
    "pganalytics-backend/internal/config"
)

type TokenService struct {
    config *config.Config
}

type JWTClaims struct {
    UserID uuid.UUID `json:"user_id"`
    Email  string    `json:"email"`
    Role   string    `json:"role"`
    Type   string    `json:"type"` // "access" ou "refresh"
    jwt.RegisteredClaims
}

type TokenPair struct {
    AccessToken  string `json:"access_token"`
    RefreshToken string `json:"refresh_token"`
    ExpiresIn    int64  `json:"expires_in"`
}

func NewTokenService(cfg *config.Config) *TokenService {
    return &TokenService{
        config: cfg,
    }
}

// GenerateTokenPair gera par de tokens (access + refresh)
func (ts *TokenService) GenerateTokenPair(user *models.User) (*TokenPair, error) {
    now := time.Now()
    
    // Access Token (15 minutos)
    accessExpiry := now.Add(15 * time.Minute)
    accessClaims := JWTClaims{
        UserID: user.ID,
        Email:  user.Email,
        Role:   user.Role,
        Type:   "access",
        RegisteredClaims: jwt.RegisteredClaims{
            Subject:   user.ID.String(),
            IssuedAt:  jwt.NewNumericDate(now),
            ExpiresAt: jwt.NewNumericDate(accessExpiry),
            NotBefore: jwt.NewNumericDate(now),
            Issuer:    "pganalytics",
            Audience:  []string{"pganalytics-api"},
        },
    }
    
    accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims)
    accessTokenString, err := accessToken.SignedString([]byte(ts.config.JWTSecret))
    if err != nil {
        return nil, fmt.Errorf("failed to sign access token: %w", err)
    }
    
    // Refresh Token (7 dias)
    refreshExpiry := now.Add(7 * 24 * time.Hour)
    refreshClaims := JWTClaims{
        UserID: user.ID,
        Email:  user.Email,
        Role:   user.Role,
        Type:   "refresh",
        RegisteredClaims: jwt.RegisteredClaims{
            Subject:   user.ID.String(),
            IssuedAt:  jwt.NewNumericDate(now),
            ExpiresAt: jwt.NewNumericDate(refreshExpiry),
            NotBefore: jwt.NewNumericDate(now),
            Issuer:    "pganalytics",
            Audience:  []string{"pganalytics-api"},
        },
    }
    
    refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
    refreshTokenString, err := refreshToken.SignedString([]byte(ts.config.JWTSecret))
    if err != nil {
        return nil, fmt.Errorf("failed to sign refresh token: %w", err)
    }
    
    return &TokenPair{
        AccessToken:  accessTokenString,
        RefreshToken: refreshTokenString,
        ExpiresIn:    accessExpiry.Unix(),
    }, nil
}

// ValidateToken valida e parseia um token JWT
func (ts *TokenService) ValidateToken(tokenString string) (*JWTClaims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
        // Verifica o método de assinatura
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
        }
        return []byte(ts.config.JWTSecret), nil
    })
    
    if err != nil {
        return nil, fmt.Errorf("failed to parse token: %w", err)
    }
    
    if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
        return claims, nil
    }
    
    return nil, fmt.Errorf("invalid token claims")
}

// ValidateAccessToken valida especificamente um access token
func (ts *TokenService) ValidateAccessToken(tokenString string) (*JWTClaims, error) {
    claims, err := ts.ValidateToken(tokenString)
    if err != nil {
        return nil, err
    }
    
    if claims.Type != "access" {
        return nil, fmt.Errorf("token is not an access token")
    }
    
    return claims, nil
}

// ValidateRefreshToken valida especificamente um refresh token
func (ts *TokenService) ValidateRefreshToken(tokenString string) (*JWTClaims, error) {
    claims, err := ts.ValidateToken(tokenString)
    if err != nil {
        return nil, err
    }
    
    if claims.Type != "refresh" {
        return nil, fmt.Errorf("token is not a refresh token")
    }
    
    return claims, nil
}

// GenerateRandomToken gera token aleatório para password reset
func (ts *TokenService) GenerateRandomToken() (string, error) {
    bytes := make([]byte, 32)
    if _, err := rand.Read(bytes); err != nil {
        return "", err
    }
    return hex.EncodeToString(bytes), nil
}

// IsTokenExpired verifica se o token expirou
func (ts *TokenService) IsTokenExpired(claims *JWTClaims) bool {
    return time.Now().After(claims.ExpiresAt.Time)
}

// GetUserIDFromToken extrai UserID do token
func (ts *TokenService) GetUserIDFromToken(tokenString string) (uuid.UUID, error) {
    claims, err := ts.ValidateToken(tokenString)
    if err != nil {
        return uuid.Nil, err
    }
    return claims.UserID, nil
}

// RevokeToken adiciona token à blacklist (implementar com Redis/DB)
func (ts *TokenService) RevokeToken(tokenString string) error {
    // TODO: Implementar blacklist de tokens
    // Por enquanto, apenas validamos que o token é válido
    _, err := ts.ValidateToken(tokenString)
    return err
}
