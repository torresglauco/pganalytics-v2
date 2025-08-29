-- Inserir dados iniciais

-- Usuários padrão
INSERT INTO users (id, email, password_hash, name, role, email_verified) 
VALUES (
    uuid_generate_v4(),
    'admin@pganalytics.local',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- admin123
    'System Administrator',
    'admin',
    true
) ON CONFLICT (email) DO NOTHING;

INSERT INTO users (id, email, password_hash, name, role, email_verified) 
VALUES (
    uuid_generate_v4(),
    'user@pganalytics.local',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- admin123
    'Test User',
    'user',
    true
) ON CONFLICT (email) DO NOTHING;

INSERT INTO users (id, email, password_hash, name, role, email_verified) 
VALUES (
    uuid_generate_v4(),
    'readonly@pganalytics.local',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- admin123
    'Read Only User',
    'readonly',
    true
) ON CONFLICT (email) DO NOTHING;

-- Configurações padrão do sistema
INSERT INTO system_config (config_key, config_value, config_type, description) VALUES
('app.name', 'PG Analytics', 'string', 'Nome da aplicação'),
('app.version', '2.0.0', 'string', 'Versão da aplicação'),
('analytics.slow_query_threshold_ms', '1000', 'number', 'Threshold para queries lentas em ms'),
('analytics.connection_log_enabled', 'true', 'boolean', 'Habilitar log de conexões'),
('analytics.retention_days', '30', 'number', 'Dias de retenção de logs'),
('auth.max_failed_login_attempts', '5', 'number', 'Máximo de tentativas de login'),
('auth.account_lockout_minutes', '15', 'number', 'Minutos de bloqueio de conta'),
('auth.jwt_refresh_token_days', '7', 'number', 'Dias de validade do refresh token'),
('monitoring.metrics_collection_interval_seconds', '60', 'number', 'Intervalo de coleta de métricas em segundos')
ON CONFLICT (config_key) DO NOTHING;