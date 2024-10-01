#!/bin/bash

# Configuration
KONG_ADMIN_URL="http://192.150.21.41"
KONG_PROXY_URL="http://192.150.21.42"
SERVICE_ROUTE="webhook"
ENCRYPTION_KEY="12345678901234567890123456789012"
ENCRYPTION_IV="1234567890123456"
NODE_SERVICE_URL="http://192.150.21.43"
SERVICE_NAME="webhook"
ROUTE_NAME="route_webhook"
PLUGIN_NAME="dbbe5259-21b2-4edc-939e-6e363c3ff1a5"

# Colors and styles
BOLD='\033[1m'
UNDERLINE='\033[4m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BOLD}${UNDERLINE}${BLUE}$1${NC}\n"
}

# Function to print sub-headers
print_subheader() {
    echo -e "\n${BOLD}${CYAN}$1${NC}"
}

# Function to make a request and check the response
make_request() {
    local url=$1
    local method=$2
    local data=$3
    local expected_status=$4
    local description=$5

    echo -e "${YELLOW}Testing:${NC} $description"
    echo -e "${YELLOW}URL:${NC} $url"
    echo -e "${YELLOW}Method:${NC} $method"
    echo -e "${YELLOW}Data:${NC} $data"
    
    response=$(curl -s -X $method -H "Content-Type: application/json" -d "$data" -w "\n%{http_code}" $url)
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    echo -e "${YELLOW}Status code:${NC} $status_code"

    if [ "$status_code" == "$expected_status" ]; then
        echo -e "${GREEN}✔ Test passed${NC}"
    else
        echo -e "${RED}✘ Test failed. Expected status $expected_status, got $status_code${NC}"
    fi
    echo -e "${YELLOW}Response body:${NC} $body\n"
    echo -e "${MAGENTA}------------------------${NC}"
}

# Main execution
print_header "Kong Integration Test Suite"

print_subheader "1. Kong Connectivity"
make_request "$KONG_ADMIN_URL" "GET" "" "200" "Kong Admin API"

print_subheader "2. Kong Service and Route Configuration"
make_request "$KONG_ADMIN_URL/services" "GET" "" "200" "List all services"
make_request "$KONG_ADMIN_URL/routes" "GET" "" "200" "List all routes"
make_request "$KONG_ADMIN_URL/services/$SERVICE_NAME" "GET" "" "200" "Get service details"
make_request "$KONG_ADMIN_URL/routes/$ROUTE_NAME" "GET" "" "200" "Get route details"

print_subheader "3. Kong Service with AES Encryption Plugin"
encrypted_data=$(make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/encrypt" "POST" '{"data":"test message"}' "200" "Encrypt data through Kong")
if [ ! -z "$encrypted_data" ]; then
    encrypted_value=$(echo "$encrypted_data" | jq -r '.encrypted // empty' 2>/dev/null)
    if [ ! -z "$encrypted_value" ]; then
        make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/decrypt" "POST" "{\"encryptedData\":\"$encrypted_value\"}" "200" "Decrypt data through Kong"
    else
        echo -e "${RED}Failed to extract encrypted value from response${NC}"
    fi
else
    echo -e "${RED}No data received from encryption request${NC}"
fi
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/echo" "POST" '{"message":"test echo"}' "200" "Echo request through Kong"

print_subheader "4. Internal Node.js Service Direct Testing"
encrypted_data=$(make_request "$NODE_SERVICE_URL/encrypt" "POST" "{\"data\":\"test message\",\"key\":\"$ENCRYPTION_KEY\",\"iv\":\"$ENCRYPTION_IV\"}" "200" "Encrypt data directly")
encrypted_value=$(echo "$encrypted_data" | jq -r '.encrypted // empty' 2>/dev/null)
if [ ! -z "$encrypted_value" ]; then
    make_request "$NODE_SERVICE_URL/decrypt" "POST" "{\"encryptedData\":\"$encrypted_value\",\"key\":\"$ENCRYPTION_KEY\",\"iv\":\"$ENCRYPTION_IV\"}" "200" "Decrypt data directly"
else
    echo -e "${RED}Failed to extract encrypted value from response${NC}"
fi
make_request "$NODE_SERVICE_URL/echo" "POST" '{"message":"test echo"}' "200" "Echo request directly"

print_subheader "5. Additional Test Cases"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data through Kong"
make_request "$NODE_SERVICE_URL/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data directly"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data through Kong"
make_request "$NODE_SERVICE_URL/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data directly"

print_subheader "6. Plugin Configuration"
make_request "$KONG_ADMIN_URL/plugins" "GET" "" "200" "List all plugins"
make_request "$KONG_ADMIN_URL/plugins/$PLUGIN_NAME" "GET" "" "200" "Get plugin details"

print_header "Test Suite Completed"