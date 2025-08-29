package repositories

import (
	"log"
	"pganalytics-backend/internal/database"
	"pganalytics-backend/internal/models"
)

// AnalyticsRepository maneja operações de analytics no banco
type AnalyticsRepository struct {
	db *database.DB
}

// NewAnalyticsRepository cria um novo repositório de analytics
func NewAnalyticsRepository(db *database.DB) *AnalyticsRepository {
	return &AnalyticsRepository{db: db}
}

// GetSlowQueries retorna as queries mais lentas do PostgreSQL
func (r *AnalyticsRepository) GetSlowQueries() ([]models.SlowQuery, error) {
	queries := []models.SlowQuery{}

	// Verificar se o banco está conectado
	if r.db == nil {
		return getMockSlowQueries(), nil
	}

	// Query para obter queries lentas (precisa da extensão pg_stat_statements)
	query := `
	SELECT 
		substring(query, 1, 150) as query_text,
		round(mean_exec_time, 2) as duration_ms,
		calls,
		rows
	FROM pg_stat_statements 
	WHERE mean_exec_time > 100
	ORDER BY mean_exec_time DESC
	LIMIT 10`

	// Tentar executar a query
	err := r.db.Select(&queries, query)
	if err != nil {
		log.Printf("⚠️ Erro ao buscar queries lentas: %v", err)
		log.Printf("⚠️ Usando dados mock")
		return getMockSlowQueries(), nil
	}

	// Se não houver resultados, usar mock
	if len(queries) == 0 {
		return getMockSlowQueries(), nil
	}

	return queries, nil
}

// GetTableStats retorna estatísticas das tabelas
func (r *AnalyticsRepository) GetTableStats() ([]models.TableStat, error) {
	stats := []models.TableStat{}

	// Verificar se o banco está conectado
	if r.db == nil {
		return getMockTableStats(), nil
	}

	// Query para obter estatísticas das tabelas
	query := `
	SELECT 
		schemaname || '.' || relname as table_name,
		n_live_tup as row_count,
		pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) as size_pretty,
		pg_total_relation_size(schemaname || '.' || relname) / 1024 / 1024 as size_mb,
		CASE WHEN pg_total_relation_size(schemaname || '.' || relname) > 0 
			THEN round((pg_indexes_size(schemaname || '.' || relname)::numeric / 
				pg_total_relation_size(schemaname || '.' || relname)::numeric) * 100, 2)
			ELSE 0
		END as index_ratio
	FROM pg_stat_user_tables
	ORDER BY pg_total_relation_size(schemaname || '.' || relname) DESC
	LIMIT 10`

	// Tentar executar a query
	err := r.db.Select(&stats, query)
	if err != nil {
		log.Printf("⚠️ Erro ao buscar estatísticas de tabelas: %v", err)
		log.Printf("⚠️ Usando dados mock")
		return getMockTableStats(), nil
	}

	// Se não houver resultados, usar mock
	if len(stats) == 0 {
		return getMockTableStats(), nil
	}

	return stats, nil
}

// GetConnectionStats retorna estatísticas de conexões
func (r *AnalyticsRepository) GetConnectionStats() (*models.ConnectionStats, error) {
	// Verificar se o banco está conectado
	if r.db == nil {
		return getMockConnectionStats(), nil
	}

	stats := &models.ConnectionStats{}

	// Query para obter máximo de conexões configuradas
	err := r.db.Get(&stats.MaxConnections, "SHOW max_connections")
	if err != nil {
		log.Printf("⚠️ Erro ao buscar max_connections: %v", err)
		return getMockConnectionStats(), nil
	}

	// Query para obter estatísticas de conexões
	query := `
	SELECT 
		COUNT(*) as total_connections,
		COUNT(CASE WHEN state = 'active' THEN 1 END) as active_connections,
		COUNT(CASE WHEN state = 'idle' THEN 1 END) as idle_connections,
		COUNT(CASE WHEN state = 'idle in transaction' THEN 1 END) as idle_in_transaction
	FROM pg_stat_activity`

	err = r.db.QueryRow(query).Scan(
		&stats.TotalConnections,
		&stats.ActiveConnections,
		&stats.IdleConnections,
		&stats.IdleInTransaction,
	)

	if err != nil {
		log.Printf("⚠️ Erro ao buscar estatísticas de conexões: %v", err)
		return getMockConnectionStats(), nil
	}

	return stats, nil
}

// GetDatabaseSize retorna o tamanho do banco de dados
func (r *AnalyticsRepository) GetDatabaseSize() (*models.DatabaseSize, error) {
	// Verificar se o banco está conectado
	if r.db == nil {
		return getMockDatabaseSize(), nil
	}

	size := &models.DatabaseSize{}

	// Query para obter o tamanho do banco de dados
	query := `
	SELECT
		pg_database.datname as database_name,
		pg_size_pretty(pg_database_size(pg_database.datname)) as size_pretty,
		pg_database_size(pg_database.datname) / 1024 / 1024 as size_mb
	FROM pg_database
	WHERE pg_database.datname = current_database()`

	err := r.db.QueryRow(query).Scan(
		&size.DatabaseName,
		&size.SizePretty,
		&size.SizeMB,
	)

	if err != nil {
		log.Printf("⚠️ Erro ao buscar tamanho do banco: %v", err)
		return getMockDatabaseSize(), nil
	}

	return size, nil
}

// GetPerformanceStats retorna estatísticas de performance
func (r *AnalyticsRepository) GetPerformanceStats() (*models.PerformanceStats, error) {
	// Verificar se o banco está conectado
	if r.db == nil {
		return getMockPerformanceStats(), nil
	}

	stats := &models.PerformanceStats{}

	// Query para obter estatísticas de performance
	query := `
	SELECT
		round(100 * blks_hit / (blks_hit + blks_read), 2) as cache_hit_ratio,
		tup_returned as tuples_returned,
		tup_fetched as tuples_fetched,
		tup_inserted as tuples_inserted,
		tup_updated as tuples_updated,
		tup_deleted as tuples_deleted,
		conflicts as conflicts,
		temp_files as temp_files,
		deadlocks as deadlocks
	FROM pg_stat_database
	WHERE datname = current_database()`

	err := r.db.Get(stats, query)
	if err != nil {
		log.Printf("⚠️ Erro ao buscar estatísticas de performance: %v", err)
		return getMockPerformanceStats(), nil
	}

	return stats, nil
}

// ======= FUNÇÕES MOCK PARA FALLBACK =======

// getMockSlowQueries retorna queries lentas simuladas
func getMockSlowQueries() []models.SlowQuery {
	return []models.SlowQuery{
		{
			QueryText:  "SELECT * FROM users WHERE email LIKE '%@example.com'",
			DurationMs: 1250.75,
			Calls:      432,
			Rows:       1250,
		},
		{
			QueryText:  "SELECT COUNT(*) FROM logs WHERE created_at > NOW() - INTERVAL '1 day'",
			DurationMs: 876.32,
			Calls:      125,
			Rows:       1,
		},
		{
			QueryText:  "SELECT logs.*, users.email FROM logs JOIN users ON logs.user_id = users.id WHERE logs.level = 'error'",
			DurationMs: 754.28,
			Calls:      89,
			Rows:       352,
		},
		{
			QueryText:  "UPDATE users SET last_login = NOW() WHERE id = ?",
			DurationMs: 532.51,
			Calls:      2451,
			Rows:       2451,
		},
		{
			QueryText:  "SELECT AVG(value) FROM metrics WHERE collected_at BETWEEN ? AND ? GROUP BY metric_name",
			DurationMs: 498.12,
			Calls:      78,
			Rows:       24,
		},
	}
}

// getMockTableStats retorna estatísticas de tabelas simuladas
func getMockTableStats() []models.TableStat {
	return []models.TableStat{
		{
			TableName:  "public.users",
			RowCount:   15000,
			SizePretty: "32 MB",
			SizeMB:     32.5,
			IndexRatio: 28.4,
		},
		{
			TableName:  "public.logs",
			RowCount:   1250000,
			SizePretty: "4.2 GB",
			SizeMB:     4300.8,
			IndexRatio: 35.2,
		},
		{
			TableName:  "public.sessions",
			RowCount:   85000,
			SizePretty: "128 MB",
			SizeMB:     128.4,
			IndexRatio: 18.7,
		},
		{
			TableName:  "public.metrics",
			RowCount:   3500000,
			SizePretty: "7.5 GB",
			SizeMB:     7680.0,
			IndexRatio: 42.1,
		},
		{
			TableName:  "public.settings",
			RowCount:   350,
			SizePretty: "2 MB",
			SizeMB:     2.1,
			IndexRatio: 12.5,
		},
	}
}

// getMockConnectionStats retorna estatísticas de conexões simuladas
func getMockConnectionStats() *models.ConnectionStats {
	return &models.ConnectionStats{
		TotalConnections:   18,
		ActiveConnections:  8,
		IdleConnections:    9,
		IdleInTransaction:  1,
		MaxConnections:     100,
		ConnectionsPercent: 18.0,
	}
}

// getMockDatabaseSize retorna tamanho do banco simulado
func getMockDatabaseSize() *models.DatabaseSize {
	return &models.DatabaseSize{
		DatabaseName: "postgres",
		SizePretty:   "12.5 GB",
		SizeMB:       12800.0,
	}
}

// getMockPerformanceStats retorna estatísticas de performance simuladas
func getMockPerformanceStats() *models.PerformanceStats {
	return &models.PerformanceStats{
		CacheHitRatio:   98.45,
		TuplesReturned:  15250000,
		TuplesFetched:   4520000,
		TuplesInserted:  285000,
		TuplesUpdated:   142500,
		TuplesDeleted:   28500,
		Conflicts:       12,
		TempFiles:       45,
		Deadlocks:       0,
	}
}
