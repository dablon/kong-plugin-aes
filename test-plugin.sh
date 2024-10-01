#!/bin/bash

# Configuration
KONG_ADMIN_URL="http://192.150.21.41"
KONG_PROXY_URL="http://192.150.21.42"
SERVICE_ROUTE="webhook"
ENCRYPTION_KEY="12345678901234567890123456789012"
ENCRYPTION_IV="1234567890123456"
NODE_SERVICE_URL="http://192.150.21.43"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to make a request and check the response
make_request() {
    local url=$1
    local method=$2
    local data=$3
    local expected_status=$4
    local description=$5

    echo "Testing: $description"
    echo "URL: $url"
    echo "Method: $method"
    echo "Data: $data"
    
    response=$(curl -s -X $method -H "Content-Type: application/json" -d "$data" -w "\n%{http_code}" $url)
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    echo "Status code: $status_code"

    if [ "$status_code" == "$expected_status" ]; then
        echo -e "${GREEN}Test passed${NC}"
    else
        echo -e "${RED}Test failed. Expected status $expected_status, got $status_code${NC}"
        echo "Response body: $body"
    fi
    echo

}

# Test Kong connectivity
echo "Testing Kong connectivity"
make_request "$KONG_ADMIN_URL" "GET" "" "200" "Kong Admin API"

# Test Kong service with AES encryption plugin
echo "Testing Kong service with AES encryption plugin"
encrypted_data=$(make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/encrypt" "POST" '{"data":"test message"}' "200" "Encrypt data through Kong")
if [ ! -z "$encrypted_data" ]; then
    encrypted_value=$(echo "$encrypted_data" | jq -r '.encrypted // empty' 2>/dev/null)
    if [ ! -z "$encrypted_value" ]; then
        make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/decrypt" "POST" "{\"encryptedData\":\"$encrypted_value\"}" "200" "Decrypt data through Kong"
    else
        echo "Failed to extract encrypted value from response"
    fi
else
    echo "No data received from encryption request"
fi
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/echo" "POST" '{"message":"test echo"}' "200" "Echo request through Kong"

# Test internal Node.js service directly
echo "Testing internal Node.js service directly"
encrypted_data=$(make_request "$NODE_SERVICE_URL/encrypt" "POST" "{\"data\":\"test message\",\"key\":\"$ENCRYPTION_KEY\",\"iv\":\"$ENCRYPTION_IV\"}" "200" "Encrypt data directly")
encrypted_value=$(echo "$encrypted_data" | jq -r '.encrypted // empty' 2>/dev/null)
if [ ! -z "$encrypted_value" ]; then
    make_request "$NODE_SERVICE_URL/decrypt" "POST" "{\"encryptedData\":\"$encrypted_value\",\"key\":\"$ENCRYPTION_KEY\",\"iv\":\"$ENCRYPTION_IV\"}" "200" "Decrypt data directly"
else
    echo "Failed to extract encrypted value from response"
fi
make_request "$NODE_SERVICE_URL/echo" "POST" '{"message":"test echo"}' "200" "Echo request directly"

# Additional test cases
echo "Additional test cases"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data through Kong"
make_request "$NODE_SERVICE_URL/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data directly"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data through Kong"
make_request "$NODE_SERVICE_URL/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data directly"