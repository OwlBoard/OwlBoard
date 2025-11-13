#!/bin/bash

# Verification Script for Centralized Authentication Implementation
# This script checks that all components are properly configured

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════════"
echo "  OwlBoard - Centralized Auth Implementation Verification"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUCCESS=0
WARNINGS=0
ERRORS=0

check_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((SUCCESS++))
}

check_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

check_error() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

echo "1. Checking Auth_Service files..."
echo "─────────────────────────────────────────────────────────"

if [ -f "Auth_Service/app.py" ]; then
    check_success "Auth_Service/app.py exists"
else
    check_error "Auth_Service/app.py missing"
fi

if [ -f "Auth_Service/requirements.txt" ]; then
    check_success "Auth_Service/requirements.txt exists"
else
    check_error "Auth_Service/requirements.txt missing"
fi

if [ -f "Auth_Service/Dockerfile" ]; then
    check_success "Auth_Service/Dockerfile exists"
else
    check_error "Auth_Service/Dockerfile missing"
fi

if [ -d "Auth_Service/src" ]; then
    check_success "Auth_Service/src directory exists"
else
    check_error "Auth_Service/src directory missing"
fi

if [ -f "Auth_Service/src/security.py" ]; then
    check_success "Auth_Service/src/security.py exists"
else
    check_error "Auth_Service/src/security.py missing"
fi

if [ -f "Auth_Service/src/routes/auth_routes.py" ]; then
    check_success "Auth_Service/src/routes/auth_routes.py exists"
else
    check_error "Auth_Service/src/routes/auth_routes.py missing"
fi

echo ""
echo "2. Checking JWT Middleware in services..."
echo "─────────────────────────────────────────────────────────"

if [ -f "User_Service/src/middleware/jwt_middleware.py" ]; then
    check_success "User_Service JWT middleware exists"
else
    check_error "User_Service JWT middleware missing"
fi

if [ -f "Chat_Service/src/middleware/jwt_middleware.py" ]; then
    check_success "Chat_Service JWT middleware exists"
else
    check_error "Chat_Service JWT middleware missing"
fi

if [ -f "Comments_Service/src/middleware/jwt_middleware.py" ]; then
    check_success "Comments_Service JWT middleware exists"
else
    check_error "Comments_Service JWT middleware missing"
fi

if [ -f "Auth_Service/middleware_examples/canvas_service_auth.go" ]; then
    check_success "Canvas_Service Go middleware example exists"
else
    check_warning "Canvas_Service Go middleware example missing"
fi

echo ""
echo "3. Checking docker-compose.yml configuration..."
echo "─────────────────────────────────────────────────────────"

if grep -q "auth_service:" docker-compose.yml; then
    check_success "auth_service defined in docker-compose.yml"
else
    check_error "auth_service not found in docker-compose.yml"
fi

if grep -q "AUTH_SERVICE_URL" docker-compose.yml; then
    check_success "AUTH_SERVICE_URL configured in services"
else
    check_error "AUTH_SERVICE_URL not configured"
fi

if grep -q "JWT_SECRET_KEY" docker-compose.yml; then
    check_success "JWT_SECRET_KEY configured"
else
    check_warning "JWT_SECRET_KEY not found (may be in .env)"
fi

echo ""
echo "4. Checking SSL certificates..."
echo "─────────────────────────────────────────────────────────"

if [ -f "Secure_Channel/ca/ca.crt" ]; then
    check_success "CA certificate exists"
else
    check_warning "CA certificate missing - run ./Secure_Channel/generate_certs.sh"
fi

if [ -d "Secure_Channel/certs/auth_service" ]; then
    check_success "auth_service certificates directory exists"
    
    if [ -f "Secure_Channel/certs/auth_service/server.crt" ]; then
        check_success "auth_service server certificate exists"
    else
        check_warning "auth_service server certificate missing"
    fi
    
    if [ -f "Secure_Channel/certs/auth_service/server.key" ]; then
        check_success "auth_service server key exists"
    else
        check_warning "auth_service server key missing"
    fi
else
    check_warning "auth_service certificates directory missing - run ./Secure_Channel/generate_certs.sh"
fi

echo ""
echo "5. Checking documentation..."
echo "─────────────────────────────────────────────────────────"

if [ -f "AUTH_SERVICE_SUMMARY.md" ]; then
    check_success "AUTH_SERVICE_SUMMARY.md exists"
else
    check_error "AUTH_SERVICE_SUMMARY.md missing"
fi

if [ -f "AUTH_SERVICE_INTEGRATION_GUIDE.md" ]; then
    check_success "AUTH_SERVICE_INTEGRATION_GUIDE.md exists"
else
    check_error "AUTH_SERVICE_INTEGRATION_GUIDE.md missing"
fi

if [ -f "Auth_Service/README.md" ]; then
    check_success "Auth_Service/README.md exists"
else
    check_error "Auth_Service/README.md missing"
fi

if [ -f "CENTRALIZED_AUTH_IMPLEMENTATION.md" ]; then
    check_success "CENTRALIZED_AUTH_IMPLEMENTATION.md exists"
else
    check_error "CENTRALIZED_AUTH_IMPLEMENTATION.md missing"
fi

echo ""
echo "6. Checking environment setup..."
echo "─────────────────────────────────────────────────────────"

if [ -f ".env" ]; then
    check_success ".env file exists"
    
    if grep -q "JWT_SECRET_KEY" .env; then
        check_success "JWT_SECRET_KEY set in .env"
    else
        check_warning "JWT_SECRET_KEY not set in .env"
    fi
else
    check_warning ".env file not found - create from Auth_Service/.env.example"
fi

if [ -f "Auth_Service/.env.example" ]; then
    check_success "Auth_Service/.env.example exists"
else
    check_error "Auth_Service/.env.example missing"
fi

echo ""
echo "7. Checking Python dependencies..."
echo "─────────────────────────────────────────────────────────"

if grep -q "httpx" User_Service/requirements.txt; then
    check_success "httpx in User_Service requirements"
else
    check_error "httpx missing in User_Service requirements"
fi

if grep -q "httpx" Chat_Service/requirements.txt; then
    check_success "httpx in Chat_Service requirements"
else
    check_error "httpx missing in Chat_Service requirements"
fi

if grep -q "httpx" Comments_Service/requirements.txt; then
    check_success "httpx in Comments_Service requirements"
else
    check_error "httpx missing in Comments_Service requirements"
fi

if grep -q "passlib" User_Service/requirements.txt; then
    check_success "passlib in User_Service requirements"
else
    check_error "passlib missing in User_Service requirements"
fi

echo ""
echo "8. Checking tests..."
echo "─────────────────────────────────────────────────────────"

if [ -f "Auth_Service/tests/test_auth.py" ]; then
    check_success "Auth_Service tests exist"
else
    check_warning "Auth_Service tests missing"
fi

if [ -f "Auth_Service/pytest.ini" ]; then
    check_success "Auth_Service pytest.ini exists"
else
    check_warning "Auth_Service pytest.ini missing"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                    VERIFICATION SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Successful checks: $SUCCESS${NC}"
echo -e "${YELLOW}⚠ Warnings: $WARNINGS${NC}"
echo -e "${RED}✗ Errors: $ERRORS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Generate certificates: cd Secure_Channel && ./generate_certs.sh"
        echo "  2. Set JWT secret: echo \"JWT_SECRET_KEY=\$(python3 -c 'import secrets; print(secrets.token_urlsafe(64)')\" >> .env"
        echo "  3. Build and start: docker-compose build && docker-compose up -d"
        echo "  4. Verify health: curl http://localhost:8000/api/auth/health"
        exit 0
    else
        echo -e "${YELLOW}⚠ Verification completed with warnings.${NC}"
        echo ""
        echo "Action required:"
        echo "  - Address warnings above before deploying to production"
        echo "  - Warnings can be ignored for development testing"
        exit 0
    fi
else
    echo -e "${RED}✗ Verification failed with errors.${NC}"
    echo ""
    echo "Action required:"
    echo "  - Fix errors above before proceeding"
    echo "  - Check that all files were created correctly"
    exit 1
fi
