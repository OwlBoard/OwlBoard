# OwlBoard Secure Channel

This directory contains scripts and infrastructure for generating SSL/TLS certificates used for secure communication between OwlBoard services.

## Contents

- `generate_certs.sh` - Main certificate generation script for all services
- `generate_client_certs.sh` - Client certificate generation for mTLS authentication
- `ca/` - Certificate Authority (CA) certificates and keys
- `certs/` - Service-specific certificates and keys

## Usage

### First-time Setup

Generate all certificates:
```bash
./generate_certs.sh
./generate_client_certs.sh
```

Or use the Makefile from the root directory:
```bash
make certificates
```

### What Gets Generated

1. **Certificate Authority (CA)**
   - `ca/ca.crt` - CA certificate (can be shared)
   - `ca/ca.key` - CA private key (NEVER commit to version control)

2. **Service Certificates** (in `certs/` subdirectories)
   - `server.crt` - Server certificate
   - `server.key` - Server private key (NEVER commit)
   - `client.crt` - Client certificate (for API Gateway)
   - `client.key` - Client private key (NEVER commit)

## Security Notes

⚠️ **IMPORTANT**: Never commit private keys (`.key` files) to version control!

- The `.gitignore` file is configured to exclude all `.key` files
- Regenerate certificates in each environment (dev, staging, production)
- Keep the CA private key (`ca/ca.key`) especially secure
- For production, use certificates from a trusted Certificate Authority

## Certificate Validity

Certificates are generated with a 10-year validity period by default. Adjust the `CERT_VALIDITY` variable in the scripts if needed.

## Services Using Certificates

- **API Gateway** - Routes requests with mTLS to backend services
- **Load Balancer** - HTTPS endpoint for frontends
- **User Service** - HTTPS with mTLS
- **Chat Service** - HTTPS with mTLS
- **Auth Service** - HTTPS with mTLS
- **Comments Service** - Certificate verification
- **Canvas Service** - Certificate verification
