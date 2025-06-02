#!/bin/bash

# Test Environment Setup Checker
# Verifies all prerequisites for running Firebase emulator tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Firebase Repository Test Setup Checker${NC}"
echo "==========================================="
echo ""

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    lsof -i ":$1" >/dev/null 2>&1 2>/dev/null || false
}

ISSUES_FOUND=0

echo -e "${BLUE}Checking Prerequisites...${NC}"
echo ""

# Check Dart SDK
if command_exists dart; then
    DART_VERSION=$(dart --version 2>&1 | head -n1)
    echo -e "✅ Dart SDK: ${GREEN}${DART_VERSION}${NC}"
else
    echo -e "❌ Dart SDK: ${RED}Not found${NC}"
    echo "   Install from: https://dart.dev/get-dart"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node --version)
    echo -e "✅ Node.js: ${GREEN}${NODE_VERSION}${NC}"
else
    echo -e "❌ Node.js: ${RED}Not found${NC}"
    echo "   Install from: https://nodejs.org/"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check npm
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    echo -e "✅ npm: ${GREEN}v${NPM_VERSION}${NC}"
else
    echo -e "❌ npm: ${RED}Not found${NC}"
    echo "   Usually installed with Node.js"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check Firebase CLI
if command_exists firebase; then
    FIREBASE_VERSION=$(firebase --version)
    echo -e "✅ Firebase CLI: ${GREEN}${FIREBASE_VERSION}${NC}"
    
    # Check Firebase CLI version (need 8.14+)
    VERSION_NUM=$(echo $FIREBASE_VERSION | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    MAJOR=$(echo $VERSION_NUM | cut -d. -f1)
    MINOR=$(echo $VERSION_NUM | cut -d. -f2)
    
    if [ "$MAJOR" -gt 8 ] || ([ "$MAJOR" -eq 8 ] && [ "$MINOR" -ge 14 ]); then
        echo -e "   ${GREEN}Version is compatible${NC}"
    else
        echo -e "   ${YELLOW}Warning: Version $VERSION_NUM may be too old (need 8.14+)${NC}"
        echo "   Update with: npm install -g firebase-tools"
    fi
else
    echo -e "❌ Firebase CLI: ${RED}Not found${NC}"
    echo "   Install with: npm install -g firebase-tools"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo ""
echo -e "${BLUE}Checking Project Files...${NC}"
echo ""

# Check firebase.json
if [ -f "firebase.json" ]; then
    echo -e "✅ firebase.json: ${GREEN}Found${NC}"
    
    # Check if Firestore emulator is configured
    if grep -q '"firestore"' firebase.json; then
        echo -e "   ${GREEN}Firestore emulator configured${NC}"
    else
        echo -e "   ${YELLOW}Warning: Firestore emulator not configured${NC}"
        echo "   Run: firebase init emulators"
    fi
else
    echo -e "❌ firebase.json: ${RED}Not found${NC}"
    echo "   Run: firebase init emulators"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    echo -e "✅ pubspec.yaml: ${GREEN}Found${NC}"
    
    # Check for test dependencies
    if grep -q "test:" pubspec.yaml; then
        echo -e "   ${GREEN}Test framework configured${NC}"
    else
        echo -e "   ${YELLOW}Warning: Test framework not found in dependencies${NC}"
    fi
else
    echo -e "❌ pubspec.yaml: ${RED}Not found${NC}"
    echo "   Make sure you're in the project root directory"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check test directory
if [ -d "test" ]; then
    TEST_COUNT=$(find test -name "*.dart" | wc -l)
    echo -e "✅ Test directory: ${GREEN}Found (${TEST_COUNT} test files)${NC}"
else
    echo -e "❌ Test directory: ${RED}Not found${NC}"
    echo "   Create with: mkdir test"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

echo ""
echo -e "${BLUE}Checking Network/Ports...${NC}"
echo ""

# Check if emulator ports are available
FIRESTORE_PORT=8080
UI_PORT=4000

if port_in_use $FIRESTORE_PORT; then
    echo -e "⚠️  Port $FIRESTORE_PORT: ${YELLOW}In use (Firebase emulator may be running)${NC}"
else
    echo -e "✅ Port $FIRESTORE_PORT: ${GREEN}Available${NC}"
fi

if port_in_use $UI_PORT; then
    echo -e "⚠️  Port $UI_PORT: ${YELLOW}In use${NC}"
else
    echo -e "✅ Port $UI_PORT: ${GREEN}Available${NC}"
fi

echo ""
echo -e "${BLUE}Checking Dependencies...${NC}"
echo ""

if [ -f "pubspec.yaml" ]; then
    echo "Running dart pub get..."
    if dart pub get > /dev/null 2>&1; then
        echo -e "✅ Dependencies: ${GREEN}Resolved successfully${NC}"
    else
        echo -e "❌ Dependencies: ${RED}Failed to resolve${NC}"
        echo "   Run: dart pub get"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi

echo ""
echo "========================================="

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "🎉 ${GREEN}All checks passed! Your test environment is ready.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Start Firebase emulator: firebase emulators:start"
    echo "2. Run tests: dart test --reporter=expanded"
    echo "3. Or use the automated script: ./scripts/test_with_emulator.sh"
else
    echo -e "⚠️  ${YELLOW}Found $ISSUES_FOUND issue(s) that need attention.${NC}"
    echo ""
    echo -e "${BLUE}Please resolve the issues above before running tests.${NC}"
fi

echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "• Check this setup: ./scripts/check_test_setup.sh"
echo "• Run all tests: ./scripts/test_with_emulator.sh"
echo "• Run unit tests: ./scripts/test_with_emulator.sh unit"
echo "• Run integration tests: ./scripts/test_with_emulator.sh integration"
echo "• Run with coverage: ./scripts/test_with_emulator.sh coverage"

exit $ISSUES_FOUND 
