
-- Sistema de permissões e segurança

-- Role para aplicação (backend Go)
CREATE ROLE pganalytics_app WITH LOGIN PASSWORD 'change_in_production';

-- Role apenas para leitura (para relatórios)
CREATE ROLE pganalytics_readonly WITH LOGIN PASSWORD 'change_in_production';

-- Permissões para aplicação
GRANT USAGE ON SCHEMA public TO pganalytics_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO pganalytics_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO pganalytics_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pganalytics_app;

-- Permissões apenas leitura
GRANT USAGE ON SCHEMA public TO pganalytics_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pganalytics_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO pganalytics_readonly;

-- RLS (Row Level Security) para isolamento multi-tenant
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE pg_clusters ENABLE ROW LEVEL SECURITY;
ALTER TABLE pg_databases ENABLE ROW LEVEL SECURITY;

-- Política para organizações (usuários só veem sua própria org)
CREATE POLICY org_isolation ON organizations
    FOR ALL TO pganalytics_app
    USING (id = current_setting('app.current_organization_id', true)::UUID);

-- Política para clusters (baseada na organização)
CREATE POLICY cluster_isolation ON pg_clusters
    FOR ALL TO pganalytics_app
    USING (organization_id = current_setting('app.current_organization_id', true)::UUID);

-- Política para databases (baseada no cluster)
CREATE POLICY database_isolation ON pg_databases
    FOR ALL TO pganalytics_app
    USING (
        cluster_id IN (
            SELECT id FROM pg_clusters 
            WHERE organization_id = current_setting('app.current_organization_id', true)::UUID
        )
    );

-- Função para obter organização de um cluster (segurança)
CREATE OR REPLACE FUNCTION get_cluster_organization(cluster_uuid UUID)
RETURNS UUID AS $$
DECLARE
    org_id UUID;
BEGIN
    SELECT organization_id INTO org_id
    FROM pg_clusters
    WHERE id = cluster_uuid AND status != 'inactive';
    
    RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Função para verificar acesso à organização
CREATE OR REPLACE FUNCTION user_has_org_access(user_org_id UUID, target_org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN user_org_id = target_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
