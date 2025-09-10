
-- Trigger para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Organizations table
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    plan_type VARCHAR(50) DEFAULT 'standard' CHECK (plan_type IN ('free', 'standard', 'premium', 'enterprise')),
    max_clusters INTEGER DEFAULT 5,
    max_databases_per_cluster INTEGER DEFAULT 20,
    retention_days INTEGER DEFAULT 90,
    is_active BOOLEAN DEFAULT TRUE,
    is_trial BOOLEAN DEFAULT FALSE,
    trial_ends_at TIMESTAMPTZ,
    collection_interval_seconds INTEGER DEFAULT 300 CHECK (collection_interval_seconds >= 60),
    enable_alerting BOOLEAN DEFAULT TRUE,
    enable_recommendations BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID,
    metadata JSONB DEFAULT '{}',
    CONSTRAINT valid_slug CHECK (slug ~ '^[a-z0-9-]+$')
);

CREATE INDEX idx_organizations_slug ON organizations(slug) WHERE is_active = TRUE;
CREATE INDEX idx_organizations_plan_active ON organizations(plan_type, is_active);
CREATE INDEX idx_organizations_trial ON organizations(trial_ends_at) WHERE is_trial = TRUE;

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
