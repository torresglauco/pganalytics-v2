package models

import (
    "time"
    "github.com/google/uuid"
    "golang.org/x/crypto/bcrypt"
)

// User representa um usuário do sistema
type User struct {
    ID            uuid.UUID `json:"id" db:"id"`
    Email         string    `json:"email" db:"email" validate:"required,email"`
    PasswordHash  string    `json:"-" db:"password_hash"`
    Name          string    `json:"name" db:"name" validate:"required,min=2,max=100"`
    Role          string    `json:"role" db:"role" validate:"required,oneof=admin user readonly"`
    EmailVerified bool      `json:"email_verified" db:"email_verified"`
    CreatedAt     time.Time `json:"created_at" db:"created_at"`
    UpdatedAt     time.Time `json:"updated_at" db:"updated_at"`
}

// UserCreate representa dados para criar usuário
type UserCreate struct {
    Email    string `json:"email" validate:"required,email,max=255"`
    Password string `json:"password" validate:"required,min=8,max=100"`
    Name     string `json:"name" validate:"required,min=2,max=100"`
    Role     string `json:"role,omitempty" validate:"omitempty,oneof=admin user readonly"`
}

// UserLogin representa dados de login
type UserLogin struct {
    Email    string `json:"email" validate:"required,email"`
    Password string `json:"password" validate:"required"`
}

// UserUpdate representa dados para atualizar usuário
type UserUpdate struct {
    Name  string `json:"name,omitempty" validate:"omitempty,min=2,max=100"`
    Email string `json:"email,omitempty" validate:"omitempty,email,max=255"`
}

// RefreshToken representa um token de refresh
type RefreshToken struct {
    ID        uuid.UUID `json:"id" db:"id"`
    UserID    uuid.UUID `json:"user_id" db:"user_id"`
    TokenHash string    `json:"-" db:"token_hash"`
    ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// PasswordReset representa um token de reset de senha
type PasswordReset struct {
    ID        uuid.UUID `json:"id" db:"id"`
    Email     string    `json:"email" db:"email"`
    TokenHash string    `json:"-" db:"token_hash"`
    ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
    UsedAt    *time.Time `json:"used_at,omitempty" db:"used_at"`
    CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// AuthResponse representa resposta de autenticação
type AuthResponse struct {
    User         User   `json:"user"`
    AccessToken  string `json:"access_token"`
    RefreshToken string `json:"refresh_token"`
    ExpiresIn    int64  `json:"expires_in"`
}

// TokenRefreshRequest representa request de refresh
type TokenRefreshRequest struct {
    RefreshToken string `json:"refresh_token" validate:"required"`
}

// PasswordResetRequest representa request de reset
type PasswordResetRequest struct {
    Email string `json:"email" validate:"required,email"`
}

// PasswordResetConfirm representa confirmação de reset
type PasswordResetConfirm struct {
    Token       string `json:"token" validate:"required"`
    NewPassword string `json:"new_password" validate:"required,min=8,max=100"`
}

// HashPassword gera hash da senha
func (u *User) HashPassword(password string) error {
    hashedBytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    if err != nil {
        return err
    }
    u.PasswordHash = string(hashedBytes)
    return nil
}

// CheckPassword verifica se a senha está correta
func (u *User) CheckPassword(password string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
    return err == nil
}

// IsAdmin verifica se o usuário é admin
func (u *User) IsAdmin() bool {
    return u.Role == "admin"
}

// CanRead verifica se pode ler dados
func (u *User) CanRead() bool {
    return u.Role == "admin" || u.Role == "user" || u.Role == "readonly"
}

// CanWrite verifica se pode escrever dados
func (u *User) CanWrite() bool {
    return u.Role == "admin" || u.Role == "user"
}
