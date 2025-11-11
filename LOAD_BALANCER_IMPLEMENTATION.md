# Load Balancer Implementation Summary

## Overview

This document describes the load balancing implementation for OwlBoard, which distributes traffic across 4 API Gateway replicas for high availability, fault tolerance, and improved performance.

## Architecture

### Before (Single API Gateway)
```
Browser → Frontend → API Gateway (single instance) → Backend Services
```

### After (Load Balanced with 4 Replicas)
```
Browser → Frontend → Load Balancer → [API Gateway 1, 2, 3, 4] → Backend Services
```

## Components

### Load Balancer (`load_balancer`)
- **Technology**: Nginx
- **Configuration**: `load_balancer_nginx.conf`
- **Ports**: 
  - 8000 (Desktop frontend traffic)
  - 9000 (Mobile frontend traffic)
- **Algorithm**: `least_conn` (least connections for better distribution)
- **Health Checks**: Automatic detection of failed gateways (`max_fails=3`, `fail_timeout=30s`)

### API Gateway Replicas
- **Count**: 4 replicas (`api_gateway_1`, `api_gateway_2`, `api_gateway_3`, `api_gateway_4`)
- **Technology**: Nginx (from `owlboard-orchestrator`)
- **Network**: Private network only (NOT exposed to external traffic)
- **Configuration**: Each uses same config from `owlboard-orchestrator/nginx.conf`
- **Certificates**: All share same mTLS certificates from `Secure_Channel/certs/api_gateway/`

## Features

### 1. High Availability
- If one gateway fails, traffic automatically routes to healthy instances
- No downtime during individual gateway restarts
- Health checks every request with automatic failover

### 2. Load Distribution
- `least_conn` algorithm ensures even distribution based on active connections
- Better for long-lived WebSocket connections (chat, comments)
- Connection pooling (`keepalive 64`) reduces connection overhead

### 3. Fault Tolerance
- **Automatic Retry**: Failed requests retry on different gateway (`proxy_next_upstream`)
- **Max Retries**: Up to 2 attempts across different backends
- **Timeout**: 10s retry timeout prevents hanging requests

### 4. Performance Optimizations
- Connection pooling to gateways
- HTTP/1.1 keepalive connections
- Rate limiting at load balancer level
- Request buffering and caching support

## Configuration Details

### Upstream Definition (load_balancer_nginx.conf)
```nginx
upstream api_gateways {
    least_conn;  # Load balancing algorithm
    
    server api_gateway_1:80 max_fails=3 fail_timeout=30s;
    server api_gateway_2:80 max_fails=3 fail_timeout=30s;
    server api_gateway_3:80 max_fails=3 fail_timeout=30s;
    server api_gateway_4:80 max_fails=3 fail_timeout=30s;
    
    keepalive 64;              # Connection pool size
    keepalive_requests 100;    # Max requests per connection
    keepalive_timeout 60s;     # Connection timeout
}
```

### Health Check Parameters
- **max_fails**: 3 consecutive failures mark backend as down
- **fail_timeout**: 30s cooldown before retry
- **Monitoring endpoint**: `/health` and `/lb-status` for status checks

### Retry Configuration
```nginx
proxy_next_upstream error timeout http_502 http_503 http_504;
proxy_next_upstream_tries 2;
proxy_next_upstream_timeout 10s;
```

## Service Count

### Total Containers: 17
- **Load Balancer**: 1
- **API Gateways**: 4
- **Frontends**: 2 (Desktop + Mobile)
- **Backend Services**: 4 (User, Canvas, Chat, Comments)
- **Databases**: 4 (MySQL, PostgreSQL, MongoDB, Redis)
- **Message Broker**: 1 (RabbitMQ)
- **Security**: 1 (Certificate volumes)

## Deployment

### Starting the System
```bash
# Full setup with load balancer
./setup.sh

# Or using Makefile
make setup
make start
```

### Verifying Load Balancer
```bash
# Check load balancer health
curl http://localhost:8000/health
curl http://localhost:9000/health

# Check load balancer status
curl http://localhost:8000/lb-status
curl http://localhost:9000/lb-status

# View all containers (should show 17)
docker compose ps

# Monitor load balancer logs
docker compose logs -f load_balancer

# Monitor specific gateway
docker compose logs -f api_gateway_1
```

### Scaling Individual Gateways
```bash
# Restart a specific gateway (zero downtime - others handle traffic)
docker compose restart api_gateway_2

# View logs for troubleshooting
docker compose logs -f api_gateway_3

# Check gateway health
docker exec api_gateway_1 curl -s http://localhost/health
```

## Frontend Configuration

### Desktop Frontend (NextJS)
- **External URL**: `http://localhost:8000` → Load Balancer
- **Internal URL**: `http://load_balancer` → Direct Docker network access
- Traffic distributed across 4 API Gateways automatically

### Mobile Frontend (Flutter)
- **External URL**: `http://localhost:9000` → Load Balancer
- **Internal URL**: `http://load_balancer:9000` → Direct Docker network access
- Traffic distributed across 4 API Gateways automatically

## Monitoring

### Key Metrics to Monitor
1. **Load Balancer Status**: Response time, error rates
2. **Gateway Health**: Individual gateway availability
3. **Connection Distribution**: Verify even distribution across replicas
4. **Failover Events**: Check logs for backend failures

### Log Monitoring
```bash
# Load balancer access logs show which backend handled each request
docker compose logs load_balancer | grep upstream:

# Example output:
# upstream: api_gateway_1:80
# upstream: api_gateway_2:80
# upstream: api_gateway_1:80
```

## Security Considerations

### TLS/mTLS
- Load balancer → API Gateway communication is HTTP (internal Docker network)
- API Gateway → Backend Services uses HTTPS with mTLS (User, Chat services)
- All traffic encrypted at backend service level

### Network Segmentation
- Load balancer on both public and private networks (bridge)
- API Gateways on private network only (NOT exposed)
- Backend services on private network only (NOT exposed)
- Databases on private network with `internal: true` (complete isolation)

### CORS Handling
- CORS configured at API Gateway level (centralized)
- Load balancer passes through CORS headers from gateways
- NO duplicate CORS headers

## Troubleshooting

### Issue: Gateway Marked as Down
```bash
# Check gateway logs
docker compose logs api_gateway_2

# Restart failed gateway
docker compose restart api_gateway_2

# Verify health
docker exec api_gateway_2 curl -s http://localhost/health
```

### Issue: Uneven Load Distribution
- Check if any gateway has errors: `docker compose logs | grep error`
- Verify `least_conn` is configured in upstream
- Monitor connection counts: `docker stats`

### Issue: WebSocket Connections Failing
- Ensure `Upgrade` and `Connection` headers are passed through
- Check timeout settings: `proxy_read_timeout 60s`
- Verify all 4 gateways have same WebSocket config

## Performance Tuning

### Increasing Gateway Replicas
To add more gateways (e.g., scale to 8):

1. Add new service definitions in `docker-compose.yml`:
```yaml
api_gateway_5:
  # Same config as api_gateway_1
```

2. Update upstream in `load_balancer_nginx.conf`:
```nginx
upstream api_gateways {
    least_conn;
    server api_gateway_1:80 max_fails=3 fail_timeout=30s;
    server api_gateway_2:80 max_fails=3 fail_timeout=30s;
    server api_gateway_3:80 max_fails=3 fail_timeout=30s;
    server api_gateway_4:80 max_fails=3 fail_timeout=30s;
    server api_gateway_5:80 max_fails=3 fail_timeout=30s;
    # ... add more as needed
}
```

3. Rebuild and restart:
```bash
docker compose up -d --build
```

## Benefits

### Advantages of This Implementation
1. ✅ **High Availability**: No single point of failure
2. ✅ **Fault Tolerance**: Automatic failover on gateway failure
3. ✅ **Scalability**: Easy to add more gateway replicas
4. ✅ **Zero Downtime**: Rolling updates possible without service interruption
5. ✅ **Performance**: Connection pooling and load distribution
6. ✅ **Monitoring**: Centralized logging and health checks
7. ✅ **No Code Changes**: Existing services unchanged, only infrastructure

### Production Readiness
This implementation follows industry best practices for:
- Microservices architecture
- High availability patterns
- Zero-trust security model
- Defense-in-depth approach
- Horizontal scalability

## References

- Main Configuration: `load_balancer_nginx.conf`
- Docker Compose: `docker-compose.yml` (services: `load_balancer`, `api_gateway_1-4`)
- AI Instructions: `.github/copilot-instructions.md`
- Architecture: `ARCHITECTURE_SECURITY_REPORT.md`
