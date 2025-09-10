#!/bin/bash
# Performance testing script for pganalytics-v2

echo "🏁 Starting Performance Tests..."

# Function to test endpoint performance
test_endpoint() {
    local endpoint=$1
    local description=$2
    
    echo "Testing $description..."
    echo "Endpoint: $endpoint"
    
    # Use Apache Bench for load testing
    ab -n 1000 -c 10 -k "$endpoint" > "performance_results_$(basename $endpoint).txt"
    
    echo "✅ Completed $description test"
    echo ""
}

# Test health endpoint
test_endpoint "http://localhost:8080/health" "Health Endpoint"

# Test metrics endpoint
test_endpoint "http://localhost:8080/metrics" "Metrics Endpoint"

# Test backend health
test_endpoint "http://localhost:8081/health" "Backend Health"

echo "📊 Performance test results saved to performance_results_*.txt files"
echo "🎯 Performance testing completed!"
