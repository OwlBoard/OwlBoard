# 🚀 OwlBoard - Guía de Inicio Rápido

## Instalación Completa desde Cero

### Prerequisitos

Antes de comenzar, asegúrate de tener instalado:

- **Git** (para clonar el repositorio y submódulos)
- **Docker** (versión 20.10 o superior)
- **Docker Compose** (versión 2.0 o superior)
- **OpenSSL** (para generar certificados SSL/TLS)

#### Verificar Prerequisitos

```bash
git --version          # Debe mostrar versión de Git
docker --version       # Debe mostrar versión 20.10+
docker compose version # Debe mostrar versión 2.0+
openssl version        # Debe mostrar versión de OpenSSL
```

---

## 📥 Instalación Paso a Paso

### 1. Clonar el Repositorio con Submódulos

```bash
# Clonar el repositorio principal CON todos los submódulos
git clone --recursive https://github.com/OwlBoard/OwlBoard.git
cd OwlBoard
```

**⚠️ IMPORTANTE**: El flag `--recursive` es **CRUCIAL**. Sin él, los submódulos estarán vacíos.

Si ya clonaste sin `--recursive`, ejecuta:

```bash
git submodule update --init --recursive
```

### 2. Ejecutar el Script de Instalación Automatizada

#### En Linux/Mac:

```bash
./setup.sh
```

#### En Windows:

**Opción 1: PowerShell (Recomendado)**
```powershell
# Ejecutar PowerShell como Administrador
.\setup.ps1
```

**Opción 2: Git Bash**
```bash
./setup-windows.sh
```

**Opción 3: WSL (Windows Subsystem for Linux)**
```bash
# Si tienes WSL instalado, usa el script de Linux
./setup.sh
```

Este script hace **TODO automáticamente**:

1. ✅ Verifica que tengas todos los prerequisitos
2. 🔄 Inicializa y actualiza los submódulos de Git
3. 🔐 Genera certificados SSL/TLS para todos los servicios
4. ⚙️ Configura variables de entorno (.env)
5. 🧹 Limpia instalaciones previas
6. 🚀 Construye e inicia los 18 contenedores Docker

**Tiempo estimado**: 5-10 minutos (primera vez)

---

## 🌐 Acceder a la Aplicación

Una vez completada la instalación:

### Frontends

- **🖥️ Desktop (Next.js)**: `https://localhost:3002`
- **📱 Mobile (Flutter)**: `https://localhost:3001`

### APIs

- **🌐 API Gateway**: `https://localhost/api`
- **❤️ Health Check**: `https://localhost/health`
- **📊 Status**: `https://localhost/proxy-status`

### ⚠️ Advertencia de Certificado SSL

Los certificados son **auto-firmados** para desarrollo. Tu navegador mostrará:

```
"Tu conexión no es privada" o "Advertencia de seguridad"
```

**Solución**: 
1. Haz clic en "Avanzado" o "Advanced"
2. Luego en "Continuar a localhost" o "Proceed to localhost"

Esto es **normal y seguro** en desarrollo local.

---

## 📊 Verificar que Todo Funciona

### Ver Estado de Servicios

```bash
docker compose ps
```

Deberías ver **18 servicios** corriendo:
- ✅ reverse_proxy
- ✅ load_balancer  
- ✅ api_gateway_1, api_gateway_2, api_gateway_3, api_gateway_4
- ✅ auth_service, user_service, canvas_service, chat_service, comments_service
- ✅ mysql_db, postgres_db, mongo_db, redis_db, rabbitmq
- ✅ nextjs_frontend, mobile_frontend

### Probar Conexiones

```bash
# Test reverse proxy
curl -k https://localhost/health

# Test desktop frontend
curl -k https://localhost:3002

# Test mobile frontend
curl -k https://localhost:3001

# Test API
curl -k https://localhost/api/auth
```

---

## 🛠️ Comandos Útiles

### Ver Logs

```bash
# Logs de todos los servicios
docker compose logs -f

# Logs de un servicio específico
docker compose logs -f reverse_proxy
docker compose logs -f user_service
docker compose logs -f mysql_db

# Últimas 50 líneas
docker compose logs --tail 50 api_gateway_1
```

### Gestión de Servicios

```bash
# Detener todos los servicios
docker compose down

# Detener y eliminar volúmenes (reset completo)
docker compose down -v

# Reiniciar todos los servicios
docker compose restart

# Reiniciar un servicio específico
docker compose restart user_service

# Reconstruir un servicio
docker compose up --build -d user_service
```

### Actualizar Código

```bash
# Actualizar submódulos a últimas versiones
git submodule update --remote --recursive

# Reconstruir después de actualizar
docker compose up --build -d
```

---

## 🔧 Solución de Problemas Comunes

### 1. "Cannot connect to Docker daemon"

**Linux/Mac:**
```bash
# Iniciar Docker
sudo systemctl start docker
```

**Windows:**
```powershell
# Abrir Docker Desktop desde el menú inicio
# Asegurarte de que Docker Desktop esté corriendo
```

### 2. Submódulos Vacíos

```bash
# Inicializar submódulos
git submodule update --init --recursive --force
```

### 3. Puertos Ya en Uso

Si ves errores como `port is already allocated`:

**Linux/Mac:**
```bash
# Ver qué está usando el puerto
sudo lsof -i :3002
sudo lsof -i :443

# Detener servicios conflictivos
```

**Windows (PowerShell como Administrador):**
```powershell
# Ver qué está usando el puerto
netstat -ano | findstr :3002
netstat -ano | findstr :443

# Matar proceso por PID
Stop-Process -Id <PID> -Force
```

### 4. Problemas con PowerShell

**Error: "cannot be loaded because running scripts is disabled"**

```powershell
# Ejecutar PowerShell como Administrador y ejecutar:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Luego volver a ejecutar:
.\setup.ps1
```

### 5. Problemas con Git Bash en Windows

Si `./setup-windows.sh` no funciona:

```bash
# Dar permisos de ejecución
chmod +x setup-windows.sh

# Ejecutar
./setup-windows.sh
```

### 6. OpenSSL no encontrado en Windows

El script de PowerShell busca OpenSSL en Git for Windows. Si no lo encuentra:

1. Instala Git for Windows: https://git-scm.com/download/win
2. O usa WSL (Windows Subsystem for Linux)

### 7. Servicios No Saludables

```bash
# Ver logs del servicio con problemas
docker compose logs user_service

# Verificar que las bases de datos estén corriendo
docker compose ps | grep db

# Reintentar generación de certificados
cd Secure_Channel
./generate_certs.sh
./generate_client_certs.sh
cd ..
docker compose restart
```

### 8. "No space left on device"

```bash
# Limpiar imágenes y contenedores viejos
docker system prune -a --volumes
```

---

## 🔐 Seguridad

### Arquitectura DMZ

OwlBoard usa una **arquitectura DMZ** con:

- **Red Pública**: Solo `reverse_proxy` (1 servicio)
- **Red Privada**: Todos los demás servicios (17 servicios)
- **Aislamiento**: Bases de datos 100% inaccesibles desde internet

### Certificados SSL/TLS

- **TLS 1.2+** en todas las comunicaciones
- **mTLS** entre API Gateway y servicios backend críticos
- **HSTS** (HTTP Strict Transport Security)
- **Rate Limiting**: 50 req/s con burst de 20

Para más detalles: [SECURITY_ARCHITECTURE_DMZ.md](./SECURITY_ARCHITECTURE_DMZ.md)

---

## 📚 Documentación Adicional

- **[SECURITY_ARCHITECTURE_DMZ.md](./SECURITY_ARCHITECTURE_DMZ.md)** - Arquitectura de seguridad completa
- **[DMZ_QUICK_REFERENCE.md](./DMZ_QUICK_REFERENCE.md)** - Referencia rápida de operaciones
- **[SECURITY_COMPARISON.md](./SECURITY_COMPARISON.md)** - Mejoras de seguridad implementadas

---

## 🆘 Obtener Ayuda

1. **Logs**: Siempre revisa los logs primero
   ```bash
   docker compose logs -f
   ```

2. **Estado**: Verifica que todos los servicios estén corriendo
   ```bash
   docker compose ps
   ```

3. **Red**: Verifica la configuración de red
   ```bash
   docker network inspect owlboard-private-network
   docker network inspect owlboard-public-network
   ```

4. **Reset Completo**: Si todo falla
   ```bash
   docker compose down -v
   ./setup.sh
   ```

---

## ✅ Checklist de Instalación Exitosa

- [ ] Los 18 servicios están corriendo (`docker compose ps`)
- [ ] Frontend desktop accesible en `https://localhost:3002`
- [ ] Frontend mobile accesible en `https://localhost:3001`
- [ ] API responde en `https://localhost/health`
- [ ] No hay errores en logs (`docker compose logs`)
- [ ] Bases de datos NO son accesibles externamente

---

¡Listo! 🎉 Ahora puedes empezar a desarrollar en OwlBoard.
