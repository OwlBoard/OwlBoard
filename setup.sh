#!/bin/bash

################################################################################
# OwlBoard Setup Script
# 
# This script automates the setup process for OwlBoard, including:
# - Certificate generation for secure communication
# - Docker environment validation
# - Network configuration
# - Service deployment
#
# Usage: ./setup.sh [options]
#   --skip-certs    Skip certificate generation (use existing)
#   --dev           Development mode (skip some checks)
#   --help          Show this help message
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
SKIP_CERTS=false
DEV_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-certs)
            SKIP_CERTS=true
            shift
            ;;
        --dev)
            DEV_MODE=true
            shift
            ;;
        --help)
            head -n 20 "$0" | grep "^#" | sed 's/^# //'
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

################################################################################
# Main Setup
################################################################################

print_header "Welcome to OwlBoard Setup"
echo "This script will set up your OwlBoard environment automatically."
echo ""

# Step 1: Check prerequisites
print_header "Step 1: Checking Prerequisites"

MISSING_DEPS=false

if ! check_command "docker"; then
    print_error "Please install Docker: https://docs.docker.com/get-docker/"
    MISSING_DEPS=true
fi

if ! check_command "docker-compose" && ! docker compose version &> /dev/null; then
    print_error "Please install Docker Compose: https://docs.docker.com/compose/install/"
    MISSING_DEPS=true
else
    print_success "docker compose is available"
fi

if ! check_command "openssl"; then
    print_error "Please install OpenSSL"
    MISSING_DEPS=true
fi

if [ "$MISSING_DEPS" = true ]; then
    print_error "Missing required dependencies. Please install them and run this script again."
    exit 1
fi

# Check Docker daemon
if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker and try again."
    exit 1
fi
print_success "Docker daemon is running"

# Step 2: Generate SSL/TLS Certificates
if [ "$SKIP_CERTS" = false ]; then
    print_header "Step 2: Generating SSL/TLS Certificates"
    
    if [ -f "Secure_Channel/ca/ca.crt" ] && [ -f "Secure_Channel/ca/ca.key" ]; then
        print_warning "CA certificates already exist"
        read -p "Do you want to regenerate them? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping certificate generation"
        else
            cd Secure_Channel
            chmod +x generate_certs.sh
            ./generate_certs.sh
            print_success "Server certificates generated"
            
            # Generate client certificates for mTLS
            if [ -f "generate_client_certs.sh" ]; then
                chmod +x generate_client_certs.sh
                ./generate_client_certs.sh
                print_success "Client certificates generated"
            fi
            cd "$SCRIPT_DIR"
        fi
    else
        print_info "Generating certificates for the first time..."
        cd Secure_Channel
        chmod +x generate_certs.sh
        ./generate_certs.sh
        print_success "Server certificates generated"
        
        # Generate client certificates for mTLS
        if [ -f "generate_client_certs.sh" ]; then
            chmod +x generate_client_certs.sh
            ./generate_client_certs.sh
            print_success "Client certificates generated"
        fi
        cd "$SCRIPT_DIR"
    fi
else
    print_info "Skipping certificate generation (--skip-certs flag)"
fi

# Step 3: Set correct permissions
print_header "Step 3: Setting File Permissions"

# Make all shell scripts executable
find . -name "*.sh" -type f -exec chmod +x {} \;
print_success "Shell scripts are now executable"

# Set correct permissions for certificates
if [ -d "Secure_Channel/certs" ]; then
    chmod 644 Secure_Channel/certs/*/server.crt 2>/dev/null || true
    chmod 644 Secure_Channel/certs/*/client.crt 2>/dev/null || true
    chmod 644 Secure_Channel/ca/ca.crt 2>/dev/null || true
    print_success "Certificate permissions set"
fi

# Step 4: Clean up old containers and networks (optional)
print_header "Step 4: Docker Environment Cleanup"

if docker ps -a | grep -q "owlboard\|api_gateway\|user_service"; then
    print_warning "Found existing OwlBoard containers"
    if [ "$DEV_MODE" = false ]; then
        read -p "Do you want to remove them? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Stopping and removing old containers..."
            docker compose down -v 2>/dev/null || true
            print_success "Old containers removed"
        fi
    fi
else
    print_success "No existing containers found"
fi

# Step 5: Build and start services
print_header "Step 5: Building and Starting Services"

print_info "This may take several minutes on the first run..."
echo ""

# Build all services
print_info "Building Docker images..."
if docker compose build --no-cache; then
    print_success "Docker images built successfully"
else
    print_error "Failed to build Docker images"
    exit 1
fi

# Start services
print_info "Starting services..."
if docker compose up -d; then
    print_success "Services started successfully"
else
    print_error "Failed to start services"
    exit 1
fi

# Step 6: Wait for services to be healthy
print_header "Step 6: Waiting for Services to Start"

print_info "Waiting for databases to be healthy (this may take 30-60 seconds)..."
sleep 10

MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    HEALTHY=$(docker compose ps --format json | jq -r 'select(.Health == "healthy") | .Service' 2>/dev/null | wc -l || echo 0)
    TOTAL=$(docker compose ps --format json | jq -r '.Service' 2>/dev/null | wc -l || echo 0)
    
    if [ "$HEALTHY" -gt 0 ]; then
        echo -ne "\r${GREEN}✓${NC} Healthy services: $HEALTHY (waiting for databases...)"
    fi
    
    # Check if critical services are healthy
    if docker ps | grep -q "mysql_db.*healthy" && \
       docker ps | grep -q "postgres_db.*healthy" && \
       docker ps | grep -q "mongo_db.*healthy"; then
        echo ""
        print_success "All critical databases are healthy"
        break
    fi
    
    sleep 2
    WAITED=$((WAITED + 2))
done

echo ""

# Step 7: Verify deployment
print_header "Step 7: Verifying Deployment"

RUNNING=$(docker compose ps --format json | jq -r 'select(.State == "running") | .Service' 2>/dev/null | wc -l || echo 0)
if [ "$RUNNING" -gt 10 ]; then
    print_success "All services are running ($RUNNING containers)"
else
    print_warning "Some services may not be running yet ($RUNNING containers)"
    print_info "Run 'docker compose ps' to check status"
fi

# Step 8: Display access information
print_header "Setup Complete! 🎉"

echo ""
echo -e "${GREEN}OwlBoard is now running!${NC}"
echo ""
echo "Access your applications at:"
echo ""
echo -e "  ${BLUE}Desktop Frontend:${NC}    http://localhost:3002"
echo -e "  ${BLUE}Mobile Frontend:${NC}     http://localhost:3001"
echo -e "  ${BLUE}API Gateway:${NC}         http://localhost:8000"
echo -e "  ${BLUE}Reverse Proxy:${NC}       http://localhost:9000"
echo ""
echo "Useful commands:"
echo ""
echo -e "  ${YELLOW}View logs:${NC}              docker compose logs -f [service_name]"
echo -e "  ${YELLOW}Check status:${NC}           docker compose ps"
echo -e "  ${YELLOW}Stop services:${NC}          docker compose down"
echo -e "  ${YELLOW}Restart services:${NC}       docker compose restart"
echo -e "  ${YELLOW}View all logs:${NC}          docker compose logs -f"
echo ""
echo "For detailed documentation, see:"
echo "  - README.md"
echo "  - DEPLOYMENT.md"
echo "  - ARCHITECTURE_SECURITY_REPORT.md"
echo ""

# Optional: Show container status
if [ "$DEV_MODE" = false ]; then
    read -p "Do you want to see the container status? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        docker compose ps
    fi
fi

print_success "Setup completed successfully!"
exit 0
