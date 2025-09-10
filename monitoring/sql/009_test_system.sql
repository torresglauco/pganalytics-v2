
-- Script de teste completo do sistema multi-tenant

DO $$
DECLARE
    org1_id UUID;
    org2_id UUID;
    cluster1_id UUID;
    cluster2_id UUID;
    snapshot1_id BIGINT;
    test_results TEXT := '';
BEGIN
    RAISE NOTICE 'Iniciando testes do sistema multi-tenant...';
    
    -- 1. Teste de criação de organizações
    INSERT INTO organizations (name, slug, plan_type) VALUES 
    ('Test Organization 1', 'test-org-1', 'premium'),
    ('Test Organization 2', 'test-org-2', 'standard')
    RETURNING id INTO org1_id;
    
    SELECT id INTO org2_id FROM organizations WHERE slug = 'test-org-2';
    
    RAISE NOTICE 'Organizações criadas: % e %', org1_id, org2_id;
    
    -- 2. Teste de criação de clusters
    INSERT INTO pg_clusters (organization_id, name, client_identifier, host, pg_version_major, pg_version_minor) VALUES
    (org1_id, 'Production Cluster', 'prod-cluster-1', 'prod-db.company.com', 15, 2),
    (org2_id, 'Staging Cluster', 'staging-cluster-1', 'staging-db.company.com', 14, 8)
    RETURNING id INTO cluster1_id;
    
    SELECT id INTO cluster2_id FROM pg_clusters WHERE client_identifier = 'staging-cluster-1';
    
    RAISE NOTICE 'Clusters criados: % e %', cluster1_id, cluster2_id;
    
    -- 3. Teste de criação de databases
    INSERT INTO pg_databases (cluster_id, name, size_bytes) VALUES
    (cluster1_id, 'production_app', 500000000),
    (cluster1_id, 'production_logs', 200000000),
    (cluster2_id, 'staging_app', 100000000);
    
    RAISE NOTICE 'Databases criadas com sucesso';
    
    -- 4. Teste de snapshots
    INSERT INTO sn_stat_snapshots (cluster_id, database_name, snapshot_type) VALUES
    (cluster1_id, 'production_app', 'tables')
    RETURNING id INTO snapshot1_id;
    
    RAISE NOTICE 'Snapshot criado: %', snapshot1_id;
    
    -- 5. Teste de métricas de tabelas
    INSERT INTO sn_stat_user_tables_modern (
        snapshot_id, cluster_id, database_name, schemaname, tablename,
        seq_scan, idx_scan, n_live_tup, n_dead_tup, table_size_bytes, total_size_bytes,
        health_score, performance_category
    ) VALUES
    (snapshot1_id, cluster1_id, 'production_app', 'public', 'users', 
     1000, 5000, 50000, 1000, 10485760, 15728640, 85, 'good'),
    (snapshot1_id, cluster1_id, 'production_app', 'public', 'orders',
     2000, 8000, 100000, 5000, 52428800, 78643200, 70, 'fair');
    
    RAISE NOTICE 'Métricas de tabelas inseridas';
    
    -- 6. Teste de isolamento RLS
    SET app.current_organization_id = org1_id::TEXT;
    
    -- Deve ver apenas clusters da org1
    IF (SELECT COUNT(*) FROM pg_clusters) != 1 THEN
        RAISE EXCEPTION 'FALHA: RLS não está funcionando para clusters';
    END IF;
    
    -- Deve ver apenas dados da org1 nas views
    IF (SELECT COUNT(*) FROM v_current_table_stats) != 2 THEN
        RAISE EXCEPTION 'FALHA: RLS não está funcionando para table stats';
    END IF;
    
    -- Trocar para org2
    SET app.current_organization_id = org2_id::TEXT;
    
    -- Agora deve ver apenas clusters da org2
    IF (SELECT COUNT(*) FROM pg_clusters) != 1 THEN
        RAISE EXCEPTION 'FALHA: RLS não está isolando organizações corretamente';
    END IF;
    
    RAISE NOTICE 'Teste de isolamento RLS: PASSOU';
    
    -- 7. Teste de views agregadas
    RESET app.current_organization_id;
    
    IF (SELECT COUNT(*) FROM v_organization_summary) != 2 THEN
        RAISE EXCEPTION 'FALHA: View de summary não está retornando organizações corretas';
    END IF;
    
    RAISE NOTICE 'Teste de views agregadas: PASSOU';
    
    -- 8. Teste de funções de manutenção
    PERFORM system_maintenance();
    RAISE NOTICE 'Teste de funções de manutenção: PASSOU';
    
    -- 9. Teste de health score
    DECLARE
        health_score INTEGER;
    BEGIN
        SELECT calculate_table_health_score(0.1, 0.8, 5, 10485760) INTO health_score;
        IF health_score < 85 OR health_score > 95 THEN
            RAISE EXCEPTION 'FALHA: Health score não está calculando corretamente: %', health_score;
        END IF;
        RAISE NOTICE 'Teste de health score: PASSOU (score: %)', health_score;
    END;
    
    -- Limpeza dos dados de teste
    DELETE FROM organizations WHERE slug IN ('test-org-1', 'test-org-2');
    
    RAISE NOTICE '✅ TODOS OS TESTES PASSARAM! Sistema multi-tenant funcionando corretamente.';
    
EXCEPTION WHEN others THEN
    -- Limpeza em caso de erro
    DELETE FROM organizations WHERE slug IN ('test-org-1', 'test-org-2');
    RAISE EXCEPTION 'TESTE FALHOU: %', SQLERRM;
END;
$$;
