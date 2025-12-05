# OwlBoard AI Coding Agent Instructions

## Architecture Overview

OwlBoard is a **microservices-based collaborative whiteboard platform** with strict **network segmentation** and **zero-trust security**. The system uses **dual-network architecture** for defense-in-depth.

### Network Topology (Critical)
- **Public Network** (`owlboard-public-network`): Only proxy services for external access
- **Private Network** (`owlboard-private-network`): All frontends, backend services, databases, message broker
  - `internal: true` prevents external routing - DO NOT expose database ports
  - All services communicate via internal Docker DNS (e.g., `mysql_db:3306`, not `localhost:3306`)

### Service Communication Pattern
```
Browser → Desktop Proxy (8000) → Next.js Frontend → Load Balancer → API Gateways (4 replicas) → Backend Services → Databases
Browser → Mobile Proxy (3001) → Flutter Frontend → Load Balancer → API Gateways (4 replicas) → Backend Services → Databases
```
- Desktop: External users → desktop_proxy:8000 → nextjs_frontend (private network) → load_balancer → 4 API Gateway replicas
- Mobile: External users → mobile_proxy:3001 → mobile_frontend (private network) → load_balancer → 4 API Gateway replicas
- Load balancer uses `least_conn` algorithm with automatic health checks and failover
- API Gateways (4 replicas) are NOT exposed externally - accessed only through load balancer
- Frontends are isolated on private network - accessed only through their respective proxies
- Backend services are isolated on private network (no port mappings in docker-compose.yml)

## Core Components

### Frontends
- **Desktop_Front_End**: Next.js 14+ (TypeScript, React Bootstrap)
  - Client-side URLs: `NEXT_PUBLIC_*` env vars point to `localhost:8000`
  - Server-side URLs: Use internal Docker network (`http://api_gateway/api`)
- **Mobile_Front_End**: Flutter (Dart, Provider state management)
  - Uses `http://reverse_proxy/api` for internal calls
  - External URLs: `localhost:9000/api` for devices outside Docker

### Backend Services
- **User_Service**: FastAPI (Python), MySQL, HTTPS with mTLS on port 8443
- **Canvas_Service**: Gin (Go), PostgreSQL, RabbitMQ consumer for async canvas creation
- **Chat_Service**: FastAPI (Python), Redis, WebSocket support, HTTPS with mTLS on port 8443
- **Comments_Service**: FastAPI (Python), MongoDB, WebSocket + GraphQL endpoint
- **Load Balancer**: Nginx with least-connections algorithm distributing traffic across 4 API Gateway replicas
- **API Gateways (4 replicas)**: Nginx instances handling routing, CORS, and mTLS connections to backend services

### Security (DO NOT BREAK)
- **TLS/mTLS**: User and Chat services use HTTPS with mutual TLS authentication
  - Certificates in `Secure_Channel/certs/{service}/` mounted as read-only volumes
  - API Gateway requires client certs (`client.crt`, `client.key`) for mTLS upstream connections
  - Generate certs: `cd Secure_Channel && ./generate_certs.sh && ./generate_client_certs.sh`
- **CORS**: Handled CENTRALLY by API Gateway nginx config - NEVER enable CORS in individual services
  - Backend services have CORS middleware commented out (see User_Service/app.py, Canvas_Service/main.go)

## Developer Workflows

### Initial Setup
```bash
./setup.sh                    # Full automated setup (certs + build + start)
make setup                    # Same as above
make certificates             # Regenerate SSL certs only
```

### Daily Development
```bash
make start                    # Start all services (detached)
make logs-service SERVICE=user_service   # Tail specific service logs
make restart-service SERVICE=chat_service  # Restart after code changes
make stop-clean               # Stop and remove volumes (reset databases)
```

### Testing
- **Python services**: Use pytest with SQLite test database (see `User_Service/tests/test_users.py`)
  - Test client overrides `get_db` dependency with `TestingSessionLocal`
- **Access APIs**:
  - User Service docs: `http://localhost:8000/api/users` (through gateway)
  - Health checks: `http://localhost:9000/health` (reverse proxy)

### Service Structure Pattern
All Python services follow this structure:
```
{Service_Name}/
├── app.py                 # FastAPI app entry point, includes routers
├── requirements.txt       # Dependencies
├── Dockerfile            # Multi-stage build with non-root user
├── src/
│   ├── config.py         # Environment variables (DATABASE_URL, etc.)
│   ├── database.py       # DB connection, session management
│   ├── models.py         # SQLAlchemy/Pydantic models
│   ├── routes/           # Route handlers
│   └── logger_config.py  # Logging setup
└── tests/
```

## Key Conventions

### Environment Variables
- **Build-time** (Docker ARG): Frontend URLs in Dockerfile
- **Runtime** (docker-compose.yml): Backend service URLs, database connections
- ALWAYS use service names for inter-service URLs: `mysql_db:3306`, NOT `localhost:3306`

### Database Initialization
- Init SQL scripts in `{Service}/database/init.sql` mounted to `/docker-entrypoint-initdb.d/`
- Services depend on DB healthchecks: `depends_on: mysql_db: condition: service_healthy`

### WebSocket Implementation
- Chat and Comments services use WebSocket managers (see `Chat_Service/src/websocket_manager.py`)
- Pattern: `ConnectionManager` class with `active_connections` dict keyed by dashboard_id
- Redis stores connected users with TTL for cleanup

### Async Messaging (RabbitMQ)
- Canvas creation is asynchronous: Canvas_Service consumes messages from RabbitMQ queue
- Pattern in `Canvas_Service/messaging/consumer.go`: connects to RabbitMQ, consumes from queue, processes in goroutine

### Load Balancing
- Load balancer distributes traffic across 4 API Gateway replicas using `least_conn` algorithm
- Configuration in `load_balancer_nginx.conf` with health checks (`max_fails=3 fail_timeout=30s`)
- Automatic failover: if one gateway fails, traffic routes to remaining healthy instances
- Connection pooling: `keepalive 64` connections maintained to gateways for performance
- Retry logic: `proxy_next_upstream` retries failed requests on different gateway replica

## Common Pitfalls

1. **Do NOT expose database ports** in docker-compose.yml - they must remain isolated
2. **Do NOT add CORS middleware** to backend services - it's handled by API Gateway
3. **Do NOT use `localhost` in backend** - use Docker service names (`user_service`, `mysql_db`)
4. **Do NOT break mTLS** - User/Chat services require `proxy_ssl_certificate` in nginx config
5. When adding new services, mount certs from `Secure_Channel/` and add to **owlboard-private-network**

## Quick Reference

- **Check all services**: `docker compose ps` or `make status`
- **View all 17 container statuses**: All should show "Up" with healthy checks passing (4 API Gateways + 1 Load Balancer + 12 others)
- **Monitor load balancer**: `curl http://localhost:8000/lb-status` or `curl http://localhost:9000/lb-status`
- **Rebuild everything**: `make build-no-cache`
- **Reset environment**: `make stop-clean && make setup`
- **Docs**: `ARCHITECTURE_SECURITY_REPORT.md` (comprehensive security assessment), `DEPLOYMENT.md` (production guide)
