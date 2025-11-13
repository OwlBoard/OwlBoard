# Centralized Authentication Service - Implementation Guide

## 🎯 Objetivo

Este documento describe la implementación del **Servidor de Autenticación Centralizado** en OwlBoard, que mitiga las vulnerabilidades de autenticación descentralizada mediante:

- ✅ **Punto único de autenticación** - Todos los servicios validan tokens a través de Auth_Service
- ✅ **JWT tokens seguros** - HS256 con claves secretas robustas y expiración configurable
- ✅ **Bcrypt password hashing** - 12 rondas por defecto para seguridad de contraseñas
- ✅ **Token blacklisting** - Revocación inmediata de tokens comprometidos
- ✅ **Rate limiting** - Protección contra ataques de fuerza bruta
- ✅ **mTLS** - Comunicación cifrada y autenticada entre servicios

## 📋 Tabla de Contenidos

1. [Arquitectura](#arquitectura)
2. [Instalación y Despliegue](#instalación-y-despliegue)
3. [Configuración](#configuración)
4. [Integración con Servicios](#integración-con-servicios)
5. [Flujos de Autenticación](#flujos-de-autenticación)
6. [Endpoints de API](#endpoints-de-api)
7. [Pruebas](#pruebas)
8. [Troubleshooting](#troubleshooting)
9. [Mejoras Futuras](#mejoras-futuras)

---

## Arquitectura

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND LAYER                          │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │ Desktop Frontend │              │ Mobile Frontend  │         │
│  │   (Next.js)      │              │    (Flutter)     │         │
│  └────────┬─────────┘              └─────────┬────────┘         │
│           │                                   │                  │
│           │    POST /auth/login               │                  │
│           └───────────────┬───────────────────┘                  │
└───────────────────────────┼──────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      LOAD BALANCER LAYER                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Nginx Load Balancer (least_conn algorithm)             │   │
│  │  - Port 8000 (Desktop), Port 9000 (Mobile)              │   │
│  │  - Distributes to 4 API Gateway replicas                │   │
│  └────────────────────┬─────────────────────────────────────┘   │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API GATEWAY LAYER (4 replicas)               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Nginx API Gateways                                      │   │
│  │  - Routes /auth/* → Auth_Service                         │   │
│  │  - Routes /users/* → User_Service                        │   │
│  │  - CORS handling centralized                             │   │
│  └────────┬─────────────────────────────────────┬────────────┘  │
└───────────┼─────────────────────────────────────┼────────────────┘
            │                                     │
            ▼                                     ▼
┌───────────────────────────┐    ┌──────────────────────────────┐
│    AUTH_SERVICE           │    │  OTHER MICROSERVICES         │
│  ┌─────────────────────┐  │    │  - User_Service              │
│  │ FastAPI (Python)    │  │    │  - Canvas_Service (Go)       │
│  │ - Login             │  │    │  - Chat_Service              │
│  │ - Token Refresh     │  │    │  - Comments_Service          │
│  │ - Token Validation  │◀─┼────┤                              │
│  │ - Token Revocation  │  │    │  All services call           │
│  └──────┬──────────────┘  │    │  Auth_Service to validate    │
│         │                 │    │  tokens before processing    │
└─────────┼─────────────────┘    └──────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA STORAGE LAYER                         │
│  ┌──────────────┐     ┌──────────────┐                          │
│  │   MySQL      │     │    Redis     │                          │
│  │ (User data)  │     │ - Token      │                          │
│  │              │     │   blacklist  │                          │
│  │              │     │ - Sessions   │                          │
│  │              │     │ - Rate limit │                          │
│  └──────────────┘     └──────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

### Flujo de Datos de Autenticación

```
1. LOGIN FLOW:
   User → Frontend → Load Balancer → API Gateway → Auth_Service
                                                        ↓
                                              ┌─────────┴─────────┐
                                              │ 1. Check rate     │
                                              │    limit (Redis)  │
                                              │ 2. Query user     │
                                              │    (MySQL)        │
                                              │ 3. Verify pwd     │
                                              │ 4. Generate JWT   │
                                              │ 5. Store refresh  │
                                              │    token (Redis)  │
                                              └─────────┬─────────┘
                                                        ↓
   User ← Frontend ← Load Balancer ← API Gateway ← {access_token,
                                                     refresh_token}

2. PROTECTED RESOURCE ACCESS:
   User → Frontend → API Gateway → Microservice
                         ↓              ↓
                    (forwards      JWT Middleware
                     token)            ↓
                                  Auth_Service
                                  /token/validate
                                       ↓
                              ┌────────┴────────┐
                              │ 1. Decode JWT   │
                              │ 2. Check        │
                              │    blacklist    │
                              │ 3. Return user  │
                              │    info         │
                              └────────┬────────┘
                                       ↓
   User ← Frontend ← API Gateway ← {resource_data}
```

---

## Instalación y Despliegue

### Paso 1: Generar Certificados SSL

El Auth_Service requiere certificados mTLS para comunicación segura:

```bash
# En el directorio raíz de OwlBoard
cd Secure_Channel

# Generar certificados (incluye auth_service)
./generate_certs.sh

# Verificar certificados generados
ls -la certs/auth_service/
# Deberías ver: server.crt, server.key, server.csr, server.ext.cnf
```

### Paso 2: Configurar Variables de Entorno

Crea un archivo `.env` en el directorio raíz con una clave JWT segura:

```bash
# Generar clave JWT segura (64 bytes recomendados)
python -c "import secrets; print(secrets.token_urlsafe(64))"

# Añadir al .env
echo "JWT_SECRET_KEY=<tu_clave_generada_aqui>" >> .env
```

**⚠️ IMPORTANTE**: NUNCA commitees la clave JWT al repositorio. Usa secrets management en producción.

### Paso 3: Construir e Iniciar Servicios

```bash
# Opción 1: Setup automatizado (recomendado)
make setup

# Opción 2: Manual
docker-compose build auth_service
docker-compose up -d auth_service

# Verificar que Auth_Service está corriendo
docker-compose ps | grep auth_service
# Debe mostrar: auth_service   Up (healthy)

# Ver logs
docker-compose logs -f auth_service
```

### Paso 4: Verificar Funcionamiento

```bash
# Test health endpoint
curl -k http://localhost:8000/api/auth/health

# Respuesta esperada:
# {"status":"healthy","service":"auth-service","redis_connected":true}
```

---

## Configuración

### Variables de Entorno del Auth_Service

| Variable | Descripción | Valor Por Defecto | Requerido |
|----------|-------------|-------------------|-----------|
| `JWT_SECRET_KEY` | Clave secreta para firmar JWT (min 32 chars) | - | ✅ |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Tiempo de expiración del access token | 30 | ❌ |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Tiempo de expiración del refresh token | 7 | ❌ |
| `REDIS_HOST` | Hostname de Redis | redis_db | ❌ |
| `REDIS_PORT` | Puerto de Redis | 6379 | ❌ |
| `REDIS_DB` | Base de datos Redis (1 para auth) | 1 | ❌ |
| `REDIS_PASSWORD` | Contraseña de Redis | password | ❌ |
| `DATABASE_URL` | URL de MySQL (User_Service DB) | mysql+pymysql://... | ✅ |
| `MAX_LOGIN_ATTEMPTS` | Intentos máximos antes de bloqueo | 5 | ❌ |
| `LOCKOUT_DURATION_MINUTES` | Duración del bloqueo (minutos) | 15 | ❌ |
| `BCRYPT_ROUNDS` | Rondas de bcrypt para hashing | 12 | ❌ |

### Configuración de Microservicios

Cada microservicio necesita estas variables para conectarse al Auth_Service:

```yaml
# En docker-compose.yml (ya configurado)
environment:
  AUTH_SERVICE_URL: "https://auth_service:8443"
  CA_CERT_PATH: "/etc/ssl/certs/ca.crt"
```

---

## Integración con Servicios

### Python Services (FastAPI)

**1. Instalar dependencia**

Ya incluido en `requirements.txt`:
```
httpx  # Cliente HTTP para llamar a Auth_Service
```

**2. Importar middleware**

```python
# En tus routes (ej: User_Service/src/routes/users_routes.py)
from src.middleware.jwt_middleware import require_auth, optional_auth, require_scopes

# Ejemplo: Ruta protegida
@router.get("/profile")
async def get_profile(current_user: dict = Depends(require_auth)):
    """
    Endpoint protegido que requiere autenticación
    current_user contiene: {user_id, email, scopes, expires_at}
    """
    return {
        "user_id": current_user["user_id"],
        "email": current_user["email"]
    }

# Ejemplo: Ruta con autenticación opcional
@router.get("/public-info")
async def public_info(current_user: dict = Depends(optional_auth)):
    """
    Endpoint que funciona con o sin autenticación
    """
    if current_user:
        return {"message": f"Hello {current_user['email']}"}
    return {"message": "Hello anonymous user"}

# Ejemplo: Ruta que requiere scopes específicos
@router.delete("/admin/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: dict = Depends(require_scopes("admin", "write"))
):
    """
    Solo usuarios con scopes 'admin' y 'write' pueden acceder
    """
    return {"message": f"User {user_id} deleted"}
```

### Go Services (Gin)

**1. Copiar middleware**

```bash
cp Auth_Service/middleware_examples/canvas_service_auth.go Canvas_Service/middleware/auth.go
```

**2. Usar en rutas**

```go
// En Canvas_Service/main.go
import (
    "canvas_service/middleware"
)

func setupRoutes(router *gin.Engine) {
    // Rutas públicas (sin auth)
    router.GET("/health", healthCheck)
    
    // Rutas protegidas (requieren auth)
    protected := router.Group("/")
    protected.Use(middleware.AuthMiddleware())
    {
        protected.POST("/canvas", createCanvas)
        protected.GET("/canvas/:id", getCanvas)
        protected.PUT("/canvas/:id", updateCanvas)
        protected.DELETE("/canvas/:id", deleteCanvas)
    }
    
    // Rutas con scopes específicos
    admin := router.Group("/admin")
    admin.Use(middleware.AuthMiddleware())
    admin.Use(middleware.RequireScopes("admin"))
    {
        admin.DELETE("/canvas/:id/force", forceDeleteCanvas)
    }
}

// En los handlers, extraer user info
func createCanvas(c *gin.Context) {
    userID, email, ok := middleware.GetCurrentUser(c)
    if !ok {
        c.JSON(401, gin.H{"error": "Unauthorized"})
        return
    }
    
    // Usar userID y email...
}
```

---

## Flujos de Autenticación

### 1. Flujo de Login

```javascript
// Frontend (Next.js/React)
const handleLogin = async (email, password) => {
  try {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.detail);
    }
    
    const { access_token, refresh_token, expires_in } = await response.json();
    
    // Almacenar tokens (httpOnly cookies es más seguro)
    localStorage.setItem('access_token', access_token);
    localStorage.setItem('refresh_token', refresh_token);
    
    // Redirigir al dashboard
    router.push('/dashboard');
    
  } catch (error) {
    console.error('Login failed:', error);
    // Mostrar error al usuario
  }
};
```

### 2. Flujo de Refresh Token

```javascript
// Interceptor de axios/fetch para refrescar tokens automáticamente
const apiClient = axios.create({
  baseURL: '/api'
});

apiClient.interceptors.response.use(
  response => response,
  async error => {
    const originalRequest = error.config;
    
    // Si recibimos 401 y no hemos reintentado
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const refresh_token = localStorage.getItem('refresh_token');
        const response = await fetch('/api/auth/token/refresh', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ refresh_token })
        });
        
        if (response.ok) {
          const { access_token } = await response.json();
          localStorage.setItem('access_token', access_token);
          
          // Reintentar request original con nuevo token
          originalRequest.headers['Authorization'] = `Bearer ${access_token}`;
          return apiClient(originalRequest);
        }
      } catch (refreshError) {
        // Refresh falló, redirigir a login
        localStorage.clear();
        window.location.href = '/login';
      }
    }
    
    return Promise.reject(error);
  }
);
```

### 3. Flujo de Logout

```javascript
const handleLogout = async () => {
  const access_token = localStorage.getItem('access_token');
  const refresh_token = localStorage.getItem('refresh_token');
  
  try {
    // Revocar tokens en el servidor
    await fetch('/api/auth/logout', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ access_token, refresh_token })
    });
  } catch (error) {
    console.error('Logout request failed:', error);
  } finally {
    // Limpiar tokens locales siempre
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    window.location.href = '/login';
  }
};
```

---

## Endpoints de API

### POST /auth/login

Autentica al usuario y retorna tokens JWT.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

**Error 401:**
```json
{
  "detail": "Invalid email or password"
}
```

**Error 429 (Rate Limited):**
```json
{
  "detail": "Too many login attempts. Try again in 900 seconds."
}
```

### POST /auth/token/refresh

Refresca el access token usando refresh token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 1800
}
```

### POST /auth/token/validate

Valida un token (usado por microservicios).

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

**Response 200:**
```json
{
  "valid": true,
  "user_id": 123,
  "email": "user@example.com",
  "scopes": ["read", "write"],
  "expires_at": "2025-11-12T14:30:00Z",
  "message": "Token is valid"
}
```

### POST /auth/token/revoke

Revoca un token (añade a blacklist).

**Request:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "access"
}
```

**Response 200:**
```json
{
  "message": "Token revoked successfully"
}
```

### POST /auth/logout

Cierra sesión revocando ambos tokens.

**Request:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response 200:**
```json
{
  "message": "Logged out successfully"
}
```

---

## Pruebas

### Tests Unitarios

```bash
cd Auth_Service

# Instalar dependencias de test
pip install pytest pytest-asyncio httpx

# Ejecutar tests
pytest tests/ -v

# Con coverage
pytest tests/ -v --cov=src --cov-report=html
```

### Tests de Integración

```bash
# Test de login completo
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Guardar access_token de la respuesta
ACCESS_TOKEN="<token_aqui>"

# Test de validación
curl -X POST http://localhost:8000/api/auth/token/validate \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# Test de endpoint protegido
curl -X GET http://localhost:8000/api/users/profile \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### Load Testing

```bash
# Instalar Apache Bench
sudo apt-get install apache2-utils

# Test de login (100 requests, 10 concurrentes)
ab -n 100 -c 10 -p login.json -T application/json \
  http://localhost:8000/api/auth/login
```

---

## Troubleshooting

### Problema: "Token validation failed"

**Síntomas**: Los microservicios no pueden validar tokens.

**Soluciones**:
1. Verificar que Auth_Service está corriendo:
   ```bash
   docker-compose ps auth_service
   ```

2. Verificar conectividad de red:
   ```bash
   docker exec user_service ping auth_service
   ```

3. Verificar certificados mTLS:
   ```bash
   docker exec user_service ls -la /etc/ssl/certs/ca.crt
   ```

4. Ver logs de Auth_Service:
   ```bash
   docker-compose logs auth_service | tail -50
   ```

### Problema: "Redis connection error"

**Síntomas**: Auth_Service no puede conectarse a Redis.

**Soluciones**:
1. Verificar que Redis está corriendo:
   ```bash
   docker-compose ps redis_db
   ```

2. Probar conexión manual:
   ```bash
   docker exec auth_service python -c "
   import redis.asyncio as redis
   import asyncio
   async def test():
       r = await redis.from_url('redis://:password@redis_db:6379/1')
       await r.ping()
       print('Redis OK')
   asyncio.run(test())
   "
   ```

3. Verificar variables de entorno:
   ```bash
   docker exec auth_service env | grep REDIS
   ```

### Problema: "JWT_SECRET_KEY not set"

**Síntomas**: Auth_Service falla al iniciar.

**Solución**:
1. Generar clave segura:
   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(64))"
   ```

2. Añadir al docker-compose.yml o .env:
   ```yaml
   environment:
     JWT_SECRET_KEY: "<tu_clave_aqui>"
   ```

3. Reiniciar servicio:
   ```bash
   docker-compose restart auth_service
   ```

### Problema: "Rate limit exceeded"

**Síntomas**: Error 429 en login después de intentos fallidos.

**Solución**:
1. Esperar 15 minutos (lockout duration)
2. O limpiar manualmente el contador en Redis:
   ```bash
   docker exec redis_db redis-cli -a password DEL "login:user@example.com"
   ```

---

## Mejoras Futuras

### Corto Plazo (1-2 semanas)
- [ ] Implementar token rotation en refresh
- [ ] Añadir soporte para roles y permisos granulares
- [ ] Implementar 2FA (Two-Factor Authentication)
- [ ] Añadir audit logging de todos los eventos de autenticación

### Medio Plazo (1-2 meses)
- [ ] Migrar a OAuth2 + OpenID Connect completo
- [ ] Implementar SSO (Single Sign-On) con proveedores externos
- [ ] Añadir detección de anomalías en patrones de login
- [ ] Implementar session management dashboard

### Largo Plazo (3-6 meses)
- [ ] Soporte para multiple tenants
- [ ] Federación de identidades
- [ ] Integración con LDAP/Active Directory
- [ ] Passwordless authentication (WebAuthn/FIDO2)

---

## Referencias

- [RFC 7519 - JWT](https://datatracker.ietf.org/doc/html/rfc7519)
- [RFC 6749 - OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)

---

**Autor**: OwlBoard Development Team  
**Última Actualización**: 12 de Noviembre 2025  
**Versión**: 2.0.0
