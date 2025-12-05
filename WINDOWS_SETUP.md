# 🚀 OwlBoard - Guía de Instalación para Windows

## 📋 Prerequisitos para Windows

Antes de instalar OwlBoard en Windows, necesitas:

### 1. Docker Desktop para Windows
- **Descarga**: https://www.docker.com/products/docker-desktop
- **Versión mínima**: 4.0 o superior
- **Requisitos**:
  - Windows 10/11 Pro, Enterprise o Education (64-bit)
  - WSL 2 habilitado (el instalador lo configura automáticamente)
  - Virtualización habilitada en BIOS

### 2. Git for Windows
- **Descarga**: https://git-scm.com/download/win
- **Incluye**: Git Bash y OpenSSL (necesarios para certificados)
- Durante la instalación, selecciona "Git Bash" y "Use Git from Windows Command Prompt"

### 3. PowerShell 5.1+ (ya incluido en Windows 10/11)
- Verifica tu versión:
  ```powershell
  $PSVersionTable.PSVersion
  ```

---

## 🎯 Instalación Paso a Paso

### Paso 1: Preparar Docker Desktop

1. **Instalar Docker Desktop**
   - Ejecuta el instalador descargado
   - Reinicia tu computadora cuando se solicite
   - Abre Docker Desktop desde el menú inicio

2. **Verificar que Docker está corriendo**
   ```powershell
   docker --version
   docker compose version
   ```

3. **Configurar WSL 2 (si es necesario)**
   - Docker Desktop debería configurarlo automáticamente
   - Si hay problemas: https://docs.docker.com/desktop/wsl/

### Paso 2: Clonar el Repositorio

**Opción A: Usando PowerShell**
```powershell
# Abrir PowerShell
cd C:\Users\TuUsuario\Documents

# Clonar con submódulos
git clone --recursive https://github.com/OwlBoard/OwlBoard.git
cd OwlBoard
```

**Opción B: Usando Git Bash**
```bash
# Abrir Git Bash
cd /c/Users/TuUsuario/Documents

# Clonar con submódulos
git clone --recursive https://github.com/OwlBoard/OwlBoard.git
cd OwlBoard
```

**⚠️ IMPORTANTE**: El flag `--recursive` es **CRÍTICO** para clonar los submódulos.

### Paso 3: Ejecutar el Script de Instalación

Tienes **3 opciones**:

#### Opción 1: PowerShell (Recomendada) ⭐

```powershell
# 1. Abrir PowerShell como Administrador
#    Click derecho en el menú inicio → "Windows PowerShell (Administrador)"

# 2. Navegar al directorio de OwlBoard
cd C:\Users\TuUsuario\Documents\OwlBoard

# 3. Permitir ejecución de scripts (solo primera vez)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 4. Ejecutar el script
.\setup.ps1
```

#### Opción 2: Git Bash

```bash
# 1. Abrir Git Bash
# 2. Navegar al directorio
cd /c/Users/TuUsuario/Documents/OwlBoard

# 3. Dar permisos de ejecución
chmod +x setup-windows.sh

# 4. Ejecutar
./setup-windows.sh
```

#### Opción 3: WSL (Windows Subsystem for Linux)

Si tienes WSL instalado:

```bash
# 1. Abrir terminal WSL (Ubuntu, etc.)
# 2. Navegar al directorio
cd /mnt/c/Users/TuUsuario/Documents/OwlBoard

# 3. Ejecutar script de Linux
./setup.sh
```

### Paso 4: Esperar la Instalación

El script hará **automáticamente**:
- ✅ Verificar prerequisitos
- 🔄 Inicializar submódulos de Git
- 🔐 Generar certificados SSL/TLS
- ⚙️ Configurar variables de entorno
- 🧹 Limpiar instalaciones previas
- 🚀 Construir e iniciar 18 contenedores

**Tiempo estimado**: 10-15 minutos en Windows (primera vez)

---

## 🌐 Acceder a la Aplicación

Una vez completada la instalación:

```
🖥️  Desktop Frontend:  https://localhost:3002
📱 Mobile Frontend:   https://localhost:3001
🌐 API Gateway:       https://localhost/api
❤️  Health Check:     https://localhost/health
```

### Aceptar Certificados SSL

En tu navegador (Chrome, Edge, Firefox):

1. Verás: **"Tu conexión no es privada"**
2. Haz clic en **"Avanzado"** o **"Advanced"**
3. Luego en **"Ir a localhost (no seguro)"** o **"Proceed to localhost"**

Esto es **normal y seguro** para desarrollo local.

---

## 🛠️ Comandos Útiles en Windows

### PowerShell

```powershell
# Ver estado de servicios
docker compose ps

# Ver logs
docker compose logs -f
docker compose logs -f reverse_proxy

# Detener servicios
docker compose down

# Reiniciar servicios
docker compose up -d

# Reiniciar un servicio específico
docker compose restart user_service

# Limpiar todo y empezar de nuevo
docker compose down -v
.\setup.ps1
```

### Git Bash

Usa los mismos comandos pero sin el prefijo `.\`:

```bash
docker compose ps
docker compose logs -f
docker compose down
```

---

## 🔧 Solución de Problemas en Windows

### 1. Docker Desktop no inicia

**Síntomas**: Error al ejecutar `docker --version`

**Soluciones**:
```powershell
# Verificar que Docker Desktop está corriendo
# Buscar el ícono de Docker en la bandeja del sistema

# Reiniciar Docker Desktop
# Click derecho en el ícono → Restart

# Si falla, reiniciar Windows
```

### 2. Error: "running scripts is disabled"

**Síntoma**: Al ejecutar `.\setup.ps1`

**Solución**:
```powershell
# Ejecutar PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. OpenSSL no encontrado

**Síntoma**: Error al generar certificados

**Solución**:
1. Instalar Git for Windows (incluye OpenSSL)
2. O usar WSL como alternativa

### 4. Puertos ocupados

**Síntoma**: `port is already allocated`

**Solución**:
```powershell
# Ver qué proceso usa el puerto
netstat -ano | findstr :3002
netstat -ano | findstr :443

# Matar proceso (reemplaza <PID> con el número mostrado)
Stop-Process -Id <PID> -Force

# O cambiar puertos en docker-compose.yml
```

### 5. WSL no está instalado

**Error**: Docker requiere WSL 2

**Solución**:
```powershell
# Abrir PowerShell como Administrador
wsl --install

# Reiniciar Windows
# Luego reinstalar Docker Desktop
```

### 6. Submódulos vacíos

**Síntoma**: Carpetas de servicios están vacías

**Solución**:
```powershell
# En el directorio de OwlBoard
git submodule update --init --recursive --force
```

### 7. Errores de permisos

**Síntoma**: "Access denied" al ejecutar Docker

**Solución**:
1. Agregar tu usuario al grupo "docker-users"
2. Cerrar sesión y volver a iniciar
3. O ejecutar PowerShell como Administrador

### 8. Memoria insuficiente

**Síntoma**: Servicios fallan al iniciar

**Solución**:
1. Abrir Docker Desktop
2. Settings → Resources
3. Aumentar Memory a 4GB o más
4. Apply & Restart

---

## 📊 Verificar Instalación

### Checklist de Verificación

```powershell
# 1. Docker está corriendo
docker --version
# Debe mostrar: Docker version 20.x o superior

# 2. Todos los servicios están corriendo
docker compose ps
# Debe mostrar 18 servicios con estado "Up"

# 3. Frontend desktop accesible
Start-Process https://localhost:3002

# 4. Frontend mobile accesible  
Start-Process https://localhost:3001

# 5. API responde
curl -k https://localhost/health
# Debe mostrar: Public Proxy Healthy

# 6. Bases de datos NO son accesibles (seguridad)
Test-NetConnection localhost -Port 3306
# Debe fallar (esto es correcto)
```

---

## 🔄 Actualizar OwlBoard

```powershell
# 1. Detener servicios
docker compose down

# 2. Actualizar código
git pull
git submodule update --remote --recursive

# 3. Reconstruir e iniciar
docker compose up --build -d
```

---

## 📚 Recursos Adicionales

- **Docker Desktop para Windows**: https://docs.docker.com/desktop/install/windows-install/
- **WSL 2**: https://docs.microsoft.com/en-us/windows/wsl/install
- **Git for Windows**: https://git-scm.com/download/win
- **Documentación OwlBoard**: [README.md](./README.md)

---

## ✅ ¡Instalación Completada!

Si todos los pasos funcionaron:

- ✅ 18 servicios corriendo
- ✅ Frontends accesibles
- ✅ APIs respondiendo
- ✅ Arquitectura de seguridad DMZ activa

**¡Ahora puedes empezar a desarrollar en OwlBoard!** 🎉

---

## 🆘 ¿Necesitas Ayuda?

Si sigues teniendo problemas después de revisar el troubleshooting:

1. Revisa los logs: `docker compose logs -f`
2. Verifica Docker Desktop: Asegúrate de que está corriendo
3. Reinicia Windows si es necesario
4. Ejecuta reset completo: `docker compose down -v` y luego `.\setup.ps1`
