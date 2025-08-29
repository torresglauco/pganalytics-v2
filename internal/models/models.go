package models

import (
    "time"
    "github.com/golang-jwt/jwt/v5"
)

// User representa um usuário do sistema
// @Description Usuário do sistema PG Analytics
type User struct {
    ID        int       `json:"id" example:"1"`                                    // ID único do usuário
    Username  string    `json:"username" example:"admin"`                          // Nome de usuário
    Email     string    `json:"email" example:"admin@pganalytics.com"`            // Email do usuário
    Password  string    `json:"-"`                                                 // Senha (não exposta)
    Role      string    `json:"role" example:"admin"`                              // Papel do usuário
    CreatedAt time.Time `json:"created_at" example:"2024-01-01T00:00:00Z"`        // Data de criação
    UpdatedAt time.Time `json:"updated_at" example:"2024-01-01T00:00:00Z"`        // Data de atualização
}

// Claims para JWT
type Claims struct {
    UserID int    `json:"user_id"`
    Email  string `json:"email"`
    Role   string `json:"role"`
    jwt.RegisteredClaims
}

// LoginRequest representa uma requisição de login
// @Description Dados necessários para autenticação
type LoginRequest struct {
    Username string `json:"username" binding:"required" example:"admin"`      // Nome de usuário ou email
    Password string `json:"password" binding:"required" example:"admin123"`   // Senha do usuário
}

// LoginResponse representa a resposta de um login bem-sucedido
// @Description Resposta da autenticação com token JWT
type LoginResponse struct {
    Token     string `json:"token" example:"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."`  // Token JWT
    ExpiresIn int    `json:"expires_in" example:"86400"`                                    // Tempo de expiração em segundos
    User      string `json:"user" example:"admin@pganalytics.com"`                         // Email do usuário
}

// ErrorResponse representa uma resposta de erro
// @Description Resposta padrão para erros
type ErrorResponse struct {
    Error string `json:"error" example:"Invalid credentials"`  // Mensagem de erro
}

// HealthResponse representa a resposta do health check
// @Description Status de saúde da API
type HealthResponse struct {
    Status      string `json:"status" example:"healthy"`                    // Status da API
    Message     string `json:"message" example:"PG Analytics API funcionando"` // Mensagem descritiva
    Environment string `json:"environment" example:"production"`            // Ambiente de execução
    Version     string `json:"version" example:"1.0"`                       // Versão da API
    Port        string `json:"port" example:"8080"`                         // Porta da API
    Database    string `json:"database" example:"connected"`                // Status do banco
}

// MetricsResponse representa as métricas do sistema
// @Description Métricas de performance e uso do sistema
type MetricsResponse struct {
    Success     bool        `json:"success" example:"true"`                      // Sucesso da operação
    Message     string      `json:"message" example:"Métricas sistema"`         // Mensagem
    Environment string      `json:"environment" example:"production"`           // Ambiente
    Source      string      `json:"source" example:"api"`                       // Fonte dos dados
    Timestamp   int64       `json:"timestamp" example:"1672531200"`             // Timestamp Unix
    User        interface{} `json:"user"`                                       // Dados do usuário
    Metrics     interface{} `json:"metrics"`                                    // Dados das métricas
}

// ProfileResponse representa o perfil do usuário
// @Description Dados do perfil do usuário autenticado
type ProfileResponse struct {
    UserID  int    `json:"user_id" example:"1"`                          // ID do usuário
    Email   string `json:"email" example:"admin@pganalytics.com"`        // Email do usuário
    Role    string `json:"role" example:"admin"`                         // Papel do usuário
    Message string `json:"message" example:"Profile data"`               // Mensagem
}
