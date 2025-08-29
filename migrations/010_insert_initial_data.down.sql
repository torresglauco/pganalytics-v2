-- Remover dados iniciais
DELETE FROM system_config WHERE config_key IN (
    'app.name', 'app.version', 'analytics.slow_query_threshold_ms',
    'analytics.connection_log_enabled', 'analytics.retention_days',
    'auth.max_failed_login_attempts', 'auth.account_lockout_minutes',
    'auth.jwt_refresh_token_days', 'monitoring.metrics_collection_interval_seconds'
);

DELETE FROM users WHERE email IN (
    'admin@pganalytics.local', 
    'user@pganalytics.local', 
    'readonly@pganalytics.local'
);