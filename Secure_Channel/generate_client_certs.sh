#!/bin/bash

################################################################################
# OwlBoard Client Certificate Generation Script
# 
# Generates client certificates for mTLS (mutual TLS) authentication:
# - API Gateway client certificates for connecting to backend services
#
# Usage: ./generate_client_certs.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OwlBoard Client Certificate Generator${NC}"
echo -e "${BLUE}========================================${NC}"
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

# Check if CA exists
if [ ! -f "ca/ca.crt" ] || [ ! -f "ca/ca.key" ]; then
    echo -e "${RED}Error: CA certificate not found!${NC}"
    echo -e "${YELLOW}Please run ./generate_certs.sh first${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Ensuring directory structure exists...${NC}"
mkdir -p certs/api_gateway
echo -e "${GREEN}✓ Directory structure verified${NC}"
echo ""

echo -e "${YELLOW}Step 2: Generating client certificate for API Gateway...${NC}"

# Generate client private key
openssl genrsa -out certs/api_gateway/client.key 2048

# Generate certificate signing request (CSR)
openssl req -new -key certs/api_gateway/client.key -out certs/api_gateway/client.csr \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=api_gateway_client"

# Generate client certificate signed by CA
openssl x509 -req -days $CERT_VALIDITY -in certs/api_gateway/client.csr \
    -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial \
    -out certs/api_gateway/client.crt

# Clean up CSR
rm certs/api_gateway/client.csr

echo -e "${GREEN}✓ Client certificate generated${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Client certificate generation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Generated client certificates:${NC}"
echo "  - API Gateway Client Cert: certs/api_gateway/client.crt"
echo "  - API Gateway Client Key: certs/api_gateway/client.key"
echo ""
echo -e "${YELLOW}These certificates are used for mTLS authentication${NC}"
echo -e "${YELLOW}between API Gateway and backend services.${NC}"
echo ""
