-- Inserir usuário admin padrão
-- Senha: admin123 (hash bcrypt)
INSERT INTO users (id, email, password_hash, name, role, email_verified) 
VALUES (
    uuid_generate_v4(),
    'admin@pganalytics.local',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'Administrator',
    'admin',
    true
) ON CONFLICT (email) DO NOTHING;

-- Inserir usuário teste
INSERT INTO users (id, email, password_hash, name, role, email_verified) 
VALUES (
    uuid_generate_v4(),
    'user@pganalytics.local',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'Test User',
    'user',
    true
) ON CONFLICT (email) DO NOTHING;