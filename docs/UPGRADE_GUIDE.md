# 🚀 PostgreSQL Analytics Collector - Enhancement Guide

## Quick Start

1. **Replace main.c with enhanced version**:
   ```bash
   cp main_enhanced.c ../pganalytics-v2/monitoring/c-collector/
   ```

2. **Update Docker configuration**:
   ```bash
   cp Dockerfile.c-collector-enhanced ../pganalytics-v2/
   cp docker-compose.enhanced.yml ../pganalytics-v2/
   ```

3. **Add PostgreSQL extensions**:
   ```bash
   mkdir -p ../pganalytics-v2/monitoring/sql
   cp monitoring/sql/init-extensions.sql ../pganalytics-v2/monitoring/sql/
   ```

4. **Test enhanced version**:
   ```bash
   cd ../pganalytics-v2
   docker-compose -f docker-compose.yml -f docker-compose.enhanced.yml up -d
   ```

5. **Verify enhanced metrics**:
   ```bash
   curl http://localhost:8080/health
   curl http://localhost:8080/metrics | grep pganalytics
   ```

## New Metrics Available

✅ Enhanced connection details (idle, in-transaction)
✅ Database size monitoring
✅ Improved cache metrics
✅ Foundation for query performance monitoring
✅ Lock monitoring capability
✅ Replication metrics support

## Migration Options

### Option A: Direct Replacement (Recommended)
Replace your existing main.c with main_enhanced.c and rebuild.

### Option B: Side-by-side Testing
Run enhanced version on different port for validation.

## Rollback Plan

Keep backup of original main.c:
```bash
cp monitoring/c-collector/main.c monitoring/c-collector/main.c.backup
```

Your PostgreSQL monitoring is now enhanced! 🚀
