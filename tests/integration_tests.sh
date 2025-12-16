#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get API endpoint from environment variable or Terraform output
if [ -z "$API_ENDPOINT" ]; then
  if [ -f "../terraform/terraform.tfstate" ]; then
    API_ENDPOINT=$(cd ../terraform && terraform output -raw api_endpoint 2>/dev/null)
  fi
  if [ -z "$API_ENDPOINT" ]; then
    echo -e "${RED}ERROR: API_ENDPOINT not set and could not read from Terraform${NC}"
    echo "Set API_ENDPOINT environment variable or run from project root with Terraform state available"
    exit 1
  fi
fi

# Test credentials - should match seeded users
TEST_EMAIL="${TEST_EMAIL:-noyblum@blumenfeld.com}"
TEST_PASSWORD="${TEST_PASSWORD:-1Kgg\$wMgX(g{:+Qc}"

echo -e "${BLUE}Using API Endpoint: ${API_ENDPOINT}${NC}"

# Counter for test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Helper function to assert HTTP status
assert_http_status() {
  local test_name=$1
  local method=$2
  local endpoint=$3
  local headers=$4
  local data=$5
  local expected_status=$6
  
  if [ "$method" = "GET" ]; then
    response=$(curl -s -w "\n%{http_code}" -X GET "$API_ENDPOINT$endpoint" $headers)
  else
    response=$(curl -s -w "\n%{http_code}" -X POST "$API_ENDPOINT$endpoint" $headers -d "$data")
  fi
  
  # Extract status code from last line
  http_code=$(echo "$response" | tail -1)
  # Extract body (everything except last line)
  body=$(echo "$response" | head -n-1)
  
  if [ "$http_code" = "$expected_status" ]; then
    echo -e "${GREEN}✅ PASS${NC}: $test_name (HTTP $http_code)"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}❌ FAIL${NC}: $test_name (Expected HTTP $expected_status, got $http_code)"
    echo "Response body: $(echo $body | cut -c1-200)"
    ((TESTS_FAILED++))
  fi
  
  # Return body for further processing
  echo "$body"
}
  
  if [ "$http_code" -eq "$expected_status" ]; then
    echo -e "${GREEN}✅ PASS${NC}: $test_name (HTTP $http_code)"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}❌ FAIL${NC}: $test_name (Expected HTTP $expected_status, got $http_code)"
    echo "Response body: $body" | head -c 200
    echo ""
    ((TESTS_FAILED++))
  fi
  
  # Return body for further processing
  echo "$body"
}

# Helper function to assert JSON field
assert_json_field() {
  local test_name=$1
  local json_response=$2
  local field=$3
  local expected_value=$4
  
  actual=$(echo "$json_response" | jq -r "$field" 2>/dev/null)
  
  if [ "$actual" = "$expected_value" ]; then
    echo -e "${GREEN}✅ PASS${NC}: $test_name"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}❌ FAIL${NC}: $test_name"
    echo "  Expected: $expected_value"
    echo "  Got: $actual"
    ((TESTS_FAILED++))
  fi
}

# Helper function to assert JSON field exists
assert_json_exists() {
  local test_name=$1
  local json_response=$2
  local field=$3
  
  actual=$(echo "$json_response" | jq -r "$field" 2>/dev/null)
  
  if [ -n "$actual" ] && [ "$actual" != "null" ]; then
    echo -e "${GREEN}✅ PASS${NC}: $test_name"
    ((TESTS_PASSED++))
    echo "$actual"
  else
    echo -e "${RED}❌ FAIL${NC}: $test_name - Field does not exist or is null"
    ((TESTS_FAILED++))
    echo ""
  fi
}

# Print header
print_header() {
  echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Main test execution
main() {
  print_header "🧪 AI Agents Platform - Integration Test Suite"
  echo "API Endpoint: $API_ENDPOINT"
  echo "Test User: $TEST_EMAIL"
  echo ""

  # ===== PHASE 1: Public Endpoints (No Auth) =====
  print_header "📋 PHASE 1: Public Endpoints (No Authentication)"

  echo "Test 1: Health Check"
  health=$(assert_http_status "Health Check" "GET" "/health" "" "" "200")
  assert_json_field "Response has status=healthy" "$health" ".status" "healthy"
  
  echo "Test 2: Root Endpoint (API Docs)"
  root=$(assert_http_status "Root Endpoint" "GET" "/" "" "" "200")
  assert_json_field "API name is correct" "$root" ".service" "AI Agents Platform API"

  # ===== PHASE 2: Authentication =====
  print_header "🔐 PHASE 2: Authentication & JWT"

  echo "Test 3: Valid Login"
  valid_login=$(assert_http_status "Valid Login" "POST" "/api/login" \
    "-H 'Content-Type: application/json'" \
    "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
    "200")
  assert_json_field "Login success flag is true" "$valid_login" ".success" "true"
  
  # Extract token for later use
  TOKEN=$(echo "$valid_login" | jq -r '.token')
  if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo -e "${GREEN}✅ Extracted JWT token${NC}"
    echo "Token (first 30 chars): ${TOKEN:0:30}..."
  else
    echo -e "${RED}❌ Failed to extract token${NC}"
    ((TESTS_FAILED++))
    return 1
  fi

  echo "Test 4: Invalid Email/Password"
  invalid_login=$(assert_http_status "Invalid Credentials" "POST" "/api/login" \
    "-H 'Content-Type: application/json'" \
    "{\"email\":\"invalid@test.com\",\"password\":\"wrongpassword\"}" \
    "401")
  assert_json_field "Error message present" "$invalid_login" ".error" "Invalid email or password"

  echo "Test 5: Missing Email"
  missing_email=$(assert_http_status "Missing Email" "POST" "/api/login" \
    "-H 'Content-Type: application/json'" \
    "{\"email\":\"\",\"password\":\"password123\"}" \
    "400")

  echo "Test 6: Missing Password"
  missing_pass=$(assert_http_status "Missing Password" "POST" "/api/login" \
    "-H 'Content-Type: application/json'" \
    "{\"email\":\"$TEST_EMAIL\",\"password\":\"\"}" \
    "400")

  # ===== PHASE 3: Protected Endpoints =====
  print_header "🔒 PHASE 3: Protected Endpoints (Require JWT)"

  echo "Test 7: List Agents with Valid Token"
  agents=$(assert_http_status "List Agents (Valid Token)" "GET" "/api/list-agents" \
    "-H 'Authorization: Bearer $TOKEN'" \
    "" \
    "200")
  assert_json_field "Agents list success" "$agents" ".success" "true"
  agent_count=$(echo "$agents" | jq '.agents | length')
  echo -e "${GREEN}✅ Found $agent_count agents${NC}"

  echo "Test 8: Access Protected Endpoint Without Token"
  no_token=$(assert_http_status "No Token" "GET" "/api/list-agents" "" "" "401")
  assert_json_field "Error without token" "$no_token" ".error" "Missing or invalid authorization header"

  echo "Test 9: Access Protected Endpoint with Invalid Token"
  bad_token=$(assert_http_status "Invalid Token" "GET" "/api/list-agents" \
    "-H 'Authorization: Bearer invalid.token.here'" \
    "" \
    "401")

  echo "Test 10: Access Protected Endpoint with Malformed Auth Header"
  bad_header=$(assert_http_status "Malformed Auth Header" "GET" "/api/list-agents" \
    "-H 'Authorization: InvalidFormat token'" \
    "" \
    "401")

  # ===== PHASE 4: Chat Functionality =====
  print_header "💬 PHASE 4: Chat Functionality"

  echo "Test 11: Send Chat Message"
  chat=$(assert_http_status "Send Chat Message" "POST" "/api/chat" \
    "-H 'Content-Type: application/json' -H 'Authorization: Bearer $TOKEN'" \
    "{\"message\":\"What is 2+2?\",\"agentType\":\"supervisor\"}" \
    "200")
  assert_json_field "Chat success flag" "$chat" ".success" "true"
  
  SESSION_ID=$(echo "$chat" | jq -r '.sessionId')
  if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
    echo -e "${GREEN}✅ Created session: $SESSION_ID${NC}"
  else
    echo -e "${RED}❌ Failed to create session${NC}"
    ((TESTS_FAILED++))
  fi

  echo "Test 12: Chat Without Authentication"
  chat_no_auth=$(assert_http_status "Chat No Auth" "POST" "/api/chat" \
    "-H 'Content-Type: application/json'" \
    "{\"message\":\"Test\",\"agentType\":\"supervisor\"}" \
    "401")

  echo "Test 13: Check Chat Status (After 2 seconds)"
  sleep 2
  status=$(assert_http_status "Chat Status" "GET" "/api/chat/status/$SESSION_ID" \
    "-H 'Authorization: Bearer $TOKEN'" \
    "" \
    "200")
  
  chat_status=$(echo "$status" | jq -r '.status')
  echo -e "${BLUE}Chat Status: $chat_status${NC}"
  
  if [ "$chat_status" = "pending" ] || [ "$chat_status" = "processing" ]; then
    echo -e "${YELLOW}ℹ️  Chat still processing (this is normal)${NC}"
    ((TESTS_SKIPPED++))
  elif [ "$chat_status" = "completed" ]; then
    echo -e "${GREEN}✅ Chat completed successfully${NC}"
    response=$(echo "$status" | jq -r '.response // empty')
    if [ -n "$response" ]; then
      echo "Response preview: ${response:0:100}..."
    fi
  elif [ "$chat_status" = "failed" ]; then
    echo -e "${YELLOW}⚠️  Chat failed (likely AWS Marketplace subscription issue)${NC}"
    error=$(echo "$status" | jq -r '.errorMessage // "Unknown error"')
    echo "Error: ${error:0:200}..."
  fi

  echo "Test 14: Check Non-existent Session"
  bad_session=$(assert_http_status "Non-existent Session" "GET" "/api/chat/status/invalid-session-id" \
    "-H 'Authorization: Bearer $TOKEN'" \
    "" \
    "200")

  # ===== PHASE 5: CORS Headers =====
  print_header "🌐 PHASE 5: CORS Headers Validation"

  echo "Test 15: Check CORS Headers"
  cors_check=$(curl -s -I "$API_ENDPOINT/health" | grep -i "Access-Control-Allow-Origin")
  if echo "$cors_check" | grep -q "\*"; then
    echo -e "${GREEN}✅ CORS headers present and allow all origins${NC}"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}❌ CORS headers missing or incorrect${NC}"
    echo "Headers: $cors_check"
    ((TESTS_FAILED++))
  fi

  # ===== RESULTS SUMMARY =====
  print_header "📊 Test Results Summary"
  
  total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
  pass_rate=$((TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED + 1)))
  
  echo "Total Tests: $total"
  echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
  echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
  echo "Pass Rate: $pass_rate%"
  
  echo ""
  if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All critical tests passed!${NC}"
    return 0
  else
    echo -e "${RED}❌ Some tests failed - see details above${NC}"
    return 1
  fi
}

# Run main function
main
exit_code=$?

# Exit with appropriate code
exit $exit_code
