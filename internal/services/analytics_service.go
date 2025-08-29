package services

import (
	"log"
	"os"
	"time"
	"pganalytics-backend/internal/models"
	"pganalytics-backend/internal/repositories"
)

// AnalyticsService gerencia operações de analytics
type AnalyticsService struct {
	repo *repositories.AnalyticsRepository
}

// NewAnalyticsService cria um novo serviço de analytics
func NewAnalyticsService(repo *repositories.AnalyticsRepository) *AnalyticsService {
	return &AnalyticsService{repo: repo}
}

// GetSlowQueries retorna as queries mais lentas
func (s *AnalyticsService) GetSlowQueries() *models.AnalyticsResponse {
	queries, err := s.repo.GetSlowQueries()
	if err != nil {
		log.Printf("Erro ao obter queries lentas: %v", err)
		return createErrorResponse("Erro ao obter queries lentas")
	}

	return &models.AnalyticsResponse{
		Success:     true,
		Message:     "Queries lentas obtidas com sucesso",
		Timestamp:   time.Now().Unix(),
		Environment: getEnvironment(),
		Data: map[string]interface{}{
			"queries":      queries,
			"total":        len(queries),
			"last_updated": time.Now().Format(time.RFC3339),
		},
	}
}

// GetTableStats retorna estatísticas das tabelas
func (s *AnalyticsService) GetTableStats() *models.AnalyticsResponse {
	stats, err := s.repo.GetTableStats()
	if err != nil {
		log.Printf("Erro ao obter estatísticas das tabelas: %v", err)
		return createErrorResponse("Erro ao obter estatísticas das tabelas")
	}

	return &models.AnalyticsResponse{
		Success:     true,
		Message:     "Estatísticas das tabelas obtidas com sucesso",
		Timestamp:   time.Now().Unix(),
		Environment: getEnvironment(),
		Data: map[string]interface{}{
			"tables":       stats,
			"total":        len(stats),
			"last_updated": time.Now().Format(time.RFC3339),
		},
	}
}

// GetConnectionStats retorna estatísticas de conexões
func (s *AnalyticsService) GetConnectionStats() *models.AnalyticsResponse {
	stats, err := s.repo.GetConnectionStats()
	if err != nil {
		log.Printf("Erro ao obter estatísticas de conexões: %v", err)
		return createErrorResponse("Erro ao obter estatísticas de conexões")
	}

	// Calcular percentual de conexões
	if stats.MaxConnections > 0 {
		stats.ConnectionsPercent = float64(stats.TotalConnections) / float64(stats.MaxConnections) * 100
	}

	return &models.AnalyticsResponse{
		Success:     true,
		Message:     "Estatísticas de conexões obtidas com sucesso",
		Timestamp:   time.Now().Unix(),
		Environment: getEnvironment(),
		Data: map[string]interface{}{
			"connections":  stats,
			"last_updated": time.Now().Format(time.RFC3339),
		},
	}
}

// GetDatabaseSize retorna o tamanho do banco de dados
func (s *AnalyticsService) GetDatabaseSize() *models.AnalyticsResponse {
	size, err := s.repo.GetDatabaseSize()
	if err != nil {
		log.Printf("Erro ao obter tamanho do banco: %v", err)
		return createErrorResponse("Erro ao obter tamanho do banco")
	}

	return &models.AnalyticsResponse{
		Success:     true,
		Message:     "Tamanho do banco obtido com sucesso",
		Timestamp:   time.Now().Unix(),
		Environment: getEnvironment(),
		Data: map[string]interface{}{
			"database":     size,
			"last_updated": time.Now().Format(time.RFC3339),
		},
	}
}

// GetPerformanceStats retorna estatísticas de performance
func (s *AnalyticsService) GetPerformanceStats() *models.AnalyticsResponse {
	stats, err := s.repo.GetPerformanceStats()
	if err != nil {
		log.Printf("Erro ao obter estatísticas de performance: %v", err)
		return createErrorResponse("Erro ao obter estatísticas de performance")
	}

	return &models.AnalyticsResponse{
		Success:     true,
		Message:     "Estatísticas de performance obtidas com sucesso",
		Timestamp:   time.Now().Unix(),
		Environment: getEnvironment(),
		Data: map[string]interface{}{
			"performance":  stats,
			"last_updated": time.Now().Format(time.RFC3339),
		},
	}
}

// GetFullAnalytics retorna todas as estatísticas
func (s *AnalyticsService) GetFullAnalytics() *models.AnalyticsResponse {
	// Obter todas as estatísticas
	slowQueries, _ := s.repo.GetSlowQueries()
	tableStats, _ := s.repo.GetTableStats()
	connectionStats, _ := s.repo.GetConnectionStats()
	databaseSize, _ := s.repo.GetDatabaseSize()
	performanceStats, _ := s.repo.GetPerformanceStats()

	// Calcular percentual de conexões
	if connectionStats != nil && connectionStats.MaxConnections > 0 {
		connectionStats.ConnectionsPercent = float64(connectionStats.TotalConnections) / float64(connectionStats.MaxConnections) * 100
	}

	return &models.AnalyticsResponse{
		Success:     true,
		Message:     "Estatísticas completas obtidas com sucesso",
		Timestamp:   time.Now().Unix(),
		Environment: getEnvironment(),
		Data: map[string]interface{}{
			"slow_queries":      slowQueries,
			"tables":            tableStats,
			"connections":       connectionStats,
			"database_size":     databaseSize,
			"performance_stats": performanceStats,
			"last_updated":      time.Now().Format(time.RFC3339),
		},
	}
}

// Função helper para criar resposta de erro
func createErrorResponse(message string) *models.AnalyticsResponse {
	return &models.AnalyticsResponse{
		Success:     false,
		Message:     message,
		Timestamp:   time.Now().Unix(),
		Environment: getEnvironment(),
		Data:        nil,
	}
}

// Função helper para obter ambiente
func getEnvironment() string {
	env := os.Getenv("APP_ENV")
	if env == "" {
		return "development"
	}
	return env
}
