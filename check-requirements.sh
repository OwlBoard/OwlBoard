#!/bin/bash

################################################################################
# OwlBoard Pre-Installation Checker
# 
# This script checks if your system meets all requirements to run OwlBoard
# Run this before attempting to install OwlBoard
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OwlBoard Pre-Installation Checker   ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# Function to check command
check_command() {
    local cmd=$1
    local required=$2
    local min_version=$3
    
    if command -v "$cmd" &> /dev/null; then
        local version=$(eval "$4" 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓${NC} $cmd is installed (version: $version)"
        
        # Check version if specified
        if [ ! -z "$min_version" ] && [ "$version" != "unknown" ]; then
            # Version comparison would go here
            :
        fi
        return 0
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}✗${NC} $cmd is NOT installed (REQUIRED)"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${YELLOW}⚠${NC} $cmd is NOT installed (optional)"
            WARNINGS=$((WARNINGS + 1))
        fi
        return 1
    fi
}

# Check OS
echo -e "${BLUE}[1/7] Operating System${NC}"
echo "  OS: $(uname -s)"
echo "  Kernel: $(uname -r)"
echo "  Architecture: $(uname -m)"
echo ""

# Check required tools
echo -e "${BLUE}[2/7] Required Tools${NC}"
check_command "docker" "required" "" "docker --version | cut -d' ' -f3 | tr -d ','"
check_command "docker-compose" "optional" "" "docker-compose --version | cut -d' ' -f4 | tr -d ','" || \
    check_command "docker" "required" "" "docker compose version --short"
check_command "git" "required" "" "git --version | cut -d' ' -f3"
check_command "openssl" "required" "" "openssl version | cut -d' ' -f2"
echo ""

# Check Docker status
echo -e "${BLUE}[3/7] Docker Service${NC}"
if docker info &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker daemon is running"
    
    # Check Docker version
    DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
    echo "  Docker version: $DOCKER_VERSION"
    
    # Check Docker Compose version
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version --short)
        echo "  Docker Compose version: $COMPOSE_VERSION"
        echo -e "${GREEN}✓${NC} Docker Compose V2 is available (recommended)"
    elif docker-compose --version &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f4 | tr -d ',')
        echo "  Docker Compose version: $COMPOSE_VERSION (V1)"
        echo -e "${YELLOW}⚠${NC} Using Docker Compose V1 (V2 recommended)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}✗${NC} Docker daemon is NOT running"
    echo "  Please start Docker Desktop or run: sudo systemctl start docker"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check ports
echo -e "${BLUE}[4/7] Port Availability${NC}"
PORTS=(3001 3002 8000 9000)
PORT_NAMES=("Mobile Frontend" "Desktop Frontend" "API Gateway" "Reverse Proxy")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${PORT_NAMES[$i]}
    
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 || \
       netstat -tuln 2>/dev/null | grep -q ":$PORT " || \
       ss -tuln 2>/dev/null | grep -q ":$PORT "; then
        echo -e "${YELLOW}⚠${NC} Port $PORT is already in use ($NAME)"
        WARNINGS=$((WARNINGS + 1))
        
        # Try to show what's using the port
        if command -v lsof &> /dev/null; then
            PROCESS=$(lsof -Pi :$PORT -sTCP:LISTEN -t 2>/dev/null | head -1)
            if [ ! -z "$PROCESS" ]; then
                echo "    Process: $(ps -p $PROCESS -o comm= 2>/dev/null || echo 'unknown')"
            fi
        fi
    else
        echo -e "${GREEN}✓${NC} Port $PORT is available ($NAME)"
    fi
done
echo ""

# Check disk space
echo -e "${BLUE}[5/7] Disk Space${NC}"
AVAILABLE_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$AVAILABLE_SPACE" -gt 10 ]; then
    echo -e "${GREEN}✓${NC} Sufficient disk space available (${AVAILABLE_SPACE}GB free)"
else
    echo -e "${YELLOW}⚠${NC} Low disk space (${AVAILABLE_SPACE}GB free, recommend 10GB+)"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check memory
echo -e "${BLUE}[6/7] System Memory${NC}"
if command -v free &> /dev/null; then
    TOTAL_MEM=$(free -g | grep Mem | awk '{print $2}')
    AVAIL_MEM=$(free -g | grep Mem | awk '{print $7}')
    echo "  Total: ${TOTAL_MEM}GB"
    echo "  Available: ${AVAIL_MEM}GB"
    
    if [ "$AVAIL_MEM" -gt 4 ]; then
        echo -e "${GREEN}✓${NC} Sufficient memory available"
    else
        echo -e "${YELLOW}⚠${NC} Low available memory (recommend 4GB+ free)"
        WARNINGS=$((WARNINGS + 1))
    fi
elif command -v vm_stat &> /dev/null; then
    # macOS
    echo "  macOS system detected"
    echo -e "${GREEN}✓${NC} Memory check (detailed info not available)"
else
    echo -e "${YELLOW}⚠${NC} Could not check memory"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Check network connectivity
echo -e "${BLUE}[7/7] Network Connectivity${NC}"
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Internet connection available"
else
    echo -e "${YELLOW}⚠${NC} No internet connection detected"
    echo "  Docker will need internet to pull images"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Docker Hub connectivity
if docker pull hello-world &> /dev/null; then
    echo -e "${GREEN}✓${NC} Can pull images from Docker Hub"
    docker rmi hello-world &> /dev/null
else
    echo -e "${YELLOW}⚠${NC} Cannot pull images from Docker Hub"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}             Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Your system meets all requirements!${NC}"
    echo ""
    echo "You can now run OwlBoard with:"
    echo "  ./setup.sh"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Found $WARNINGS warning(s)${NC}"
    echo ""
    echo "Your system meets minimum requirements but has some warnings."
    echo "You can proceed with installation, but may encounter issues."
    echo ""
    echo "To continue anyway, run:"
    echo "  ./setup.sh"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors before proceeding with installation."
    echo ""
    
    # Provide helpful installation links
    echo "Installation guides:"
    echo "  Docker: https://docs.docker.com/get-docker/"
    echo "  Docker Compose: https://docs.docker.com/compose/install/"
    echo "  Git: https://git-scm.com/downloads"
    echo ""
    
    exit 1
fi
