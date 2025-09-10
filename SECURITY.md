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
