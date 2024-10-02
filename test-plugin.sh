#!/bin/bash

# Configuration
KONG_ADMIN_URL="http://192.150.21.41"
KONG_PROXY_URL="http://192.150.21.42"
SERVICE_ROUTE_WITH_PLUGIN="webhook"
SERVICE_ROUTE_WITHOUT_PLUGIN="mifare"
ENCRYPTION_KEY="12345678901234567890123456789012"
ENCRYPTION_IV="1234567890123456"
NODE_SERVICE_URL="http://192.150.21.43"
SERVICE_NAME_WITH_PLUGIN="webhook"
SERVICE_NAME_WITHOUT_PLUGIN="webhook-sinplugin"
ROUTE_NAME_WITH_PLUGIN="route_webhook"
ROUTE_NAME_WITHOUT_PLUGIN="route_mifare"
PLUGIN_NAME="dbbe5259-21b2-4edc-939e-6e363c3ff1a5"

# Colors and styles
BOLD='\033[1m'
CYAN='\033[0;36m'
UNDERLINE='\033[4m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
MAGENTA='\033[0;35m'
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
        if [ "$status_code" == "000" ]; then
            echo -e "${RED}Error: Connection failed. Please check if the service is running and accessible.${NC}"
        fi
    fi
    echo -e "${YELLOW}Response body:${NC} $body\n"
    echo -e "${MAGENTA}------------------------${NC}"

    echo "$body"
}

# Function to make a request with detailed error handling
make_request_with_error_handling() {
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
        if [ "$status_code" == "000" ]; then
            echo -e "${RED}Error: Connection failed. Please check if the service is running and accessible.${NC}"
        elif [ "$status_code" == "502" ]; then
            echo -e "${RED}Error: Bad Gateway. The Kong proxy might be unable to reach the upstream service.${NC}"
        fi
    fi
    echo -e "${YELLOW}Response body:${NC} $body\n"
    echo -e "${MAGENTA}------------------------${NC}"

    echo "$body"
}

# Main execution
print_header "Enhanced Kong Integration Test Suite"

print_subheader "1. Kong Connectivity"
make_request "$KONG_ADMIN_URL" "GET" "" "200" "Kong Admin API"

print_subheader "2. Kong Service and Route Configuration"
make_request "$KONG_ADMIN_URL/services" "GET" "" "200" "List all services"
make_request "$KONG_ADMIN_URL/routes" "GET" "" "200" "List all routes"
make_request "$KONG_ADMIN_URL/services/$SERVICE_NAME_WITH_PLUGIN" "GET" "" "200" "Get service details (with plugin)"
make_request "$KONG_ADMIN_URL/services/$SERVICE_NAME_WITHOUT_PLUGIN" "GET" "" "200" "Get service details (without plugin)"
make_request "$KONG_ADMIN_URL/routes/$ROUTE_NAME_WITH_PLUGIN" "GET" "" "200" "Get route details (with plugin)"
make_request "$KONG_ADMIN_URL/routes/$ROUTE_NAME_WITHOUT_PLUGIN" "GET" "" "200" "Get route details (without plugin)"

print_subheader "3. Plugin Configuration Checks"
make_request "$KONG_ADMIN_URL/plugins" "GET" "" "200" "List all plugins"
make_request "$KONG_ADMIN_URL/plugins/$PLUGIN_NAME" "GET" "" "200" "Get specific plugin details"
make_request "$KONG_ADMIN_URL/services/$SERVICE_NAME_WITH_PLUGIN/plugins" "GET" "" "200" "List plugins for service with plugin"
make_request "$KONG_ADMIN_URL/plugins?name=aes-encryption" "GET" "" "200" "Check for AES encryption plugin"

print_subheader "4. Kong Service with AES Encryption Plugin"

# Test connectivity to the Kong Proxy
echo -e "${YELLOW}Testing connectivity to Kong Proxy${NC}"
curl_output=$(curl -s -o /dev/null -w "%{http_code}" $KONG_PROXY_URL)
if [ "$curl_output" != "000" ]; then
    echo -e "${GREEN}✔ Kong Proxy is reachable${NC}"
else
    echo -e "${RED}✘ Kong Proxy is not reachable. Please check the KONG_PROXY_URL.${NC}"
fi

# Test encrypt endpoint
encrypted_data=$(make_request_with_error_handling "$KONG_PROXY_URL/$SERVICE_ROUTE_WITH_PLUGIN/encrypt" "POST" '{"data":"test message"}' "200" "Encrypt data through Kong (with plugin)")

# Test decrypt endpoint
if [ ! -z "$encrypted_data" ]; then
    encrypted_value=$(echo "$encrypted_data" | jq -r '.encrypted // empty' 2>/dev/null)
    if [ ! -z "$encrypted_value" ]; then
        make_request_with_error_handling "$KONG_PROXY_URL/$SERVICE_ROUTE_WITH_PLUGIN/decrypt" "POST" "{\"encryptedData\":\"$encrypted_value\"}" "200" "Decrypt data through Kong (with plugin)"
    else
        echo -e "${RED}Failed to extract encrypted value from response${NC}"
    fi
else
    echo -e "${RED}No data received from encryption request${NC}"
fi

# Test echo endpoint
make_request_with_error_handling "$KONG_PROXY_URL/$SERVICE_ROUTE_WITH_PLUGIN/echo" "POST" '{"message":"test echo"}' "200" "Echo request through Kong (with plugin)"

print_subheader "5. Kong Service without Plugin"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE_WITHOUT_PLUGIN/encrypt" "POST" '{"data":"test message"}' "200" "Encrypt data through Kong (without plugin)"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE_WITHOUT_PLUGIN/decrypt" "POST" '{"encryptedData":"81aee295f1a2a221e6554649ea21a45c"}' "200" "Decrypt data through Kong (without plugin)"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE_WITHOUT_PLUGIN/echo" "POST" '{"message":"test echo"}' "200" "Echo request through Kong (without plugin)"

print_subheader "6. Internal Node.js Service Direct Testing"
encrypted_data=$(make_request "$NODE_SERVICE_URL/encrypt" "POST" "{\"data\":\"test message\",\"key\":\"$ENCRYPTION_KEY\",\"iv\":\"$ENCRYPTION_IV\"}" "200" "Encrypt data directly")
encrypted_value=$(echo "$encrypted_data" | jq -r '.encrypted // empty' 2>/dev/null)
if [ ! -z "$encrypted_value" ]; then
    make_request "$NODE_SERVICE_URL/decrypt" "POST" "{\"encryptedData\":\"$encrypted_value\",\"key\":\"$ENCRYPTION_KEY\",\"iv\":\"$ENCRYPTION_IV\"}" "200" "Decrypt data directly"
else
    echo -e "${RED}Failed to extract encrypted value from response${NC}"
fi
make_request "$NODE_SERVICE_URL/echo" "POST" '{"message":"test echo"}' "200" "Echo request directly"

print_subheader "7. Additional Test Cases"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE_WITH_PLUGIN/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data through Kong (with plugin)"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE_WITHOUT_PLUGIN/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data through Kong (without plugin)"
make_request "$NODE_SERVICE_URL/encrypt" "POST" '{"data":""}' "400" "Encrypt empty data directly"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE_WITH_PLUGIN/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data through Kong (with plugin)"
make_request "$KONG_PROXY_URL/$SERVICE_ROUTE_WITHOUT_PLUGIN/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data through Kong (without plugin)"
make_request "$NODE_SERVICE_URL/decrypt" "POST" '{"encryptedData":"invalid_data"}' "500" "Decrypt invalid data directly"

print_subheader "8. Plugin Configuration Verification"
plugin_config=$(curl -s $KONG_ADMIN_URL/plugins/$PLUGIN_NAME)
echo -e "${YELLOW}Plugin configuration:${NC} $plugin_config"
if [[ $plugin_config == *"$SERVICE_NAME_WITH_PLUGIN"* ]]; then
    echo -e "${GREEN}✔ Plugin is correctly associated with the service${NC}"
else
    echo -e "${RED}✘ Plugin is not correctly associated with the service${NC}"
fi

# Check if the plugin is enabled and configured correctly
echo -e "\n${YELLOW}Checking plugin configuration:${NC}"
curl -s $KONG_ADMIN_URL/plugins/$PLUGIN_NAME | grep -E "config.*(encryption_key|iv)"

print_header "Enhanced Test Suite Completed"

echo -e "\n${YELLOW}Diagnostic Information:${NC}"
echo "1. Verify that the AES encryption plugin is installed and enabled in Kong."
echo "2. Check if the plugin is correctly associated with the '$SERVICE_NAME_WITH_PLUGIN' service."
echo "3. Ensure that the encryption key and IV in the plugin configuration match the ones used in the tests."
echo "4. Verify that the Node.js service is correctly implementing the encryption and decryption endpoints."
echo "5. Check Kong logs for any error messages related to the plugin or service."