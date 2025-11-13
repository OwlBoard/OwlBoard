# Arquitectura del Sistema de Autenticación Centralizado

## Diagrama de Alto Nivel

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                            CAPA DE PRESENTACIÓN                               │
│  ┌─────────────────────────────┐       ┌─────────────────────────────┐       │
│  │   Desktop Frontend          │       │   Mobile Frontend           │       │
│  │   (Next.js + React)         │       │   (Flutter)                 │       │
│  │   Port: 3002                │       │   Port: 3001                │       │
│  └──────────────┬──────────────┘       └──────────────┬──────────────┘       │
│                 │                                      │                       │
│                 │   HTTP/HTTPS Requests                │                       │
│                 │   with JWT tokens                    │                       │
└─────────────────┼──────────────────────────────────────┼───────────────────────┘
                  │                                      │
                  ▼                                      ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                       LOAD BALANCER (Nginx)                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │  • Port 8000 (Desktop)  → Round-robin to API Gateways                   │  │
│  │  • Port 9000 (Mobile)   → Round-robin to API Gateways                   │  │
│  │  • Health checks: max_fails=3, fail_timeout=30s                         │  │
│  │  • Algorithm: least_conn                                                │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────┘
                  │
                  ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                    API GATEWAY LAYER (4 Replicas)                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ API Gateway  │  │ API Gateway  │  │ API Gateway  │  │ API Gateway  │     │
│  │   Replica 1  │  │   Replica 2  │  │   Replica 3  │  │   Replica 4  │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                  │                  │              │
│         │  Routes:        │                  │                  │              │
│         │  /auth/*    → Auth_Service         │                  │              │
│         │  /users/*   → User_Service         │                  │              │
│         │  /canvas/*  → Canvas_Service       │                  │              │
│         │  /chat/*    → Chat_Service         │                  │              │
│         │  /comments/*→ Comments_Service     │                  │              │
│         │                                                                       │
└─────────┼───────────────────────────────────────────────────────┼──────────────┘
          │                                                       │
          │                     Private Network                  │
          │                  (owlboard-private-network)          │
          │                                                       │
┌─────────┼───────────────────────────────────────────────────────┼──────────────┐
│         ▼                                                       ▼              │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                        ╔═══════════════════════╗                         │  │
│  │                        ║   AUTH_SERVICE        ║                         │  │
│  │                        ║   (Port 8443)         ║                         │  │
│  │                        ╠═══════════════════════╣                         │  │
│  │                        ║ Endpoints:            ║                         │  │
│  │                        ║ • POST /auth/login    ║◀─────────┐              │  │
│  │                        ║ • POST /auth/logout   ║          │              │  │
│  │                        ║ • POST /token/refresh ║          │              │  │
│  │ All services ────────▶ ║ • POST /token/validate║          │              │  │
│  │ call this for         ║ • POST /token/revoke  ║          │              │  │
│  │ token validation      ║ • POST /token/introspect          │              │  │
│  │                        ╚═══════════╤═══════════╝          │              │  │
│  │                                    │                       │              │  │
│  └────────────────────────────────────┼───────────────────────┼──────────────┘  │
│                                       │                       │                 │
│  ┌───────────────┬───────────────────┼───────────────────┬───┼──────────────┐  │
│  │               │                   │                   │   │              │  │
│  ▼               ▼                   ▼                   ▼   ▼              │  │
│ ┌─────────┐  ┌─────────┐  ┌──────────────┐  ┌──────────┐ ┌────────┐       │  │
│ │  User   │  │  Chat   │  │   Canvas     │  │ Comments │ │ Other  │       │  │
│ │ Service │  │ Service │  │   Service    │  │ Service  │ │Services│       │  │
│ │         │  │         │  │              │  │          │ │        │       │  │
│ │ Python  │  │ Python  │  │   Go/Gin     │  │ Python   │ │ ...    │       │  │
│ │ FastAPI │  │ FastAPI │  │              │  │ FastAPI  │ │        │       │  │
│ └────┬────┘  └────┬────┘  └──────┬───────┘  └────┬─────┘ └────┬───┘       │  │
│      │            │               │                │            │            │  │
│      │  JWT       │  JWT          │  JWT           │  JWT       │            │  │
│      │ Middleware │ Middleware    │ Middleware     │ Middleware │            │  │
│      │            │               │                │            │            │  │
└──────┼────────────┼───────────────┼────────────────┼────────────┼────────────┘
       │            │               │                │            │
       ▼            ▼               ▼                ▼            ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                         CAPA DE DATOS (Private Network)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │    MySQL     │  │  PostgreSQL  │  │   MongoDB    │  │    Redis     │     │
│  │              │  │              │  │              │  │              │     │
│  │ User Data    │  │ Canvas Data  │  │ Comments     │  │ DB 0: Chat   │     │
│  │              │  │              │  │              │  │ DB 1: Auth   │     │
│  │ Port: 3306   │  │ Port: 5432   │  │ Port: 27017  │  │ Port: 6379   │     │
│  │ (Internal)   │  │ (Internal)   │  │ (Internal)   │  │ (Internal)   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                                               │
│  ┌──────────────┐                                                            │
│  │  RabbitMQ    │                                                            │
│  │              │                                                            │
│  │ Message      │                                                            │
│  │ Broker       │                                                            │
│  │ Port: 5672   │                                                            │
│  │ (Internal)   │                                                            │
│  └──────────────┘                                                            │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## Flujo de Autenticación Detallado

### 1. Login Flow

```
┌────────┐                                                      ┌──────────────┐
│ Client │                                                      │ Auth_Service │
└───┬────┘                                                      └──────┬───────┘
    │                                                                  │
    │  POST /auth/login                                               │
    │  {email, password}                                              │
    ├────────────────────────────────────────────────────────────────▶│
    │                                                                  │
    │                                              ┌──────────────┐   │
    │                                              │ 1. Check     │   │
    │                                              │    Rate      │   │
    │                                              │    Limit     │   │
    │                                              │    (Redis)   │   │
    │                                              └──────┬───────┘   │
    │                                                     │            │
    │                                              ┌──────▼───────┐   │
    │                                              │ 2. Query     │   │
    │                                              │    User      │   │
    │                                              │    (MySQL)   │   │
    │                                              └──────┬───────┘   │
    │                                                     │            │
    │                                              ┌──────▼───────┐   │
    │                                              │ 3. Verify    │   │
    │                                              │    Password  │   │
    │                                              │    (Bcrypt)  │   │
    │                                              └──────┬───────┘   │
    │                                                     │            │
    │                                              ┌──────▼───────┐   │
    │                                              │ 4. Generate  │   │
    │                                              │    JWT       │   │
    │                                              │    Tokens    │   │
    │                                              └──────┬───────┘   │
    │                                                     │            │
    │                                              ┌──────▼───────┐   │
    │                                              │ 5. Store     │   │
    │                                              │    Refresh   │   │
    │                                              │    Token     │   │
    │                                              │    (Redis)   │   │
    │                                              └──────┬───────┘   │
    │                                                     │            │
    │  {access_token, refresh_token, expires_in}         │            │
    │◀────────────────────────────────────────────────────┴────────────┤
    │                                                                  │
    │  Store tokens in localStorage/cookies                           │
    │                                                                  │
```

### 2. Protected Resource Access Flow

```
┌────────┐                    ┌────────────┐                    ┌──────────────┐
│ Client │                    │Microservice│                    │ Auth_Service │
└───┬────┘                    └─────┬──────┘                    └──────┬───────┘
    │                               │                                  │
    │  GET /users/profile           │                                  │
    │  Authorization: Bearer <JWT>  │                                  │
    ├──────────────────────────────▶│                                  │
    │                               │                                  │
    │                               │  POST /auth/token/validate       │
    │                               │  Authorization: Bearer <JWT>     │
    │                               ├─────────────────────────────────▶│
    │                               │                                  │
    │                               │              ┌─────────────┐     │
    │                               │              │ 1. Decode   │     │
    │                               │              │    JWT      │     │
    │                               │              └──────┬──────┘     │
    │                               │                     │            │
    │                               │              ┌──────▼──────┐     │
    │                               │              │ 2. Check    │     │
    │                               │              │    Blacklist│     │
    │                               │              │    (Redis)  │     │
    │                               │              └──────┬──────┘     │
    │                               │                     │            │
    │                               │              ┌──────▼──────┐     │
    │                               │              │ 3. Verify   │     │
    │                               │              │    Signature│     │
    │                               │              └──────┬──────┘     │
    │                               │                     │            │
    │                               │  {valid: true,      │            │
    │                               │   user_id: 123,     │            │
    │                               │   email: "...",     │            │
    │                               │   scopes: [...]}    │            │
    │                               │◀─────────────────────┴────────────┤
    │                               │                                  │
    │                               │  Process request with            │
    │                               │  authenticated user context      │
    │                               │                                  │
    │  {user_data}                  │                                  │
    │◀──────────────────────────────┤                                  │
    │                               │                                  │
```

### 3. Token Refresh Flow

```
┌────────┐                                                      ┌──────────────┐
│ Client │                                                      │ Auth_Service │
└───┬────┘                                                      └──────┬───────┘
    │                                                                  │
    │  Request to protected resource returns 401                      │
    │  (access_token expired)                                         │
    │                                                                  │
    │  POST /auth/token/refresh                                       │
    │  {refresh_token}                                                │
    ├────────────────────────────────────────────────────────────────▶│
    │                                                                  │
    │                                              ┌─────────────┐    │
    │                                              │ 1. Decode   │    │
    │                                              │    Refresh  │    │
    │                                              │    Token    │    │
    │                                              └──────┬──────┘    │
    │                                                     │            │
    │                                              ┌──────▼──────┐    │
    │                                              │ 2. Check    │    │
    │                                              │    Blacklist│    │
    │                                              │    (Redis)  │    │
    │                                              └──────┬──────┘    │
    │                                                     │            │
    │                                              ┌──────▼──────┐    │
    │                                              │ 3. Verify   │    │
    │                                              │    in Redis │    │
    │                                              │    Storage  │    │
    │                                              └──────┬──────┘    │
    │                                                     │            │
    │                                              ┌──────▼──────┐    │
    │                                              │ 4. Generate │    │
    │                                              │    New      │    │
    │                                              │    Access   │    │
    │                                              │    Token    │    │
    │                                              └──────┬──────┘    │
    │                                                     │            │
    │  {access_token, refresh_token, expires_in}         │            │
    │◀────────────────────────────────────────────────────┴────────────┤
    │                                                                  │
    │  Update stored access_token                                     │
    │  Retry original request                                         │
    │                                                                  │
```

### 4. Logout Flow

```
┌────────┐                                                      ┌──────────────┐
│ Client │                                                      │ Auth_Service │
└───┬────┘                                                      └──────┬───────┘
    │                                                                  │
    │  POST /auth/logout                                              │
    │  {access_token, refresh_token}                                  │
    ├────────────────────────────────────────────────────────────────▶│
    │                                                                  │
    │                                              ┌─────────────┐    │
    │                                              │ 1. Extract  │    │
    │                                              │    JTI from │    │
    │                                              │    Tokens   │    │
    │                                              └──────┬──────┘    │
    │                                                     │            │
    │                                              ┌──────▼──────┐    │
    │                                              │ 2. Add to   │    │
    │                                              │    Blacklist│    │
    │                                              │    (Redis)  │    │
    │                                              │    with TTL │    │
    │                                              └──────┬──────┘    │
    │                                                     │            │
    │                                              ┌──────▼──────┐    │
    │                                              │ 3. Delete   │    │
    │                                              │    Refresh  │    │
    │                                              │    from     │    │
    │                                              │    Storage  │    │
    │                                              └──────┬──────┘    │
    │                                                     │            │
    │  {message: "Logged out successfully"}              │            │
    │◀────────────────────────────────────────────────────┴────────────┤
    │                                                                  │
    │  Clear tokens from localStorage                                 │
    │  Redirect to login page                                         │
    │                                                                  │
```

---

## Componentes de Seguridad

```
┌───────────────────────────────────────────────────────────────────────┐
│                       SECURITY LAYERS                                 │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Layer 1: Network Segmentation                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ • Public Network (owlboard-public-network)                  │    │
│  │   - Frontends, Load Balancer                                │    │
│  │                                                              │    │
│  │ • Private Network (owlboard-private-network)                │    │
│  │   - API Gateways, Auth Service, Microservices, Databases    │    │
│  │   - NO external port mappings                               │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  Layer 2: TLS/mTLS Encryption                                        │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ • Client ↔ Load Balancer: HTTPS                             │    │
│  │ • Load Balancer ↔ API Gateway: HTTPS                        │    │
│  │ • API Gateway ↔ Auth Service: HTTPS + mTLS                  │    │
│  │ • API Gateway ↔ Other Services: HTTPS + mTLS                │    │
│  │ • Microservices ↔ Auth Service: HTTPS + mTLS                │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  Layer 3: Authentication & Authorization                             │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ Auth_Service:                                                │    │
│  │ • JWT tokens (HS256, 256-bit secret)                        │    │
│  │ • Access token: 30 minutes expiration                       │    │
│  │ • Refresh token: 7 days expiration                          │    │
│  │ • Bcrypt password hashing (12 rounds)                       │    │
│  │ • Rate limiting: 5 attempts / 15 minutes                    │    │
│  │ • Token blacklist in Redis                                  │    │
│  │                                                              │    │
│  │ Microservices:                                               │    │
│  │ • JWT middleware validates all protected endpoints          │    │
│  │ • Scope-based authorization (RBAC ready)                    │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  Layer 4: Data Protection                                            │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ • Databases on private network only                          │    │
│  │ • Redis segregated (DB 0: Chat, DB 1: Auth)                 │    │
│  │ • Password hashing with bcrypt                               │    │
│  │ • JWT tokens encrypted with secret key                       │    │
│  │ • Sensitive data never in logs                               │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  Layer 5: Monitoring & Audit                                         │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │ • All authentication events logged                           │    │
│  │ • Failed login attempts tracked                              │    │
│  │ • Token validation metrics                                   │    │
│  │ • Health checks on all services                              │    │
│  │ • Rate limiting triggers logged                              │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Redis Database Schema

```
Redis DB 0 (Chat Service):
  connected_users:{dashboard_id} → Set<user_id>
  last_seen:{user_id} → timestamp
  ...

Redis DB 1 (Auth Service):
  # Rate Limiting
  login:{email} → counter (TTL: 15 minutes)
  
  # Token Blacklist
  blacklist:{jti} → "revoked" (TTL: token expiration time)
  
  # Refresh Token Storage
  refresh_token:{jti} → user_id (TTL: 7 days)
  
  # Session Management (optional)
  session:{user_id} → {last_login, ip, user_agent} (TTL: 30 days)
```

---

## Métricas de Monitoreo Recomendadas

```
┌────────────────────────────────────────────────────────────┐
│               KEY PERFORMANCE INDICATORS                   │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Authentication Metrics:                                   │
│  • Login attempts/second                                   │
│  • Login success rate (target: >95%)                      │
│  • Login failure rate (alert if >5%)                      │
│  • Token validation latency (p50, p95, p99)               │
│  • Token validation errors (alert if >1%)                 │
│                                                            │
│  Security Metrics:                                         │
│  • Rate limit triggers (alert if >10/hour)                │
│  • Failed login attempts per user (alert if >3)           │
│  • Blacklisted tokens count (monitor growth)              │
│  • Token refresh rate                                      │
│  • Anomalous login patterns (ML-based)                    │
│                                                            │
│  Service Health:                                           │
│  • Auth_Service uptime (target: 99.9%)                    │
│  • Redis connection errors                                 │
│  • MySQL connection errors                                 │
│  • Request throughput (requests/sec)                       │
│  • Error rate (5xx responses)                              │
│                                                            │
│  Performance:                                              │
│  • Average response time (target: <100ms)                 │
│  • Token validation time (target: <50ms p95)              │
│  • Database query time                                     │
│  • Redis operation time                                    │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

*Este documento describe la arquitectura del sistema de autenticación centralizado implementado en OwlBoard v2.0.0*
