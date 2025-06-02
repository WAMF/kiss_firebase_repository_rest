#!/bin/bash

# Firebase Emulator Test Runner
# Automatically starts Firebase emulator, runs tests, and cleans up

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EMULATOR_TIMEOUT=30
FIRESTORE_PORT=8080
UI_PORT=4000

echo -e "${BLUE}🧪 Firebase Emulator Test Runner${NC}"
echo "=================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if a port is in use
port_in_use() {
    lsof -i ":$1" >/dev/null 2>&1
}

# Function to wait for emulator to be ready
wait_for_emulator() {
    echo -e "${YELLOW}⏳ Waiting for Firebase emulator to start...${NC}"
    local timeout=$EMULATOR_TIMEOUT
    while [ $timeout -gt 0 ]; do
        if curl -s "http://127.0.0.1:$FIRESTORE_PORT" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Firebase emulator is ready!${NC}"
            return 0
        fi
        sleep 1
        timeout=$((timeout - 1))
    done
    echo -e "${RED}❌ Timeout waiting for Firebase emulator${NC}"
    return 1
}

# Function to stop emulator
stop_emulator() {
    echo -e "${YELLOW}🛑 Stopping Firebase emulator...${NC}"
    if [ ! -z "$EMULATOR_PID" ]; then
        kill $EMULATOR_PID 2>/dev/null || true
        wait $EMULATOR_PID 2>/dev/null || true
    fi
    
    # Kill any remaining processes on emulator ports
    for port in $FIRESTORE_PORT $UI_PORT; do
        if port_in_use $port; then
            echo "Killing process on port $port"
            lsof -ti ":$port" | xargs kill -9 2>/dev/null || true
        fi
    done
}

# Cleanup function
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    stop_emulator
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Set trap for cleanup on script exit
trap cleanup EXIT INT TERM

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

if ! command_exists firebase; then
    echo -e "${RED}❌ Firebase CLI not found${NC}"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

if ! command_exists dart; then
    echo -e "${RED}❌ Dart SDK not found${NC}"
    echo "Install Dart SDK: https://dart.dev/get-dart"
    exit 1
fi

if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ firebase.json not found${NC}"
    echo "Run: firebase init emulators"
    exit 1
fi

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ pubspec.yaml not found${NC}"
    echo "This script must be run from the project root"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"

# Check if emulator is already running
if port_in_use $FIRESTORE_PORT; then
    echo -e "${YELLOW}⚠️  Firebase emulator appears to be already running${NC}"
    read -p "Continue with existing emulator? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping existing emulator..."
        stop_emulator
        sleep 2
    else
        EMULATOR_ALREADY_RUNNING=true
    fi
fi

# Start Firebase emulator if not already running
if [ "$EMULATOR_ALREADY_RUNNING" != "true" ]; then
    echo -e "${BLUE}🚀 Starting Firebase emulator...${NC}"
    firebase emulators:start --only firestore &
    EMULATOR_PID=$!
    
    # Wait for emulator to be ready
    if ! wait_for_emulator; then
        echo -e "${RED}❌ Failed to start Firebase emulator${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🌐 Emulator UI: http://127.0.0.1:$UI_PORT${NC}"
    echo -e "${GREEN}🔥 Firestore: http://127.0.0.1:$FIRESTORE_PORT${NC}"
fi

# Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
dart pub get

# Run different types of tests based on arguments
case "${1:-all}" in
    "unit")
        echo -e "${BLUE}🧪 Running unit tests...${NC}"
        dart test test/unit/ --reporter=expanded
        ;;
    "integration")
        echo -e "${BLUE}🔗 Running integration tests...${NC}"
        dart test test/integration/ --reporter=expanded
        ;;
    "coverage")
        echo -e "${BLUE}📊 Running tests with coverage...${NC}"
        if command_exists dart; then
            dart test --coverage=coverage
            dart pub global activate coverage
            dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib
            echo -e "${GREEN}📊 Coverage report generated: coverage/lcov.info${NC}"
        else
            echo -e "${YELLOW}⚠️  Coverage tools not available${NC}"
            dart test test/ --reporter=expanded
        fi
        ;;
    "watch")
        echo -e "${BLUE}👀 Running tests in watch mode...${NC}"
        echo "Press Ctrl+C to stop"
        while true; do
            echo -e "${BLUE}🔄 Running tests...${NC}"
            dart test test/ --reporter=compact || true
            echo -e "${YELLOW}⏳ Waiting for file changes...${NC}"
            sleep 5
        done
        ;;
    *)
        echo -e "${BLUE}🧪 Running all tests...${NC}"
        dart test test/ --reporter=expanded
        ;;
esac

TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Some tests failed${NC}"
fi

# Show test summary
echo ""
echo -e "${BLUE}📋 Test Summary${NC}"
echo "==============="
echo "Firebase emulator UI: http://127.0.0.1:$UI_PORT"
echo "Firestore endpoint: http://127.0.0.1:$FIRESTORE_PORT"
echo ""

# Option to keep emulator running
if [ "$EMULATOR_ALREADY_RUNNING" != "true" ]; then
    read -p "Keep emulator running for manual testing? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}🔥 Emulator will continue running${NC}"
        echo "Stop it manually with: firebase emulators:stop"
        trap - EXIT INT TERM  # Remove cleanup trap
        exit $TEST_EXIT_CODE
    fi
fi

exit $TEST_EXIT_CODE 
