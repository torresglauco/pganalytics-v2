package config

import (
    "fmt"
    "os"
    "strconv"
    "log"
)

type Config struct {
    Database DatabaseConfig
    Server   ServerConfig
    Auth     AuthConfig
}

type DatabaseConfig struct {
    Host     string
    Port     int
    Name     string
    User     string
    Password string
}

type ServerConfig struct {
    Port        int
    Environment string
    LogLevel    string
}

type AuthConfig struct {
    JWTSecret string
}

func Load() (*Config, error) {
    cfg := &Config{
        Database: DatabaseConfig{
            Host:     getEnv("DB_HOST", "localhost"),
            Port:     getEnvInt("DB_PORT", 5432),
            Name:     getEnv("DB_NAME", "pganalytics"),
            User:     getEnv("DB_USER", "admin"),
            Password: getEnv("DB_PASSWORD", ""),
        },
        Server: ServerConfig{
            Port:        getEnvInt("PORT", 8080),
            Environment: getEnv("ENVIRONMENT", "development"),
            LogLevel:    getEnv("LOG_LEVEL", "info"),
        },
        Auth: AuthConfig{
            JWTSecret: getEnv("JWT_SECRET", ""),
        },
    }
    
    // Validate required fields
    if cfg.Auth.JWTSecret == "" {
        return nil, fmt.Errorf("JWT_SECRET is required")
    }
    
    if cfg.Database.Password == "" {
        log.Println("Warning: DB_PASSWORD not set")
    }
    
    return cfg, nil
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
    if value := os.Getenv(key); value != "" {
        if intValue, err := strconv.Atoi(value); err == nil {
            return intValue
        }
    }
    return defaultValue
}
