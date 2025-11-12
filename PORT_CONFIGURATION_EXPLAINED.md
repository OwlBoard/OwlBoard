# Port Configuration Explained - OwlBoard Architecture

This document explains the rationale behind every port choice in the OwlBoard system.

---

## 📌 Summary Table

| Service/Component | Internal Port | External Port | Protocol | Reason |
|-------------------|---------------|---------------|----------|--------|
| **Frontends** |
| Desktop Frontend (Next.js) | 3000 | 3002 | HTTP | Next.js default is 3000; external 3002 to avoid conflicts |
| Mobile Frontend (Flutter) | 80 | 3001 | HTTP | Nginx serves static files on 80; external 3001 for easy access |
| **Gateways** |
| Load Balancer | 80, 9000 | 8000, 9000 | HTTP | Standard HTTP (80); 9000 for mobile routing |
| API Gateway 1-4 | 80 | NONE | HTTP | Standard HTTP; private network only |
| **Backend Services** |
| User Service | 8443 | NONE | HTTPS | 8443 = standard HTTPS alt; mTLS required |
| Canvas Service | 8080 | NONE | HTTP | 8080 = common alt HTTP; Go Gin default |
| Chat Service | 8443 | NONE | HTTPS | 8443 = standard HTTPS alt; mTLS required |
| Comments Service | 8000 | NONE | HTTP | 8000 = common HTTP alt; FastAPI default |
| **Databases** |
| MySQL | 3306 | NONE | MySQL | 3306 = MySQL default port |
| PostgreSQL | 5432 | NONE | PostgreSQL | 5432 = PostgreSQL default port |
| Redis | 6379 | NONE | Redis | 6379 = Redis default port |
| MongoDB | 27017 | NONE | MongoDB | 27017 = MongoDB default port |
| **Message Broker** |
| RabbitMQ | 5672 | NONE | AMQP | 5672 = RabbitMQ default AMQP port |

---

## 🌐 Frontend Ports (Externally Accessible)

### Desktop Frontend: **3002** (external) → **3000** (internal)
```yaml
nextjs_frontend:
  ports:
    - "3002:3000"
```

**Why 3002 externally?**
- ✅ **Avoid conflicts**: Port 3000 is extremely common (React, Next.js, Node.js dev servers)
- ✅ **User convenience**: Easy to remember - 3001 = mobile, 3002 = desktop
- ✅ **Development friendly**: Developers often have other services on 3000

**Why 3000 internally?**
- ✅ **Next.js default**: Next.js applications run on port 3000 by default
- ✅ **No need to override**: Using default means no configuration changes in Next.js

---

### Mobile Frontend: **3001** (external) → **80** (internal)
```yaml
mobile_frontend:
  ports:
    - "3001:80"
```

**Why 3001 externally?**
- ✅ **User convenience**: Sequential numbering (3001, 3002)
- ✅ **Memorable**: Lower number often implies "first" or "mobile"
- ✅ **Avoid standard ports**: 80 is privileged; 3001 is user-space

**Why 80 internally?**
- ✅ **Nginx default**: Flutter app is served via Nginx, which defaults to port 80
- ✅ **Standard HTTP**: No need to configure non-standard port in Nginx

---

## 🔀 Load Balancer & Gateway Ports

### Load Balancer: **8000 & 9000** (external) → **80 & 9000** (internal)
```yaml
load_balancer:
  ports:
    - "8000:80"    # Desktop traffic
    - "9000:9000"  # Mobile traffic
```

**Why 8000 externally (Desktop traffic)?**
- ✅ **Common API port**: 8000 is widely used for APIs (Django, FastAPI, etc.)
- ✅ **Easy to remember**: Round number, developer-friendly
- ✅ **Avoids conflicts**: Less likely to conflict than 8080
- ✅ **Historical**: Previous single API Gateway used 8000

**Why 9000 externally (Mobile traffic)?**
- ✅ **Separation**: Different port clearly distinguishes mobile traffic
- ✅ **Flexibility**: Allows different rate limits, caching, monitoring
- ✅ **Historical**: Previous reverse proxy used 9000

**Why 80 & 9000 internally?**
- ✅ **Standard HTTP**: 80 is the universal HTTP port
- ✅ **Consistency**: 9000 maps 1:1 for mobile (easier to trace)

---

### API Gateways 1-4: **80** (internal only, NO external port)
```yaml
api_gateway_1:
  # NO ports mapping - private network only!
  networks:
    - owlboard-private-network
```

**Why 80 internally?**
- ✅ **Standard HTTP**: Universal default for web services
- ✅ **Nginx default**: API Gateway is Nginx, which defaults to port 80
- ✅ **No conflicts**: Each container has isolated network namespace

**Why NO external port?**
- ✅ **Security**: Prevents direct access bypassing load balancer
- ✅ **Enforces pattern**: All traffic MUST go through load balancer
- ✅ **Zero-trust**: Private network with `internal: true`

---

## 🔧 Backend Service Ports (Internal Only)

### User Service: **8443** (HTTPS with mTLS)
```yaml
user_service:
  # NO external port
  # Listens on 8443 internally
```

**Why 8443?**
- ✅ **HTTPS alternative**: 8443 is the standard alternative HTTPS port
- ✅ **Distinguishes from HTTP**: Clearly indicates secure traffic
- ✅ **mTLS enabled**: Requires client certificates (mutual TLS)
- ✅ **Not 443**: 443 is privileged; 8443 is unprivileged (no root needed)

**Security consideration:**
- 🔒 Only API Gateway can connect (has client certificates)
- 🔒 Traffic is encrypted with TLS
- 🔒 Mutual authentication prevents unauthorized access

---

### Canvas Service: **8080** (HTTP)
```yaml
canvas_service:
  # NO external port
  # Listens on 8080 internally
```

**Why 8080?**
- ✅ **Common HTTP alternative**: 8080 is the most popular HTTP alternative port
- ✅ **Go Gin default**: Gin framework commonly uses 8080
- ✅ **Easy to remember**: "80-80" = HTTP variant
- ✅ **Avoids conflicts**: Different from other services

**Why not HTTPS?**
- ✅ **Internal traffic**: Communication is within Docker private network
- ✅ **Performance**: Encryption overhead not needed for internal calls
- ✅ **Simplicity**: Fewer certificates to manage

---

### Chat Service: **8443** (HTTPS with mTLS)
```yaml
chat_service:
  # NO external port
  # Listens on 8443 internally
```

**Why 8443 (same as User Service)?**
- ✅ **HTTPS required**: Chat handles sensitive real-time communication
- ✅ **mTLS enabled**: Mutual authentication required
- ✅ **WebSocket security**: Secure WebSocket (wss://) over HTTPS
- ✅ **Consistent pattern**: Same as User Service for consistency

**No port conflict:**
- Each container has isolated network namespace
- Both User and Chat can use 8443 without conflict

---

### Comments Service: **8000** (HTTP)
```yaml
comments_service:
  # NO external port
  # Listens on 8000 internally
```

**Why 8000?**
- ✅ **FastAPI default**: FastAPI/Uvicorn commonly uses 8000
- ✅ **Common API port**: Widely recognized as API port
- ✅ **Distinguishes from Canvas**: Different port shows different service

**Why not HTTPS?**
- ✅ **Internal traffic**: Within private Docker network
- ✅ **GraphQL + WebSocket**: Performance over internal network is adequate
- ✅ **MongoDB connection**: Internal to private network

---

## 🗄️ Database Ports (Internal Only, NEVER Exposed)

### MySQL: **3306**
```yaml
mysql_db:
  # NO external port mapping!
  # Port 3306 only accessible on private network
```

**Why 3306?**
- ✅ **MySQL standard**: 3306 is the universal MySQL port
- ✅ **Client compatibility**: All MySQL clients expect 3306
- ✅ **No reason to change**: Standard port works perfectly internally

**Why NEVER expose?**
- 🔒 **Security**: Direct database access is a major security risk
- 🔒 **Network isolation**: `internal: true` on private network
- 🔒 **Attack surface**: Exposed databases are common attack targets

---

### PostgreSQL: **5432**
```yaml
postgres_db:
  # NO external port mapping!
```

**Why 5432?**
- ✅ **PostgreSQL standard**: 5432 is the universal PostgreSQL port
- ✅ **Canvas Service expects it**: Go application uses default port
- ✅ **Convention**: All PostgreSQL tools expect 5432

---

### Redis: **6379**
```yaml
redis_db:
  # NO external port mapping!
```

**Why 6379?**
- ✅ **Redis standard**: 6379 is the universal Redis port
- ✅ **Client libraries**: All Redis clients default to 6379
- ✅ **Funny origin**: Spells "MERZ" on phone keypad (founder's name)

**Use case:**
- Chat Service uses Redis for WebSocket connection management
- User status tracking with TTL (time-to-live)

---

### MongoDB: **27017**
```yaml
mongo_db:
  # NO external port mapping!
```

**Why 27017?**
- ✅ **MongoDB standard**: 27017 is the universal MongoDB port
- ✅ **Driver compatibility**: All MongoDB drivers expect 27017
- ✅ **Comments Service**: Connects via standard port

---

## 📨 Message Broker Port

### RabbitMQ: **5672** (AMQP)
```yaml
rabbitmq:
  # NO external port mapping!
  # Port 5672 for AMQP protocol
```

**Why 5672?**
- ✅ **AMQP standard**: 5672 is the standard AMQP protocol port
- ✅ **RabbitMQ default**: All RabbitMQ clients expect 5672
- ✅ **Canvas async processing**: Used for canvas creation queue

**Note:** RabbitMQ also has management UI on 15672 (not exposed)

---

## 🔐 Security Principles Behind Port Choices

### 1. **Public vs Private Separation**
```
EXPOSED (Public Network):
  - 3001 (Mobile Frontend)
  - 3002 (Desktop Frontend)
  - 8000 (Load Balancer - Desktop API)
  - 9000 (Load Balancer - Mobile API)

NOT EXPOSED (Private Network):
  - All backend services
  - All databases
  - All API Gateways
  - Message broker
```

### 2. **Zero External Database Access**
- ❌ MySQL port 3306 NOT exposed
- ❌ PostgreSQL port 5432 NOT exposed
- ❌ Redis port 6379 NOT exposed
- ❌ MongoDB port 27017 NOT exposed

**Why?** Direct database access is the #1 security vulnerability in web applications.

### 3. **Enforce Load Balancing**
- ❌ API Gateways NOT exposed directly
- ✅ All traffic MUST go through Load Balancer
- ✅ Monitoring, rate limiting, and failover at single point

### 4. **Standard Ports Internally**
Using standard ports internally means:
- ✅ No configuration changes needed in applications
- ✅ Works with default client libraries
- ✅ Easier for developers to understand
- ✅ Less chance of misconfiguration

---

## 🎯 Port Conflict Resolution

### Question: "Why can multiple services use the same internal port?"

**Answer:** Docker container network isolation

Each container has its own network namespace:
```
api_gateway_1:80  → IP: 172.20.0.5:80
api_gateway_2:80  → IP: 172.20.0.6:80
user_service:8443 → IP: 172.20.0.10:8443
chat_service:8443 → IP: 172.20.0.11:8443
```

They're on different IPs, so no conflict!

---

## 📊 Port Allocation Strategy

### User-Facing Ports (3000-3999)
- **3001**: Mobile Frontend (sequential, easy to remember)
- **3002**: Desktop Frontend (sequential, easy to remember)

### API/Gateway Ports (8000-8999)
- **8000**: Load Balancer Desktop traffic (common API port)
- **8080**: Canvas Service internal (common HTTP alt)
- **8443**: User & Chat Services internal (HTTPS alt)

### Special Ports (9000+)
- **9000**: Load Balancer Mobile traffic (routing separation)

### Database Ports (Standard)
- **3306**: MySQL (never change, universal standard)
- **5432**: PostgreSQL (never change, universal standard)
- **5672**: RabbitMQ AMQP (never change, protocol standard)
- **6379**: Redis (never change, universal standard)
- **27017**: MongoDB (never change, universal standard)

---

## 🚀 Best Practices Demonstrated

1. ✅ **Use standard ports internally** - No configuration needed
2. ✅ **Use user-space ports externally** (>1024) - No root required
3. ✅ **Never expose databases** - Major security principle
4. ✅ **Isolate services on private network** - Defense in depth
5. ✅ **Map external ports to avoid conflicts** - User convenience
6. ✅ **Document port choices** - Team understanding

---

## 🔍 Quick Reference

```bash
# Access URLs (from host machine)
Desktop Frontend:    http://localhost:3002
Mobile Frontend:     http://localhost:3001
Desktop API:         http://localhost:8000/api
Mobile API:          http://localhost:9000/api

# Internal URLs (from within Docker)
API Gateway 1:       http://api_gateway_1:80
User Service:        https://user_service:8443
Canvas Service:      http://canvas_service:8080
Chat Service:        https://chat_service:8443
Comments Service:    http://comments_service:8000
MySQL:               mysql://mysql_db:3306
PostgreSQL:          postgresql://postgres_db:5432
Redis:               redis://redis_db:6379
MongoDB:             mongodb://mongo_db:27017
RabbitMQ:            amqp://rabbitmq:5672
```

---

## Summary

The port configuration in OwlBoard follows these principles:

1. **Standards compliance** - Use default ports internally for each technology
2. **Security first** - Never expose databases or backend services
3. **User convenience** - External ports are memorable and avoid conflicts
4. **Network isolation** - Private network prevents external access to sensitive services
5. **Load balancing enforcement** - API Gateways only accessible through load balancer
6. **Container isolation** - Multiple services can use same internal port without conflict

This design provides maximum security while maintaining ease of development and deployment.
