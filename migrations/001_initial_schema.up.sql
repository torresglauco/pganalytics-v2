-- PgAnalytics v2.0 Initial Schema
-- Modern PostgreSQL schema for monitoring and analytics

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create customers table
CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    customer_email VARCHAR(255) NOT NULL UNIQUE,
    customer_schema VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    is_admin BOOLEAN DEFAULT false,
    customer_id INTEGER REFERENCES customers(customer_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

-- Create servers table
CREATE TABLE IF NOT EXISTS servers (
    server_id SERIAL PRIMARY KEY,
    server_name VARCHAR(255) NOT NULL,
    description TEXT,
    hostname VARCHAR(255) NOT NULL,
    port INTEGER NOT NULL DEFAULT 5432,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create databases table
CREATE TABLE IF NOT EXISTS databases (
    database_id SERIAL PRIMARY KEY,
    database_name VARCHAR(255) NOT NULL,
    server_id INTEGER NOT NULL REFERENCES servers(server_id),
    description TEXT,
    username VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create snapshots table
CREATE TABLE IF NOT EXISTS snapshots (
    snapshot_id SERIAL PRIMARY KEY,
    server_id INTEGER NOT NULL REFERENCES servers(server_id),
    database_id INTEGER REFERENCES databases(database_id),
    snap_type VARCHAR(100) NOT NULL,
    snap_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create alerts table
CREATE TABLE IF NOT EXISTS alerts (
    alert_id SERIAL PRIMARY KEY,
    job_id INTEGER,
    server_id INTEGER NOT NULL REFERENCES servers(server_id),
    database_id INTEGER REFERENCES databases(database_id),
    alert_item VARCHAR(255) NOT NULL,
    alert_value TEXT,
    alert_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    alert_severity VARCHAR(20) NOT NULL CHECK (alert_severity IN ('critical', 'warning', 'info', 'ok')),
    alert_msg TEXT NOT NULL,
    alert_hint TEXT,
    alert_sent_time TIMESTAMP,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_snapshots_server_time ON snapshots(server_id, snap_time);
CREATE INDEX IF NOT EXISTS idx_snapshots_customer ON snapshots(customer_id);
CREATE INDEX IF NOT EXISTS idx_alerts_server_time ON alerts(server_id, alert_time);
CREATE INDEX IF NOT EXISTS idx_alerts_customer ON alerts(customer_id);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts(alert_severity);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_servers_customer ON servers(customer_id);
CREATE INDEX IF NOT EXISTS idx_databases_server ON databases(server_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_servers_updated_at BEFORE UPDATE ON servers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_databases_updated_at BEFORE UPDATE ON databases
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default customer
INSERT INTO customers (customer_name, customer_email, customer_schema) 
VALUES ('Demo Customer', 'demo@pganalytics.com', 'public')
ON CONFLICT (customer_email) DO NOTHING;

-- Insert default users (password: admin123 and demo123)
-- bcrypt hash for 'admin123' and 'demo123'
INSERT INTO users (username, email, password_hash, first_name, last_name, is_admin, customer_id)
VALUES 
    ('admin', 'admin@pganalytics.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'User', true, 1),
    ('demo', 'demo@pganalytics.com', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Demo', 'User', false, 1)
ON CONFLICT (username) DO NOTHING;

-- Insert sample server
INSERT INTO servers (server_name, description, hostname, port, customer_id)
VALUES ('Local PostgreSQL', 'Local development server', 'localhost', 5432, 1)
ON CONFLICT DO NOTHING;

-- Insert sample database
INSERT INTO databases (database_name, server_id, description, username, customer_id)
VALUES ('pganalytics', 1, 'Main analytics database', 'pganalytics', 1)
ON CONFLICT DO NOTHING;
