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
    response=$(curl -s -X $method -H "Content-Type: application/json" -d "$data" -w "%{http_code}" $url)
    status_code=${response: -3}
    body=${response:0:${#response}-3}

    if [ "$status_code" == "$expected_status" ]; then
        echo -e "${GREEN}Test passed${NC}"
    else
        echo -e "${RED}Test failed. Expected status $expected_status, got $status_code${NC}"
    fi
    echo "Response body: $body"
    echo
}

# Test Kong service with AES encryption plugin
echo "Testing Kong service with AES encryption plugin"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/encrypt" "POST" '{"data":"test message"}' "200" "Encrypt data through Kong"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/decrypt" "POST" '{"encryptedData":"encrypted_data_from_previous_response"}' "200" "Decrypt data through Kong"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/echo" "POST" '{"message":"test echo"}' "200" "Echo request through Kong"

# Test internal Node.js service directly
echo "Testing internal Node.js service directly"
make_request "$NODE_SERVICE_URL/encrypt" "POST" "{\"data\":\"test message\",\"key\":\"$ENCRYPTION_KEY\",\"iv\":\"$ENCRYPTION_IV\"}" "200" "Encrypt data directly"
make_request "$NODE_SERVICE_URL/decrypt" "POST" "{\"encryptedData\":\"encrypted_data_from_previous_response\",\"key\":\"$ENCRYPTION_KEY\",\"iv\":\"$ENCRYPTION_IV\"}" "200" "Decrypt data directly"
make_request "$NODE_SERVICE_URL/echo" "POST" '{"message":"test echo"}' "200" "Echo request directly"

# Additional test cases
echo "Additional test cases"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data through Kong"
make_request "$NODE_SERVICE_URL/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data directly"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data through Kong"
make_request "$NODE_SERVICE_URL/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data directly"