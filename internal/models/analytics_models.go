package models

// SlowQuery representa uma query lenta do PostgreSQL
type SlowQuery struct {
	QueryText  string  `json:"query" db:"query_text"`        // Texto da query
	DurationMs float64 `json:"duration_ms" db:"duration_ms"` // Duração em milissegundos
	Calls      int     `json:"calls" db:"calls"`             // Número de chamadas
	Rows       int     `json:"rows" db:"rows"`               // Número de linhas retornadas
}

// TableStat representa estatísticas de uma tabela
type TableStat struct {
	TableName  string  `json:"table_name" db:"table_name"`   // Nome da tabela
	RowCount   int     `json:"row_count" db:"row_count"`     // Número de linhas
	SizePretty string  `json:"size_pretty" db:"size_pretty"` // Tamanho formatado
	SizeMB     float64 `json:"size_mb" db:"size_mb"`         // Tamanho em MB
	IndexRatio float64 `json:"index_ratio" db:"index_ratio"` // Proporção do índice
}

// ConnectionStats representa estatísticas de conexões
type ConnectionStats struct {
	TotalConnections   int     `json:"total_connections" db:"total_connections"`     // Total de conexões
	ActiveConnections  int     `json:"active_connections" db:"active_connections"`   // Conexões ativas
	IdleConnections    int     `json:"idle_connections" db:"idle_connections"`       // Conexões idle
	IdleInTransaction  int     `json:"idle_in_transaction" db:"idle_in_transaction"` // Conexões idle em transação
	MaxConnections     int     `json:"max_connections" db:"max_connections"`         // Máximo de conexões
	ConnectionsPercent float64 `json:"connections_percent"`                          // Percentual de conexões
}

// DatabaseSize representa o tamanho do banco de dados
type DatabaseSize struct {
	DatabaseName string  `json:"database_name" db:"database_name"` // Nome do banco
	SizePretty   string  `json:"size_pretty" db:"size_pretty"`     // Tamanho formatado
	SizeMB       float64 `json:"size_mb" db:"size_mb"`             // Tamanho em MB
}

// PerformanceStats representa estatísticas de performance
type PerformanceStats struct {
	CacheHitRatio  float64 `json:"cache_hit_ratio" db:"cache_hit_ratio"`   // Cache hit ratio
	TuplesReturned int64   `json:"tuples_returned" db:"tuples_returned"`   // Tuplas retornadas
	TuplesFetched  int64   `json:"tuples_fetched" db:"tuples_fetched"`     // Tuplas buscadas
	TuplesInserted int64   `json:"tuples_inserted" db:"tuples_inserted"`   // Tuplas inseridas
	TuplesUpdated  int64   `json:"tuples_updated" db:"tuples_updated"`     // Tuplas atualizadas
	TuplesDeleted  int64   `json:"tuples_deleted" db:"tuples_deleted"`     // Tuplas deletadas
	Conflicts      int64   `json:"conflicts" db:"conflicts"`               // Conflitos
	TempFiles      int64   `json:"temp_files" db:"temp_files"`             // Arquivos temporários
	Deadlocks      int64   `json:"deadlocks" db:"deadlocks"`               // Deadlocks
}

// AnalyticsResponse representa uma resposta do serviço de analytics
type AnalyticsResponse struct {
	Success     bool        `json:"success"`                              // Sucesso da operação
	Message     string      `json:"message"`                              // Mensagem
	Timestamp   int64       `json:"timestamp"`                            // Timestamp
	Environment string      `json:"environment"`                          // Ambiente
	User        interface{} `json:"user,omitempty"`                       // Dados do usuário
	Data        interface{} `json:"data"`                                 // Dados da resposta
}
