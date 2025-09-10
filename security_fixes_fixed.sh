#!/bin/bash
# PGANALYTICS-V2 SECURITY FIXES AUTOMATION SCRIPT (FIXED VERSION)
# This script addresses critical security vulnerabilities identified in the analysis

set -e  # Exit on any error

echo "🔒 Starting PGANALYTICS-V2 Security Fixes..."
echo "======================================================"

# Create necessary directories
mkdir -p backups/$(date +%Y%m%d_%H%M%S)
mkdir -p security_patches
mkdir -p middleware

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

echo "📋 Creating backups in $BACKUP_DIR..."

# Backup original files
if [ -f "main.go" ]; then
    cp main.go "$BACKUP_DIR/main.go.backup"
    echo "✅ Backed up main.go"
fi

if [ -f "export_metrics_prometheus_fixed.c" ]; then
    cp export_metrics_prometheus_fixed.c "$BACKUP_DIR/export_metrics_prometheus_fixed.c.backup"
    echo "✅ Backed up C collector"
fi

# 1. Fix hardcoded JWT secret in main.go
echo "🔧 Fixing hardcoded JWT secret..."
if [ -f "main.go" ]; then
    # Replace hardcoded JWT secret with environment variable
    sed -i.bak 's/const jwtSecret = "your-secret-key"/var jwtSecret = getEnv("JWT_SECRET", "")/' main.go
    
    # Add JWT secret validation at the beginning of main function
    sed -i.bak '/func main() {/a\
\t// Validate required environment variables\
\tif jwtSecret == "" {\
\t\tlog.Fatal("JWT_SECRET environment variable is required")\
\t}\
' main.go
    
    echo "✅ Fixed hardcoded JWT secret"
else
    echo "❌ main.go not found, skipping JWT secret fix"
fi

# 2. Remove hardcoded fallback credentials
echo "🔧 Removing hardcoded fallback credentials..."
if [ -f "main.go" ]; then
    # Create a temporary file with the improved authentication function
    cat > temp_auth_fix.go << 'EOF'
// validateCredentials checks user credentials against database first, then secure fallback
func validateCredentials(username, password string) bool {
    // Try database first
    var hashedPassword string
    err := db.QueryRow("SELECT password FROM users WHERE username = $1", username).Scan(&hashedPassword)
    if err == nil {
        err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
        return err == nil
    }
    
    // Only allow admin fallback if explicitly enabled and properly configured
    adminEnabled := getEnv("ADMIN_FALLBACK_ENABLED", "false")
    if adminEnabled == "true" {
        adminUser := getEnv("ADMIN_USERNAME", "")
        adminHashedPass := getEnv("ADMIN_PASSWORD_HASH", "")
        if adminUser != "" && adminHashedPass != "" && username == adminUser {
            return bcrypt.CompareHashAndPassword([]byte(adminHashedPass), []byte(password)) == nil
        }
    }
    
    log.Printf("Authentication failed for user: %s", username)
    return false
}
EOF

    # Replace the validateCredentials function in main.go
    # First, let's find the function and replace it
    awk '
    /^func validateCredentials/ {
        print "// validateCredentials checks user credentials against database first, then secure fallback"
        print "func validateCredentials(username, password string) bool {"
        print "    // Try database first"
        print "    var hashedPassword string"
        print "    err := db.QueryRow("SELECT password FROM users WHERE username = $1", username).Scan(&hashedPassword)"
        print "    if err == nil {"
        print "        err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))"
        print "        return err == nil"
        print "    }"
        print ""
        print "    // Only allow admin fallback if explicitly enabled and properly configured"
        print "    adminEnabled := getEnv("ADMIN_FALLBACK_ENABLED", "false")"
        print "    if adminEnabled == "true" {"
        print "        adminUser := getEnv("ADMIN_USERNAME", "")"
        print "        adminHashedPass := getEnv("ADMIN_PASSWORD_HASH", "")"
        print "        if adminUser != "" && adminHashedPass != "" && username == adminUser {"
        print "            return bcrypt.CompareHashAndPassword([]byte(adminHashedPass), []byte(password)) == nil"
        print "        }"
        print "    }"
        print ""
        print "    log.Printf("Authentication failed for user: %s", username)"
        print "    return false"
        print "}"
        # Skip the original function
        while (getline > 0 && $0 !~ /^}/) { }
        next
    }
    { print }
    ' main.go > main_temp.go && mv main_temp.go main.go
    
    rm -f temp_auth_fix.go
    echo "✅ Removed hardcoded fallback credentials"
fi

# 3. Create secure .env.example
echo "📝 Creating secure .env.example..."
cat > .env.example << 'EOF'
# REQUIRED SECURITY CONFIGURATION
# Generate JWT secret with: openssl rand -base64 32
JWT_SECRET=your-very-long-random-jwt-secret-key-here-min-32-chars

# DATABASE CONFIGURATION
DB_HOST=postgres
DB_PORT=5432
DB_NAME=pganalytics
DB_USER=admin
DB_PASSWORD=your-secure-database-password-here

# OPTIONAL ADMIN FALLBACK (NOT RECOMMENDED FOR PRODUCTION)
# Only enable if you need emergency access without database
ADMIN_FALLBACK_ENABLED=false
ADMIN_USERNAME=admin
# Generate with: echo -n 'your-password' | bcrypt-tool (or use bcrypt online tool)
ADMIN_PASSWORD_HASH=$2a$10$example.bcrypt.hash.here

# APPLICATION CONFIGURATION
PORT=8080
ENVIRONMENT=development
LOG_LEVEL=info
TENANT_NAME=default
EOF

# 4. Create input validation middleware
echo "🔧 Creating input validation middleware..."
cat > middleware/validation.go << 'EOF'
package main

import (
    "net/http"
    "regexp"
    "strings"
    "github.com/gin-gonic/gin"
)

// Input validation middleware
func validationMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // Validate request size (1MB limit)
        if c.Request.ContentLength > 1024*1024 {
            c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "Request too large"})
            c.Abort()
            return
        }
        
        // Validate Content-Type for POST requests
        if c.Request.Method == "POST" {
            contentType := c.GetHeader("Content-Type")
            if !strings.Contains(contentType, "application/json") {
                c.JSON(http.StatusBadRequest, gin.H{"error": "Content-Type must be application/json"})
                c.Abort()
                return
            }
        }
        
        // Validate User-Agent header length
        if userAgent := c.GetHeader("User-Agent"); len(userAgent) > 200 {
            c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid User-Agent header"})
            c.Abort()
            return
        }
        
        // Add security headers
        c.Header("X-Content-Type-Options", "nosniff")
        c.Header("X-Frame-Options", "DENY")
        c.Header("X-XSS-Protection", "1; mode=block")
        
        c.Next()
    }
}

// Validate tenant name format (alphanumeric, underscore, hyphen only)
func isValidTenantName(name string) bool {
    if len(name) == 0 || len(name) > 50 {
        return false
    }
    matched, _ := regexp.MatchString("^[a-zA-Z0-9_-]+$", name)
    return matched
}

// Validate username format
func isValidUsername(username string) bool {
    if len(username) < 3 || len(username) > 50 {
        return false
    }
    matched, _ := regexp.MatchString("^[a-zA-Z0-9_.-]+$", username)
    return matched
}

// Validate password strength
func isValidPassword(password string) bool {
    if len(password) < 8 || len(password) > 100 {
        return false
    }
    
    // Check for at least one uppercase, lowercase, digit
    hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(password)
    hasLower := regexp.MustCompile(`[a-z]`).MatchString(password)
    hasDigit := regexp.MustCompile(`[0-9]`).MatchString(password)
    
    return hasUpper && hasLower && hasDigit
}
EOF

# 5. Update main.go to use validation middleware
echo "🔧 Adding validation middleware to main.go..."
if [ -f "main.go" ]; then
    # Add validation middleware to the router setup
    sed -i.bak '/router.Use(func(c \*gin.Context) {/i\
\t// Add input validation middleware\
\trouter.Use(validationMiddleware())\
' main.go
    echo "✅ Added validation middleware to router"
fi

# 6. Fix C collector buffer overflow
echo "🔧 Fixing C collector buffer overflow..."
if [ -f "export_metrics_prometheus_fixed.c" ]; then
    # Create improved version with dynamic buffer allocation
    cat > export_metrics_prometheus_secure.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>

// Secure version with proper buffer management and input validation
int export_metrics_prometheus_format(const PostgreSQLMetrics* metrics, 
                                    const char* tenant_name, 
                                    char* output, 
                                    size_t output_size) {
    if (!metrics || !tenant_name || !output || output_size == 0) {
        return -1; // Invalid parameters
    }
    
    // Validate tenant name (alphanumeric and underscores only)
    size_t tenant_len = strlen(tenant_name);
    if (tenant_len == 0 || tenant_len > 50) {
        return -2; // Invalid tenant name length
    }
    
    for (size_t i = 0; i < tenant_len; i++) {
        if (!isalnum(tenant_name[i]) && tenant_name[i] != '_' && tenant_name[i] != '-') {
            return -3; // Invalid tenant name character
        }
    }
    
    // Calculate required buffer size more accurately
    size_t estimated_size = 8192; // Increased base size
    estimated_size += tenant_len * 25; // Account for tenant name in each metric
    
    // Allocate dynamic buffer with safety margin
    char* metrics_buffer = calloc(1, estimated_size);
    if (!metrics_buffer) {
        return -4; // Memory allocation failed
    }
    
    size_t offset = 0;
    
    // Safe string concatenation macro with overflow protection
    #define SAFE_APPEND(format, ...) do { \
        int written = snprintf(metrics_buffer + offset, estimated_size - offset, format, ##__VA_ARGS__); \
        if (written < 0) { \
            free(metrics_buffer); \
            return -5; /* snprintf error */ \
        } \
        if (offset + written >= estimated_size) { \
            free(metrics_buffer); \
            return -6; /* Buffer would overflow */ \
        } \
        offset += written; \
    } while(0)
    
    // Add header
    SAFE_APPEND("# HELP pganalytics PostgreSQL Analytics Metrics\n");
    SAFE_APPEND("# TYPE pganalytics_total_connections gauge\n");
    
    // Connection metrics with validation
    if (metrics->total_connections >= 0) {
        SAFE_APPEND("pganalytics_total_connections{tenant=\"%s\"} %d\n", tenant_name, metrics->total_connections);
    }
    if (metrics->active_connections >= 0) {
        SAFE_APPEND("pganalytics_active_connections{tenant=\"%s\"} %d\n", tenant_name, metrics->active_connections);
    }
    if (metrics->idle_connections >= 0) {
        SAFE_APPEND("pganalytics_idle_connections{tenant=\"%s\"} %d\n", tenant_name, metrics->idle_connections);
    }
    if (metrics->idle_in_transaction >= 0) {
        SAFE_APPEND("pganalytics_idle_in_transaction{tenant=\"%s\"} %d\n", tenant_name, metrics->idle_in_transaction);
    }
    
    // Query performance metrics
    if (metrics->slow_queries_count >= 0) {
        SAFE_APPEND("pganalytics_slow_queries_count{tenant=\"%s\"} %d\n", tenant_name, metrics->slow_queries_count);
    }
    if (metrics->avg_query_time >= 0.0) {
        SAFE_APPEND("pganalytics_avg_query_time_ms{tenant=\"%s\"} %.2f\n", tenant_name, metrics->avg_query_time);
    }
    if (metrics->max_query_time >= 0.0) {
        SAFE_APPEND("pganalytics_max_query_time_ms{tenant=\"%s\"} %.2f\n", tenant_name, metrics->max_query_time);
    }
    
    // Transaction metrics
    if (metrics->commits_total >= 0) {
        SAFE_APPEND("pganalytics_commits_total{tenant=\"%s\"} %lld\n", tenant_name, metrics->commits_total);
    }
    if (metrics->rollbacks_total >= 0) {
        SAFE_APPEND("pganalytics_rollbacks_total{tenant=\"%s\"} %lld\n", tenant_name, metrics->rollbacks_total);
    }
    
    // Database size metrics
    if (metrics->database_size >= 0) {
        SAFE_APPEND("pganalytics_database_size_bytes{tenant=\"%s\"} %lld\n", tenant_name, metrics->database_size);
    }
    if (metrics->largest_table_size >= 0) {
        SAFE_APPEND("pganalytics_largest_table_size_bytes{tenant=\"%s\"} %lld\n", tenant_name, metrics->largest_table_size);
    }
    
    // Lock metrics
    if (metrics->active_locks >= 0) {
        SAFE_APPEND("pganalytics_active_locks{tenant=\"%s\"} %d\n", tenant_name, metrics->active_locks);
    }
    if (metrics->waiting_locks >= 0) {
        SAFE_APPEND("pganalytics_waiting_locks{tenant=\"%s\"} %d\n", tenant_name, metrics->waiting_locks);
    }
    if (metrics->deadlocks_total >= 0) {
        SAFE_APPEND("pganalytics_deadlocks_total{tenant=\"%s\"} %d\n", tenant_name, metrics->deadlocks_total);
    }
    
    // Replication metrics
    SAFE_APPEND("pganalytics_is_primary{tenant=\"%s\"} %d\n", tenant_name, metrics->is_primary ? 1 : 0);
    if (metrics->replication_lag_bytes >= 0.0) {
        SAFE_APPEND("pganalytics_replication_lag_bytes{tenant=\"%s\"} %.0f\n", tenant_name, metrics->replication_lag_bytes);
    }
    if (metrics->replication_lag_seconds >= 0.0) {
        SAFE_APPEND("pganalytics_replication_lag_seconds{tenant=\"%s\"} %.2f\n", tenant_name, metrics->replication_lag_seconds);
    }
    
    // Cache metrics
    if (metrics->cache_hit_ratio >= 0.0 && metrics->cache_hit_ratio <= 100.0) {
        SAFE_APPEND("pganalytics_cache_hit_ratio{tenant=\"%s\"} %.2f\n", tenant_name, metrics->cache_hit_ratio);
    }
    if (metrics->index_hit_ratio >= 0.0 && metrics->index_hit_ratio <= 100.0) {
        SAFE_APPEND("pganalytics_index_hit_ratio{tenant=\"%s\"} %.2f\n", tenant_name, metrics->index_hit_ratio);
    }
    
    // Status metrics
    SAFE_APPEND("pganalytics_database_connected{tenant=\"%s\"} %d\n", tenant_name, metrics->database_connected ? 1 : 0);
    SAFE_APPEND("pganalytics_last_update{tenant=\"%s\"} %ld\n", tenant_name, (long)metrics->last_update);
    
    // Copy to output buffer safely
    if (offset >= output_size) {
        free(metrics_buffer);
        return -7; // Output buffer too small
    }
    
    memcpy(output, metrics_buffer, offset);
    output[offset] = '\0';
    
    free(metrics_buffer);
    return 0; // Success
    
    #undef SAFE_APPEND
}
EOF
    echo "✅ Created secure C collector with buffer overflow protection"
fi

# 7. Create security documentation
echo "📚 Creating security documentation..."
cat > SECURITY.md << 'EOF'
# Security Configuration Guide

## Critical Security Requirements

### 1. JWT Secret Configuration
The JWT secret is used to sign authentication tokens and MUST be cryptographically secure.

```bash
# Generate a secure JWT secret (minimum 32 characters)
openssl rand -base64 32

# Set in environment
export JWT_SECRET="your-generated-secret-here"
```

### 2. Database Security
- Use strong passwords (minimum 12 characters, mixed case, numbers, symbols)
- Enable SSL/TLS for database connections in production
- Limit database user privileges to minimum required

```bash
# Example secure database password
export DB_PASSWORD="MySecure2024!Database#Password"
```

### 3. Admin Fallback Configuration
⚠️ **WARNING**: Admin fallback should be DISABLED in production

```bash
# Production setting (recommended)
export ADMIN_FALLBACK_ENABLED=false

# If emergency access needed (NOT RECOMMENDED for production)
export ADMIN_FALLBACK_ENABLED=true
export ADMIN_USERNAME=emergency_admin
# Generate bcrypt hash for password
export ADMIN_PASSWORD_HASH="$2a$10$actual.bcrypt.hash.here"
```

### 4. Generate Bcrypt Hash
To generate a bcrypt hash for admin password:

```bash
# Using Python
python3 -c "import bcrypt; print(bcrypt.hashpw('your-password'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'))"

# Using Node.js
node -e "const bcrypt = require('bcrypt'); console.log(bcrypt.hashSync('your-password', 10));"

# Using online tool (use with caution)
# Visit: https://bcrypt-generator.com/
```

## Security Checklist

### Pre-Production Security Audit
- [ ] JWT_SECRET is set to cryptographically random value (≥32 chars)
- [ ] No hardcoded secrets in source code
- [ ] Database passwords are strong and rotated
- [ ] Admin fallback is disabled (ADMIN_FALLBACK_ENABLED=false)
- [ ] HTTPS is enabled for all communications
- [ ] Input validation middleware is active
- [ ] Security headers are configured
- [ ] Buffer overflow protections are in place

### Monitoring Security Events
Monitor these patterns for security issues:
- Multiple failed authentication attempts from same IP
- Requests with invalid/malicious input patterns
- Unusual connection patterns or geographic locations
- Buffer overflow attempt indicators
- JWT token manipulation attempts

### Security Headers
The application automatically adds these security headers:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY` 
- `X-XSS-Protection: 1; mode=block`

### Regular Security Maintenance
- Rotate JWT secrets every 90 days
- Update dependencies regularly
- Monitor security advisories
- Perform security scans
- Review access logs weekly

## Incident Response

### If Security Breach Suspected
1. Immediately rotate JWT secret
2. Reset all user passwords
3. Review access logs
4. Update all dependencies
5. Perform security scan
6. Document incident

### Emergency Access
If locked out due to security measures:
1. Access server directly (SSH)
2. Temporarily enable admin fallback
3. Create new admin user in database
4. Disable admin fallback
5. Investigate root cause

## Contact
For security issues, contact: security@yourcompany.com
EOF

# 8. Create validation script
echo "🔧 Creating security validation script..."
cat > scripts/validate_security.sh << 'EOF'
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
EOF

chmod +x scripts/validate_security.sh

# 9. Update go.mod if needed
echo "📦 Checking Go dependencies..."
if [ -f "go.mod" ]; then
    # Add bcrypt dependency if not present
    if ! grep -q "golang.org/x/crypto" go.mod; then
        echo "Adding bcrypt dependency..."
        go get golang.org/x/crypto/bcrypt
    fi
fi

echo ""
echo "🎉 Security fixes completed successfully!"
echo "======================================================"
echo "📋 Summary of security improvements:"
echo "  ✅ Fixed hardcoded JWT secret (now uses JWT_SECRET env var)"
echo "  ✅ Removed hardcoded fallback credentials"
echo "  ✅ Added input validation middleware"
echo "  ✅ Created buffer overflow protection for C collector"
echo "  ✅ Generated secure .env.example template"
echo "  ✅ Created comprehensive security documentation"
echo "  ✅ Added security validation script"
echo ""
echo "⚠️  CRITICAL NEXT STEPS:"
echo "1. Generate JWT secret: openssl rand -base64 32"
echo "2. Copy .env.example to .env and configure with secure values"
echo "3. Run validation: ./scripts/validate_security.sh"
echo "4. Test application: docker-compose up -d"
echo ""
echo "🔐 Your application is now significantly more secure!"
echo "📋 All changes backed up to: $BACKUP_DIR"
