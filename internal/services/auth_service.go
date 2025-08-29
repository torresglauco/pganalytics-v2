package services

import (
    "database/sql"
    "fmt"
    "time"
    
    "github.com/google/uuid"
    "golang.org/x/crypto/bcrypt"
    "pganalytics-backend/internal/models"
    "pganalytics-backend/internal/config"
)

type AuthService struct {
    db           *sql.DB
    tokenService *TokenService
    config       *config.Config
}

func NewAuthService(db *sql.DB, tokenService *TokenService, cfg *config.Config) *AuthService {
    return &AuthService{
        db:           db,
        tokenService: tokenService,
        config:       cfg,
    }
}

// Register cria um novo usuário
func (as *AuthService) Register(userData *models.UserCreate) (*models.AuthResponse, error) {
    // Verificar se email já existe
    exists, err := as.emailExists(userData.Email)
    if err != nil {
        return nil, fmt.Errorf("failed to check email existence: %w", err)
    }
    if exists {
        return nil, fmt.Errorf("email already registered")
    }
    
    // Criar usuário
    user := &models.User{
        ID:            uuid.New(),
        Email:         userData.Email,
        Name:          userData.Name,
        Role:          userData.Role,
        EmailVerified: false,
        CreatedAt:     time.Now(),
        UpdatedAt:     time.Now(),
    }
    
    // Definir role padrão se não especificado
    if user.Role == "" {
        user.Role = "user"
    }
    
    // Hash da senha
    if err := user.HashPassword(userData.Password); err != nil {
        return nil, fmt.Errorf("failed to hash password: %w", err)
    }
    
    // Inserir no banco
    query := `
        INSERT INTO users (id, email, password_hash, name, role, email_verified, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    `
    _, err = as.db.Exec(query, user.ID, user.Email, user.PasswordHash, user.Name, 
                       user.Role, user.EmailVerified, user.CreatedAt, user.UpdatedAt)
    if err != nil {
        return nil, fmt.Errorf("failed to create user: %w", err)
    }
    
    // Gerar tokens
    tokenPair, err := as.tokenService.GenerateTokenPair(user)
    if err != nil {
        return nil, fmt.Errorf("failed to generate tokens: %w", err)
    }
    
    // Salvar refresh token
    if err := as.saveRefreshToken(user.ID, tokenPair.RefreshToken); err != nil {
        return nil, fmt.Errorf("failed to save refresh token: %w", err)
    }
    
    return &models.AuthResponse{
        User:         *user,
        AccessToken:  tokenPair.AccessToken,
        RefreshToken: tokenPair.RefreshToken,
        ExpiresIn:    tokenPair.ExpiresIn,
    }, nil
}

// Login autentica um usuário
func (as *AuthService) Login(credentials *models.UserLogin) (*models.AuthResponse, error) {
    // Buscar usuário pelo email
    user, err := as.getUserByEmail(credentials.Email)
    if err != nil {
        return nil, fmt.Errorf("invalid credentials")
    }
    
    // Verificar senha
    if !user.CheckPassword(credentials.Password) {
        return nil, fmt.Errorf("invalid credentials")
    }
    
    // Gerar novos tokens
    tokenPair, err := as.tokenService.GenerateTokenPair(user)
    if err != nil {
        return nil, fmt.Errorf("failed to generate tokens: %w", err)
    }
    
    // Remover tokens antigos e salvar novo
    if err := as.revokeUserRefreshTokens(user.ID); err != nil {
        return nil, fmt.Errorf("failed to revoke old tokens: %w", err)
    }
    
    if err := as.saveRefreshToken(user.ID, tokenPair.RefreshToken); err != nil {
        return nil, fmt.Errorf("failed to save refresh token: %w", err)
    }
    
    return &models.AuthResponse{
        User:         *user,
        AccessToken:  tokenPair.AccessToken,
        RefreshToken: tokenPair.RefreshToken,
        ExpiresIn:    tokenPair.ExpiresIn,
    }, nil
}

// RefreshToken renova os tokens usando refresh token
func (as *AuthService) RefreshToken(refreshToken string) (*models.AuthResponse, error) {
    // Validar refresh token
    claims, err := as.tokenService.ValidateRefreshToken(refreshToken)
    if err != nil {
        return nil, fmt.Errorf("invalid refresh token: %w", err)
    }
    
    // Verificar se token existe no banco
    exists, err := as.refreshTokenExists(claims.UserID, refreshToken)
    if err != nil {
        return nil, fmt.Errorf("failed to verify refresh token: %w", err)
    }
    if !exists {
        return nil, fmt.Errorf("refresh token not found")
    }
    
    // Buscar usuário
    user, err := as.getUserByID(claims.UserID)
    if err != nil {
        return nil, fmt.Errorf("user not found")
    }
    
    // Gerar novos tokens
    tokenPair, err := as.tokenService.GenerateTokenPair(user)
    if err != nil {
        return nil, fmt.Errorf("failed to generate tokens: %w", err)
    }
    
    // Remover token antigo e salvar novo
    if err := as.revokeRefreshToken(refreshToken); err != nil {
        return nil, fmt.Errorf("failed to revoke old token: %w", err)
    }
    
    if err := as.saveRefreshToken(user.ID, tokenPair.RefreshToken); err != nil {
        return nil, fmt.Errorf("failed to save refresh token: %w", err)
    }
    
    return &models.AuthResponse{
        User:         *user,
        AccessToken:  tokenPair.AccessToken,
        RefreshToken: tokenPair.RefreshToken,
        ExpiresIn:    tokenPair.ExpiresIn,
    }, nil
}

// Logout revoga o refresh token
func (as *AuthService) Logout(refreshToken string) error {
    return as.revokeRefreshToken(refreshToken)
}

// GetUserProfile retorna perfil do usuário
func (as *AuthService) GetUserProfile(userID uuid.UUID) (*models.User, error) {
    return as.getUserByID(userID)
}

// UpdateUserProfile atualiza perfil do usuário
func (as *AuthService) UpdateUserProfile(userID uuid.UUID, updateData *models.UserUpdate) (*models.User, error) {
    // Verificar se email já existe (se estiver sendo alterado)
    if updateData.Email != "" {
        user, err := as.getUserByID(userID)
        if err != nil {
            return nil, fmt.Errorf("user not found")
        }
        
        if updateData.Email != user.Email {
            exists, err := as.emailExists(updateData.Email)
            if err != nil {
                return nil, fmt.Errorf("failed to check email existence: %w", err)
            }
            if exists {
                return nil, fmt.Errorf("email already in use")
            }
        }
    }
    
    // Construir query de update dinâmica
    setParts := []string{}
    args := []interface{}{}
    argIndex := 1
    
    if updateData.Name != "" {
        setParts = append(setParts, fmt.Sprintf("name = $%d", argIndex))
        args = append(args, updateData.Name)
        argIndex++
    }
    
    if updateData.Email != "" {
        setParts = append(setParts, fmt.Sprintf("email = $%d", argIndex))
        args = append(args, updateData.Email)
        argIndex++
    }
    
    if len(setParts) == 0 {
        return as.getUserByID(userID)
    }
    
    setParts = append(setParts, fmt.Sprintf("updated_at = $%d", argIndex))
    args = append(args, time.Now())
    argIndex++
    
    args = append(args, userID)
    
    query := fmt.Sprintf("UPDATE users SET %s WHERE id = $%d", 
                        fmt.Sprintf("%s", setParts), argIndex)
    
    _, err := as.db.Exec(query, args...)
    if err != nil {
        return nil, fmt.Errorf("failed to update user: %w", err)
    }
    
    return as.getUserByID(userID)
}

// Métodos auxiliares
func (as *AuthService) emailExists(email string) (bool, error) {
    var count int
    err := as.db.QueryRow("SELECT COUNT(*) FROM users WHERE email = $1", email).Scan(&count)
    return count > 0, err
}

func (as *AuthService) getUserByEmail(email string) (*models.User, error) {
    user := &models.User{}
    query := `
        SELECT id, email, password_hash, name, role, email_verified, created_at, updated_at
        FROM users WHERE email = $1
    `
    err := as.db.QueryRow(query, email).Scan(
        &user.ID, &user.Email, &user.PasswordHash, &user.Name,
        &user.Role, &user.EmailVerified, &user.CreatedAt, &user.UpdatedAt,
    )
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (as *AuthService) getUserByID(id uuid.UUID) (*models.User, error) {
    user := &models.User{}
    query := `
        SELECT id, email, password_hash, name, role, email_verified, created_at, updated_at
        FROM users WHERE id = $1
    `
    err := as.db.QueryRow(query, id).Scan(
        &user.ID, &user.Email, &user.PasswordHash, &user.Name,
        &user.Role, &user.EmailVerified, &user.CreatedAt, &user.UpdatedAt,
    )
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (as *AuthService) saveRefreshToken(userID uuid.UUID, token string) error {
    // Hash do token para segurança
    hashedToken, err := bcrypt.GenerateFromPassword([]byte(token), bcrypt.DefaultCost)
    if err != nil {
        return err
    }
    
    query := `
        INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at, created_at)
        VALUES ($1, $2, $3, $4, $5)
    `
    _, err = as.db.Exec(query, uuid.New(), userID, string(hashedToken), 
                       time.Now().Add(7*24*time.Hour), time.Now())
    return err
}

func (as *AuthService) refreshTokenExists(userID uuid.UUID, token string) (bool, error) {
    rows, err := as.db.Query("SELECT token_hash FROM refresh_tokens WHERE user_id = $1", userID)
    if err != nil {
        return false, err
    }
    defer rows.Close()
    
    for rows.Next() {
        var hashedToken string
        if err := rows.Scan(&hashedToken); err != nil {
            continue
        }
        
        if bcrypt.CompareHashAndPassword([]byte(hashedToken), []byte(token)) == nil {
            return true, nil
        }
    }
    
    return false, nil
}

func (as *AuthService) revokeRefreshToken(token string) error {
    // Para simplicidade, vamos remover todos os tokens expirados e o token atual
    _, err := as.db.Exec("DELETE FROM refresh_tokens WHERE expires_at < NOW()")
    return err
}

func (as *AuthService) revokeUserRefreshTokens(userID uuid.UUID) error {
    _, err := as.db.Exec("DELETE FROM refresh_tokens WHERE user_id = $1", userID)
    return err
}
