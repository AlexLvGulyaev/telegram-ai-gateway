#!/bin/bash

# =============================================================================
# Telegram AI Gateway - Deployment Validation Script
# =============================================================================
# This script validates that the project is properly deployed and configured.
# Run this script after deploying the project.
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASS=$((PASS+1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    FAIL=$((FAIL+1))
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
    WARN=$((WARN+1))
}

section() {
    echo ""
    echo "=== $1 ==="
}

# =============================================================================
# 1. Prerequisites
# =============================================================================

section "Prerequisites"

# Check Docker
if command -v docker &> /dev/null; then
    pass "Docker is installed"
else
    fail "Docker is not installed"
fi

# Check Docker Compose
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    pass "Docker Compose is installed"
else
    fail "Docker Compose is not installed"
fi

# Check Git
if command -v git &> /dev/null; then
    pass "Git is installed"
else
    fail "Git is not installed"
fi

# =============================================================================
# 2. Configuration Files
# =============================================================================

section "Configuration Files"

# Check .env file
if [ -f .env ]; then
    pass ".env file exists"
else
    fail ".env file does not exist (copy .env.example to .env)"
fi

# Check docker-compose.yml
if [ -f docker-compose.yml ]; then
    pass "docker-compose.yml exists"
else
    fail "docker-compose.yml does not exist"
fi

# Check workflow files
if [ -f "workflows/Telegram AI Gateway.json" ]; then
    pass "Telegram AI Gateway.json exists"
else
    fail "Telegram AI Gateway.json does not exist"
fi

if [ -f "workflows/Telegram AI Gateway - Log Writer.json" ]; then
    pass "Telegram AI Gateway - Log Writer.json exists"
else
    fail "Telegram AI Gateway - Log Writer.json does not exist"
fi

# =============================================================================
# 3. Environment Variables
# =============================================================================

section "Environment Variables"

# Check required variables
check_env_var() {
    local var=$1
    local value=$(grep "^${var}=" .env 2>/dev/null | cut -d'=' -f2)

    if [ -n "$value" ] && [ "$value" != "your_secure_password_here" ] && [ "$value" != "your_telegram_bot_token_here" ] && [ "$value" != "your_base64_credentials_here" ]; then
        pass "${var} is set"
    else
        fail "${var} is not set or has placeholder value"
    fi
}

if [ -f .env ]; then
    check_env_var "POSTGRES_PASSWORD"
    check_env_var "N8N_BASIC_AUTH_USER"
    check_env_var "N8N_BASIC_AUTH_PASSWORD"
    check_env_var "TELEGRAM_BOT_TOKEN"
    check_env_var "GIGACHAT_AUTH_KEY"
else
    fail "Cannot check environment variables (.env not found)"
fi

# =============================================================================
# 4. Docker Containers
# =============================================================================

section "Docker Containers"

# Check if containers are running
check_container() {
    local container=$1
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        pass "${container} is running"
    else
        fail "${container} is not running"
    fi
}

check_container "telegram-ai-gateway-postgres"
check_container "telegram-ai-gateway-n8n"

# Check container health
check_health() {
    local container=$1
    local health=$(docker inspect --format='{{.State.Health.Status}}' ${container} 2>/dev/null || echo "unknown")

    if [ "$health" = "healthy" ]; then
        pass "${container} is healthy"
    elif [ "$health" = "unknown" ]; then
        warn "${container} has no health check"
    else
        fail "${container} is ${health}"
    fi
}

check_health "telegram-ai-gateway-n8n"

# =============================================================================
# 5. Network Connectivity
# =============================================================================

section "Network Connectivity"

# Check if n8n is accessible
if curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/healthz | grep -q "200"; then
    pass "n8n is accessible"
else
    fail "n8n is not accessible"
fi

# Check PostgreSQL connection
if docker exec telegram-ai-gateway-postgres pg_isready -U n8n -d n8n &> /dev/null; then
    pass "PostgreSQL is accessible"
else
    fail "PostgreSQL is not accessible"
fi

# =============================================================================
# 6. External APIs
# =============================================================================

section "External APIs"

# Check Telegram Bot Token
check_telegram() {
    local token=$(grep "^TELEGRAM_BOT_TOKEN=" .env 2>/dev/null | cut -d'=' -f2)

    if [ -z "$token" ]; then
        fail "TELEGRAM_BOT_TOKEN not set"
        return
    fi

    if curl -s "https://api.telegram.org/bot${token}/getMe" | grep -q '"ok":true'; then
        pass "Telegram Bot Token is valid"
    else
        fail "Telegram Bot Token is invalid"
    fi
}

check_telegram

# Note: GigaChat API validation requires making a request, which consumes quota
warn "GigaChat API validation requires making a request (not tested automatically)"

# =============================================================================
# 7. Workflow
# =============================================================================

section "Workflow"

# Check if workflow is active
# Note: This requires n8n CLI or API access
warn "Workflow activation check requires manual verification in n8n UI"

# =============================================================================
# 8. Functional Tests
# =============================================================================

section "Functional Tests"

# Test sending a message to the bot
# Note: This requires a test message, which should be done manually
warn "Functional tests require manual testing with Telegram bot"

# =============================================================================
# 9. Documentation
# =============================================================================

section "Documentation"

# Check if documentation exists
check_doc() {
    local doc=$1
    if [ -f "docs/${doc}" ]; then
        pass "docs/${doc} exists"
    else
        fail "docs/${doc} does not exist"
    fi
}

check_doc "architecture.md"
check_doc "setup.md"
check_doc "deployment_guide.md"
check_doc "workflow_overview.md"
check_doc "limitations.md"
check_doc "known_issues.md"

# Check README
if [ -f README.md ]; then
    pass "README.md exists"
else
    fail "README.md does not exist"
fi

# Check LICENSE
if [ -f LICENSE ]; then
    pass "LICENSE exists"
else
    fail "LICENSE does not exist"
fi

# =============================================================================
# 10. Security
# =============================================================================

section "Security"

# Check if .gitignore exists
if [ -f .gitignore ]; then
    pass ".gitignore exists"
else
    fail ".gitignore does not exist"
fi

# Check if .env is in .gitignore
if grep -q ".env" .gitignore 2>/dev/null; then
    pass ".env is in .gitignore"
else
    fail ".env is not in .gitignore"
fi

# Check if real .env is committed (should not be)
if [ -f .env ] && git ls-files --error-unmatch .env &> /dev/null; then
    fail ".env is committed to Git (should be ignored)"
else
    pass ".env is not committed to Git"
fi

# =============================================================================
# Summary
# =============================================================================

section "Summary"

echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo "Warnings: ${WARN}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some checks failed. Please fix them before proceeding.${NC}"
    exit 1
fi