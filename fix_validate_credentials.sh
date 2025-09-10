#!/bin/bash
# Quick fix for the validateCredentials function that had AWK syntax issues

echo "🔧 Fixing validateCredentials function manually..."

# Create the corrected function
cat > temp_validate_fix.go << 'EOF'
// validateCredentials checks user credentials against database first, then secure fallback
func validateCredentials(username, password string) bool {
	// Input validation
	if len(username) < 3 || len(username) > 50 || len(password) < 6 {
		log.Printf("Invalid credentials format for user: %s", username)
		return false
	}

	// Try database first
	var hashedPassword string
	err := db.QueryRow("SELECT password FROM users WHERE username = $1", username).Scan(&hashedPassword)
	if err == nil {
		err = bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
		if err == nil {
			log.Printf("Database authentication successful for user: %s", username)
			return true
		}
	}
	
	// Only allow admin fallback if explicitly enabled and properly configured
	adminEnabled := getEnv("ADMIN_FALLBACK_ENABLED", "false")
	if adminEnabled == "true" {
		adminUser := getEnv("ADMIN_USERNAME", "")
		adminHashedPass := getEnv("ADMIN_PASSWORD_HASH", "")
		if adminUser != "" && adminHashedPass != "" && username == adminUser {
			err := bcrypt.CompareHashAndPassword([]byte(adminHashedPass), []byte(password))
			if err == nil {
				log.Printf("Admin fallback authentication successful for user: %s", username)
				return true
			}
		}
	}
	
	log.Printf("Authentication failed for user: %s", username)
	return false
}
EOF

# Find and replace the validateCredentials function in main.go
if [ -f "main.go" ]; then
    # Create a backup
    cp main.go main.go.validate_backup
    
    # Extract everything before the validateCredentials function
    awk '/^func validateCredentials/ {exit} {print}' main.go > temp_before.go
    
    # Extract everything after the validateCredentials function
    awk '
    /^func validateCredentials/ {
        inFunction = 1
        braceCount = 0
        next
    }
    inFunction {
        for (i = 1; i <= length($0); i++) {
            c = substr($0, i, 1)
            if (c == "{") braceCount++
            if (c == "}") braceCount--
        }
        if (braceCount < 0) {
            inFunction = 0
            print
        }
        next
    }
    !inFunction {print}
    ' main.go > temp_after.go
    
    # Combine all parts
    cat temp_before.go > main.go
    cat temp_validate_fix.go >> main.go
    echo "" >> main.go
    cat temp_after.go >> main.go
    
    # Clean up temporary files
    rm -f temp_before.go temp_after.go temp_validate_fix.go
    
    echo "✅ Fixed validateCredentials function"
else
    echo "❌ main.go not found"
fi

echo "🎉 validateCredentials function fix completed!"
