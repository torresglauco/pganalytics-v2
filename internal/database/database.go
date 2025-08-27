package database

import (
	"context"
	"pganalytics-backend/internal/config"

	"github.com/jackc/pgx/v5/pgxpool"
)

func Connect(cfg *config.Config) (*pgxpool.Pool, error) {
	db, err := pgxpool.New(context.Background(), cfg.DatabaseURL())
	if err != nil {
		return nil, err
	}

	// Test connection
	if err := db.Ping(context.Background()); err != nil {
		return nil, err
	}

	return db, nil
}
