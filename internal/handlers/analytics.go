package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"pganalytics-backend/internal/models"
	"pganalytics-backend/internal/services"
)

// AnalyticsHandler gerencia endpoints de analytics
type AnalyticsHandler struct {
	service *services.AnalyticsService
}

// NewAnalyticsHandler cria um novo handler de analytics
func NewAnalyticsHandler(service *services.AnalyticsService) *AnalyticsHandler {
	return &AnalyticsHandler{service: service}
}

// @Summary      Obter queries lentas
// @Description  Retorna as queries SQL mais lentas do PostgreSQL
// @Tags         Analytics
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  models.AnalyticsResponse
// @Failure      401  {object}  models.ErrorResponse
// @Failure      500  {object}  models.ErrorResponse
// @Router       /api/v1/analytics/queries/slow [get]
func (h *AnalyticsHandler) GetSlowQueries(c *gin.Context) {
	// Adicionar dados do usuário autenticado
	response := h.service.GetSlowQueries()
	addUserContext(c, response)
	c.JSON(http.StatusOK, response)
}

// @Summary      Obter estatísticas das tabelas
// @Description  Retorna estatísticas detalhadas das tabelas do PostgreSQL
// @Tags         Analytics
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  models.AnalyticsResponse
// @Failure      401  {object}  models.ErrorResponse
// @Failure      500  {object}  models.ErrorResponse
// @Router       /api/v1/analytics/tables/stats [get]
func (h *AnalyticsHandler) GetTableStats(c *gin.Context) {
	response := h.service.GetTableStats()
	addUserContext(c, response)
	c.JSON(http.StatusOK, response)
}

// @Summary      Obter estatísticas de conexões
// @Description  Retorna informações sobre conexões ativas do PostgreSQL
// @Tags         Analytics
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  models.AnalyticsResponse
// @Failure      401  {object}  models.ErrorResponse
// @Failure      500  {object}  models.ErrorResponse
// @Router       /api/v1/analytics/connections [get]
func (h *AnalyticsHandler) GetConnectionStats(c *gin.Context) {
	response := h.service.GetConnectionStats()
	addUserContext(c, response)
	c.JSON(http.StatusOK, response)
}

// @Summary      Obter tamanho do banco
// @Description  Retorna informações sobre o tamanho do banco de dados
// @Tags         Analytics
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  models.AnalyticsResponse
// @Failure      401  {object}  models.ErrorResponse
// @Failure      500  {object}  models.ErrorResponse
// @Router       /api/v1/analytics/database/size [get]
func (h *AnalyticsHandler) GetDatabaseSize(c *gin.Context) {
	response := h.service.GetDatabaseSize()
	addUserContext(c, response)
	c.JSON(http.StatusOK, response)
}

// @Summary      Obter estatísticas de performance
// @Description  Retorna métricas de performance do PostgreSQL
// @Tags         Analytics
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  models.AnalyticsResponse
// @Failure      401  {object}  models.ErrorResponse
// @Failure      500  {object}  models.ErrorResponse
// @Router       /api/v1/analytics/performance [get]
func (h *AnalyticsHandler) GetPerformanceStats(c *gin.Context) {
	response := h.service.GetPerformanceStats()
	addUserContext(c, response)
	c.JSON(http.StatusOK, response)
}

// @Summary      Obter todas as estatísticas
// @Description  Retorna todas as métricas e estatísticas disponíveis
// @Tags         Analytics
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  models.AnalyticsResponse
// @Failure      401  {object}  models.ErrorResponse
// @Failure      500  {object}  models.ErrorResponse
// @Router       /api/v1/analytics/all [get]
func (h *AnalyticsHandler) GetFullAnalytics(c *gin.Context) {
	response := h.service.GetFullAnalytics()
	addUserContext(c, response)
	c.JSON(http.StatusOK, response)
}

// Função helper para adicionar contexto do usuário à resposta
func addUserContext(c *gin.Context, response *models.AnalyticsResponse) {
	response.User = gin.H{
		"id":    c.GetInt("user_id"),
		"email": c.GetString("email"),
		"role":  c.GetString("role"),
	}
}
