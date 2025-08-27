-- Down migration - Drop all tables and functions

-- Drop triggers
DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_servers_updated_at ON servers;
DROP TRIGGER IF EXISTS update_databases_updated_at ON databases;

-- Drop function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop indexes
DROP INDEX IF EXISTS idx_snapshots_server_time;
DROP INDEX IF EXISTS idx_snapshots_customer;
DROP INDEX IF EXISTS idx_alerts_server_time;
DROP INDEX IF EXISTS idx_alerts_customer;
DROP INDEX IF EXISTS idx_alerts_severity;
DROP INDEX IF EXISTS idx_users_username;
DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS idx_servers_customer;
DROP INDEX IF EXISTS idx_databases_server;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS alerts;
DROP TABLE IF EXISTS snapshots;
DROP TABLE IF EXISTS databases;
DROP TABLE IF EXISTS servers;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS customers;
