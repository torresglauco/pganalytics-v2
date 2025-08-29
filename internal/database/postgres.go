package database

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

// DB é um wrapper para sqlx.DB
type DB struct {
	*sqlx.DB
}

// NewDB cria uma nova conexão com o PostgreSQL
func NewDB() (*DB, error) {
	// Obter configurações do ambiente
	host := getEnv("DB_HOST", "postgres")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	password := getEnv("DB_PASSWORD", "postgres")
	dbname := getEnv("DB_NAME", "postgres")

	// Montar string de conexão
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname,
	)

	// Tentar conectar
	db, err := sqlx.Connect("postgres", dsn)
	if err != nil {
		log.Printf("⚠️ Erro ao conectar ao PostgreSQL: %v", err)
		log.Printf("⚠️ Usando dados mock para desenvolvimento")
		return nil, err
	}

	// Configurar connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	log.Printf("✅ Conectado ao PostgreSQL em %s:%s/%s", host, port, dbname)
	return &DB{db}, nil
}

// Ping verifica a conexão com o banco
func (db *DB) Ping() error {
	return db.DB.Ping()
}

// Função helper para obter variáveis de ambiente com fallback
func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
