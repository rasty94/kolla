#!/bin/bash
# Test runner script with coverage reporting
# Usage: ./tools/run-tests.sh [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default options
RUN_UNIT=true
RUN_INTEGRATION=false
RUN_FUNCTIONAL=false
COVERAGE=true
FAIL_UNDER=80
VERBOSE=false
OPEN_HTML=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-coverage)
            COVERAGE=false
            shift
            ;;
        --integration)
            RUN_INTEGRATION=true
            shift
            ;;
        --functional)
            RUN_FUNCTIONAL=true
            shift
            ;;
        --all)
            RUN_UNIT=true
            RUN_INTEGRATION=true
            RUN_FUNCTIONAL=true
            shift
            ;;
        --unit-only)
            RUN_UNIT=true
            RUN_INTEGRATION=false
            RUN_FUNCTIONAL=false
            shift
            ;;
        --fail-under)
            FAIL_UNDER="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --open)
            OPEN_HTML=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --no-coverage          Disable coverage reporting"
            echo "  --integration          Run integration tests"
            echo "  --functional           Run functional tests"
            echo "  --all                  Run all test types"
            echo "  --unit-only            Run only unit tests (default)"
            echo "  --fail-under N         Set minimum coverage percentage (default: 80)"
            echo "  --verbose, -v          Enable verbose output"
            echo "  --open                 Open HTML coverage report after tests"
            echo "  --help, -h             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                     # Run unit tests with coverage"
            echo "  $0 --all               # Run all tests"
            echo "  $0 --no-coverage       # Run tests without coverage"
            echo "  $0 --fail-under 85     # Require 85% coverage"
            echo "  $0 --open              # Open HTML report after tests"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Print configuration
echo -e "${GREEN}Kolla Test Runner${NC}"
echo "=================="
echo "Unit tests: $RUN_UNIT"
echo "Integration tests: $RUN_INTEGRATION"
echo "Functional tests: $RUN_FUNCTIONAL"
echo "Coverage: $COVERAGE"
echo "Minimum coverage: ${FAIL_UNDER}%"
echo ""

# Check if running in virtual environment
if [[ -z "$VIRTUAL_ENV" ]]; then
    echo -e "${YELLOW}Warning: Not running in a virtual environment${NC}"
    echo "Consider activating a virtualenv first"
    echo ""
fi

# Clean previous coverage data
if [ "$COVERAGE" = true ]; then
    echo "Cleaning previous coverage data..."
    rm -f .coverage .coverage.* coverage.xml coverage.json
    rm -rf htmlcov/
fi

# Build test command
TEST_CMD="pytest"
TEST_MARKERS=""

# Add markers based on selected tests
if [ "$RUN_UNIT" = true ] && [ "$RUN_INTEGRATION" = false ] && [ "$RUN_FUNCTIONAL" = false ]; then
    TEST_MARKERS="unit"
elif [ "$RUN_INTEGRATION" = true ] && [ "$RUN_UNIT" = false ] && [ "$RUN_FUNCTIONAL" = false ]; then
    TEST_MARKERS="integration"
elif [ "$RUN_FUNCTIONAL" = true ] && [ "$RUN_UNIT" = false ] && [ "$RUN_INTEGRATION" = false ]; then
    TEST_MARKERS="functional"
fi

if [ -n "$TEST_MARKERS" ]; then
    TEST_CMD="$TEST_CMD -m $TEST_MARKERS"
fi

# Add coverage options
if [ "$COVERAGE" = true ]; then
    TEST_CMD="$TEST_CMD --cov=kolla --cov-branch --cov-report=term-missing --cov-report=html --cov-report=xml --cov-fail-under=$FAIL_UNDER"
else
    TEST_CMD="$TEST_CMD --no-cov"
fi

# Add verbose flag
if [ "$VERBOSE" = true ]; then
    TEST_CMD="$TEST_CMD -v"
fi

# Run tests
echo "Running tests..."
echo "Command: $TEST_CMD"
echo ""

if eval "$TEST_CMD"; then
    echo ""
    echo -e "${GREEN}✓ Tests passed!${NC}"
    
    if [ "$COVERAGE" = true ]; then
        echo ""
        echo "Coverage report generated:"
        echo "  - HTML: htmlcov/index.html"
        echo "  - XML: coverage.xml"
        echo "  - JSON: coverage.json"
        
        if [ "$OPEN_HTML" = true ]; then
            echo ""
            echo "Opening HTML coverage report..."
            if command -v xdg-open &> /dev/null; then
                xdg-open htmlcov/index.html
            elif command -v open &> /dev/null; then
                open htmlcov/index.html
            else
                echo "Could not open browser. Please open htmlcov/index.html manually."
            fi
        fi
    fi
    
    exit 0
else
    echo ""
    echo -e "${RED}✗ Tests failed!${NC}"
    
    if [ "$COVERAGE" = true ]; then
        echo ""
        echo "Coverage report (if generated):"
        echo "  - HTML: htmlcov/index.html"
        echo "  - XML: coverage.xml"
    fi
    
    exit 1
fi
