#!/bin/bash

################################################################################
# OwlBoard Certificate Generation Script
# 
# Generates SSL/TLS certificates for secure communication between services:
# - Certificate Authority (CA)
# - API Gateway certificates
# - Load Balancer certificates
# - Backend service certificates (User, Chat, Auth, Comments, Canvas)
#
# Note: Certificates include localhost and 127.0.0.1 in Subject Alternative Names
# for development/testing. For production, regenerate without these or use 
# certificates from a trusted CA.
#
# Usage: ./generate_certs.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}OwlBoard Certificate Generator${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Certificate validity (in days)
CERT_VALIDITY=3650  # 10 years

# Certificate details
COUNTRY="US"
STATE="CA"
LOCALITY="San Francisco"
ORGANIZATION="OwlBoard"
ORG_UNIT="Engineering"

echo -e "${YELLOW}Step 1: Creating directory structure...${NC}"
mkdir -p ca
mkdir -p certs/api_gateway
mkdir -p certs/load_balancer
mkdir -p certs/user_service
mkdir -p certs/chat_service
mkdir -p certs/auth_service
mkdir -p certs/comments_service
mkdir -p certs/canvas_service
echo -e "${GREEN}✓ Directory structure created${NC}"
echo ""

echo -e "${YELLOW}Step 2: Generating Certificate Authority (CA)...${NC}"
# Generate CA private key
openssl genrsa -out ca/ca.key 4096

# Generate CA certificate
openssl req -new -x509 -days $CERT_VALIDITY -key ca/ca.key -out ca/ca.crt \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=OwlBoard-CA"

echo -e "${GREEN}✓ CA certificate generated${NC}"
echo ""

# Function to generate service certificate
generate_service_cert() {
    local service_name=$1
    local service_dir=$2
    local common_name=$3
    
    echo -e "${YELLOW}Generating certificate for ${service_name}...${NC}"
    
    # Generate private key
    openssl genrsa -out "$service_dir/server.key" 2048
    
    # Generate certificate signing request (CSR)
    openssl req -new -key "$service_dir/server.key" -out "$service_dir/server.csr" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$common_name"
    
    # Generate certificate signed by CA
    openssl x509 -req -days $CERT_VALIDITY -in "$service_dir/server.csr" \
        -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
        -out "$service_dir/server.crt" \
        -extfile <(printf "subjectAltName=DNS:$common_name,DNS:localhost,IP:127.0.0.1")
    
    # Clean up CSR
    rm "$service_dir/server.csr"
    
    echo -e "${GREEN}✓ Certificate for ${service_name} generated${NC}"
}

echo -e "${YELLOW}Step 3: Generating service certificates...${NC}"
echo ""

# Generate certificates for each service
generate_service_cert "API Gateway" "certs/api_gateway" "api_gateway"
generate_service_cert "Load Balancer" "certs/load_balancer" "load_balancer"
generate_service_cert "User Service" "certs/user_service" "user_service"
generate_service_cert "Chat Service" "certs/chat_service" "chat_service"
generate_service_cert "Auth Service" "certs/auth_service" "auth_service"
generate_service_cert "Comments Service" "certs/comments_service" "comments_service"
generate_service_cert "Canvas Service" "certs/canvas_service" "canvas_service"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Certificate generation complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}Generated certificates:${NC}"
echo "  - CA Certificate: ca/ca.crt"
echo "  - CA Key: ca/ca.key"
echo ""
echo "  Service certificates in certs/ directory:"
echo "    - api_gateway/"
echo "    - load_balancer/"
echo "    - user_service/"
echo "    - chat_service/"
echo "    - auth_service/"
echo "    - comments_service/"
echo "    - canvas_service/"
echo ""
echo -e "${YELLOW}Note: Keep ca/ca.key secure and never commit it to version control!${NC}"
echo ""
