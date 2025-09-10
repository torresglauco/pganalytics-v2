#!/bin/bash
# Security validation script

echo "🔍 Validating Security Configuration..."

# Check for hardcoded secrets
echo "Checking for hardcoded secrets..."
if grep -r "secret.*=" --include="*.go" --include="*.c" . | grep -v ".env" | grep -v "getEnv"; then
    echo "❌ Found potential hardcoded secrets!"
    exit 1
else
    echo "✅ No hardcoded secrets found"
fi

# Check JWT secret length
if [ -n "$JWT_SECRET" ]; then
    if [ ${#JWT_SECRET} -ge 32 ]; then
        echo "✅ JWT_SECRET is properly configured"
    else
        echo "❌ JWT_SECRET is too short (minimum 32 characters)"
        exit 1
    fi
else
    echo "❌ JWT_SECRET is not set"
    exit 1
fi

# Check admin fallback configuration
if [ "$ADMIN_FALLBACK_ENABLED" = "true" ]; then
    echo "⚠️  Admin fallback is ENABLED - not recommended for production"
    if [ -z "$ADMIN_PASSWORD_HASH" ]; then
        echo "❌ Admin fallback enabled but no password hash set"
        exit 1
    fi
else
    echo "✅ Admin fallback is disabled (secure)"
fi

# Test endpoints
echo "Testing security endpoints..."
if curl -f -s http://localhost:8080/health > /dev/null; then
    echo "✅ Health endpoint responding"
else
    echo "❌ Health endpoint not responding"
fi

echo "🎉 Security validation completed!"
