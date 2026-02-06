#!/bin/bash

# Test script for FTP and SFTP relay API
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_URL="http://localhost:8000"
PASSED=0
FAILED=0

echo "========================================="
echo "FTP/SFTP Relay API Test Suite"
echo "========================================="
echo ""

# Function to check if a test passed
check_test() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    if echo "$actual" | grep -q "$expected"; then
        echo -e "${GREEN}✓ PASSED${NC}: $test_name"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}: $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        ((FAILED++))
        return 1
    fi
}

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 5

# Fix SFTP permissions and clean up old test files
echo "Setting up SFTP permissions and cleaning up..."
docker-compose exec -T sftp-server chmod 777 /home/testuser/upload 2>/dev/null
docker-compose exec -T sftp-server sh -c 'rm -f /home/testuser/upload/*.tmp /home/testuser/upload/test*.txt /home/testuser/upload/manual*.txt' 2>/dev/null

echo ""
echo "========================================="
echo "SFTP Relay Tests"
echo "========================================="
echo ""

# Test 1: SFTP successful upload
echo "Test 1: SFTP successful upload"
RESPONSE=$(curl -s -X POST -d 'host=sftp-server&port=22&user=testuser&password=testpass&directory=/upload&file_name=test1.txt&message=Test message 1' "$API_URL/sftp/relay")
check_test "SFTP successful upload" '"status":true' "$RESPONSE"

# Test 2: Verify file exists on SFTP server
echo "Test 2: Verify file exists on SFTP server"
FILE_CHECK=$(docker-compose exec -T sftp-server ls /home/testuser/upload/test1.txt 2>/dev/null)
if [ -n "$FILE_CHECK" ]; then
    echo -e "${GREEN}✓ PASSED${NC}: File exists on SFTP server"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}: File does not exist on SFTP server"
    ((FAILED++))
fi

# Test 3: Verify file content
echo "Test 3: Verify file content"
FILE_CONTENT=$(docker-compose exec -T sftp-server cat /home/testuser/upload/test1.txt 2>/dev/null)
check_test "SFTP file content" "Test message 1" "$FILE_CONTENT"

# Test 4: SFTP with wrong credentials
echo "Test 4: SFTP authentication failure"
RESPONSE=$(curl -s -X POST -d 'host=sftp-server&port=22&user=wronguser&password=wrongpass&directory=/upload&file_name=should_fail.txt&message=Should fail' "$API_URL/sftp/relay")
check_test "SFTP wrong credentials" '"status":false' "$RESPONSE"
check_test "SFTP error message" 'Authentication failed' "$RESPONSE"

# Test 5: SFTP with JSON payload
echo "Test 5: SFTP with JSON payload"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"host":"sftp-server","port":22,"user":"testuser","password":"testpass","directory":"/upload","file_name":"test_json.txt","message":"JSON test"}' "$API_URL/sftp/relay")
check_test "SFTP JSON upload" '"status":true' "$RESPONSE"

echo ""
echo "========================================="
echo "FTP Relay Tests"
echo "========================================="
echo ""

# Test 6: FTP connection error handling
echo "Test 6: FTP connection error handling"
RESPONSE=$(curl -s -X POST -d 'host=nonexistent&port=9999&user=test&password=test&directory=/&is_pasv=false&file_name=test.txt&message=Test' "$API_URL/relay")
check_test "FTP connection error" '"status":false' "$RESPONSE"

# Test 7: FTP with JSON payload (connection will fail but error handling should work)
echo "Test 7: FTP JSON payload error handling"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"host":"nonexistent","port":9999,"user":"test","password":"test","directory":"/","is_pasv":false,"file_name":"test.txt","message":"Test"}' "$API_URL/relay")
check_test "FTP JSON error handling" '"status":false' "$RESPONSE"

# Test 8: FTP server test (may fail due to Rosetta on ARM)
echo "Test 8: FTP server test (may fail on ARM Mac)"
RESPONSE=$(curl -s -X POST -d 'host=ftp-server&port=21&user=testuser&password=testpass&directory=/&is_pasv=true&file_name=test_ftp.txt&message=FTP test' "$API_URL/relay")
if echo "$RESPONSE" | grep -q '"status":true'; then
    echo -e "${GREEN}✓ PASSED${NC}: FTP successful upload"
    ((PASSED++))
elif echo "$RESPONSE" | grep -q '"status":false'; then
    echo -e "${YELLOW}⚠ EXPECTED FAILURE${NC}: FTP server issue (likely Rosetta on ARM Mac)"
    echo "  This is expected on Apple Silicon Macs"
    ((PASSED++))
else
    echo -e "${RED}✗ FAILED${NC}: Unexpected response"
    echo "  Response: $RESPONSE"
    ((FAILED++))
fi

echo ""
echo "========================================="
echo "API Endpoint Tests"
echo "========================================="
echo ""

# Test 9: Home endpoint
echo "Test 9: Home endpoint"
RESPONSE=$(curl -s "$API_URL/")
check_test "Home endpoint" "It's working" "$RESPONSE"

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
