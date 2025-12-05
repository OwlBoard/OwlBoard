# OwlBoard - Automated Setup Script for Windows (PowerShell)
# Este script configura todo el sistema OwlBoard desde cero

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "`n╔════════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║                     OwlBoard Setup Script                     ║" "Cyan"
Write-ColorOutput "║              Configuración Automatizada Completa              ║" "Cyan"
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝`n" "Cyan"

# Step 1: Verificar prerequisitos
Write-ColorOutput "[1/6] Verificando prerequisitos..." "Blue"

# Check Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-ColorOutput "❌ Docker no está instalado. Por favor instala Docker Desktop primero." "Red"
    Write-ColorOutput "   Descarga: https://www.docker.com/products/docker-desktop" "Yellow"
    exit 1
}

# Check Docker Compose
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue) -and !(docker compose version 2>$null)) {
    Write-ColorOutput "❌ Docker Compose no está disponible." "Red"
    exit 1
}

# Check Git
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-ColorOutput "❌ Git no está instalado. Por favor instala Git primero." "Red"
    Write-ColorOutput "   Descarga: https://git-scm.com/download/win" "Yellow"
    exit 1
}

# Check OpenSSL (viene con Git Bash)
$opensslPath = ""
if (Get-Command openssl -ErrorAction SilentlyContinue) {
    $opensslPath = "openssl"
} elseif (Test-Path "C:\Program Files\Git\usr\bin\openssl.exe") {
    $opensslPath = "C:\Program Files\Git\usr\bin\openssl.exe"
} else {
    Write-ColorOutput "❌ OpenSSL no está disponible. Instala Git for Windows que incluye OpenSSL." "Red"
    exit 1
}

Write-ColorOutput "✅ Docker version: $(docker --version)" "Green"
Write-ColorOutput "✅ Docker Compose disponible" "Green"
Write-ColorOutput "✅ Git version: $(git --version)" "Green"
Write-ColorOutput "✅ OpenSSL disponible`n" "Green"

# Step 1.5: Inicializar y actualizar submódulos de Git
Write-ColorOutput "[1.5/6] Inicializando submódulos de Git..." "Blue"

# Verificar si estamos en un repositorio git
if (!(Test-Path ".git")) {
    Write-ColorOutput "❌ No estás en un repositorio Git. Este script debe ejecutarse desde el directorio raíz de OwlBoard." "Red"
    exit 1
}

# Verificar si hay submódulos configurados
if (!(Test-Path ".gitmodules")) {
    Write-ColorOutput "⚠️  No se encontró archivo .gitmodules" "Yellow"
} else {
    Write-Host "Inicializando submódulos..."
    git submodule init
    
    Write-Host "Actualizando submódulos (esto puede tomar varios minutos)..."
    git submodule update --init --recursive
    
    # Verificar que los submódulos críticos existan
    $criticalModules = @("User_Service", "Canvas_Service", "Chat_Service", "Comments_Service", "Desktop_Front_End", "Mobile_Front_End", "owlboard-orchestrator")
    
    $allPresent = $true
    foreach ($module in $criticalModules) {
        if ((Test-Path $module) -and ((Get-ChildItem $module | Measure-Object).Count -gt 0)) {
            Write-ColorOutput "✅ Submódulo '$module' OK" "Green"
        } else {
            Write-ColorOutput "❌ Submódulo '$module' no está clonado correctamente" "Red"
            $allPresent = $false
        }
    }
    
    if (-not $allPresent) {
        Write-ColorOutput "`n❌ Algunos submódulos no están disponibles. Intenta:" "Red"
        Write-Host "   git submodule update --init --recursive --force"
        exit 1
    }
}
Write-Host ""

# Step 2: Generar certificados SSL/TLS
Write-ColorOutput "[2/6] Generando certificados SSL/TLS..." "Blue"

if (!(Test-Path "Secure_Channel\ca\ca.crt")) {
    Write-Host "Generando certificados para todos los servicios..."
    
    # Ejecutar script de generación de certificados en Git Bash
    if (Test-Path "Secure_Channel\generate_certs.sh") {
        Write-Host "Ejecutando generate_certs.sh en Git Bash..."
        
        # Buscar Git Bash
        $gitBashPaths = @(
            "C:\Program Files\Git\bin\bash.exe",
            "C:\Program Files (x86)\Git\bin\bash.exe",
            "$env:ProgramFiles\Git\bin\bash.exe"
        )
        
        $gitBash = $null
        foreach ($path in $gitBashPaths) {
            if (Test-Path $path) {
                $gitBash = $path
                break
            }
        }
        
        if ($gitBash) {
            & $gitBash -c "cd Secure_Channel && ./generate_certs.sh"
            Write-ColorOutput "✅ Certificados de servidor generados" "Green"
            
            if (Test-Path "Secure_Channel\generate_client_certs.sh") {
                & $gitBash -c "cd Secure_Channel && ./generate_client_certs.sh"
                Write-ColorOutput "✅ Certificados de cliente generados" "Green"
            }
        } else {
            Write-ColorOutput "⚠️  No se encontró Git Bash. Por favor ejecuta manualmente:" "Yellow"
            Write-Host "   cd Secure_Channel"
            Write-Host "   ./generate_certs.sh"
            Write-Host "   ./generate_client_certs.sh"
        }
    }
} else {
    Write-ColorOutput "✅ Certificados ya existen, saltando generación" "Green"
}
Write-Host ""

# Step 3: Crear archivo .env si no existe
Write-ColorOutput "[3/6] Configurando variables de entorno..." "Blue"

if (!(Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-ColorOutput "✅ Archivo .env creado desde .env.example" "Green"
    } else {
        Write-ColorOutput "⚠️  .env.example no encontrado, creando .env básico..." "Yellow"
        @"
# JWT Configuration
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production-min-32-chars-recommended-64
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Environment
ENVIRONMENT=development
"@ | Out-File -FilePath ".env" -Encoding utf8
        Write-ColorOutput "✅ Archivo .env básico creado" "Green"
    }
} else {
    Write-ColorOutput "✅ Archivo .env ya existe" "Green"
}
Write-Host ""

# Step 4: Limpiar contenedores y volúmenes previos
Write-ColorOutput "[4/6] Limpiando instalación previa (si existe)..." "Blue"

$existingContainers = docker ps -a --filter "name=owlboard" --format "{{.Names}}"
if ($existingContainers) {
    Write-Host "Deteniendo contenedores existentes..."
    docker compose down -v 2>$null
    Write-ColorOutput "✅ Contenedores anteriores eliminados" "Green"
} else {
    Write-ColorOutput "✅ No hay contenedores previos" "Green"
}
Write-Host ""

# Step 5: Construir e iniciar todos los servicios
Write-ColorOutput "[5/6] Construyendo e iniciando servicios..." "Blue"
Write-Host "Esto puede tomar varios minutos dependiendo de tu conexión...`n"

docker compose up --build -d

Write-Host ""
Write-ColorOutput "Esperando a que los servicios estén listos..." "Blue"
Start-Sleep -Seconds 10

# Step 6: Verificar que todos los servicios estén corriendo
Write-ColorOutput "[6/6] Verificando servicios..." "Blue"
Write-Host ""

# Contar servicios
$services = docker compose ps --format json | ConvertFrom-Json
$totalCount = $services.Count
$runningCount = ($services | Where-Object { $_.State -eq "running" }).Count

Write-Host "Servicios iniciados: " -NoNewline
Write-ColorOutput "$runningCount/$totalCount" "Green"
Write-Host ""

# Verificar servicios críticos
$criticalServices = @("reverse_proxy", "load_balancer", "mysql_db", "postgres_db", "redis_db", "mongo_db")
Write-Host "Verificando servicios críticos:"
foreach ($service in $criticalServices) {
    $status = docker compose ps $service --format "{{.State}}" 2>$null
    if ($status -eq "running") {
        Write-ColorOutput "  ✅ $service" "Green"
    } else {
        Write-ColorOutput "  ❌ $service (no está corriendo)" "Red"
    }
}
Write-Host ""

# Verificar estado de servicios
Write-ColorOutput "════════════════════════════════════════════════════════════════" "Cyan"
Write-ColorOutput "✅ ¡Instalación completada con éxito!" "Green"
Write-ColorOutput "════════════════════════════════════════════════════════════════`n" "Cyan"

# Mostrar URLs de acceso
Write-ColorOutput "📱 URLs de Acceso:`n" "Yellow"
Write-Host "  🖥️  Desktop Frontend:  " -NoNewline
Write-ColorOutput "https://localhost:3002" "Cyan"
Write-Host "  📱 Mobile Frontend:   " -NoNewline
Write-ColorOutput "https://localhost:3001" "Cyan"
Write-Host "  🌐 API Gateway:       " -NoNewline
Write-ColorOutput "https://localhost/api" "Cyan"
Write-Host "  ❤️  Health Check:     " -NoNewline
Write-ColorOutput "https://localhost/health`n" "Cyan"

Write-ColorOutput "⚠️  Nota sobre certificados SSL:" "Yellow"
Write-Host "  Los certificados son auto-firmados. Tu navegador mostrará una advertencia."
Write-Host "  Haz clic en 'Avanzado' y 'Continuar' para aceptar el certificado.`n"

# Mostrar estado de servicios
Write-ColorOutput "📊 Estado de Servicios:`n" "Yellow"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | Select-Object -First 20
Write-Host ""

# Comandos útiles
Write-ColorOutput "🛠️  Comandos Útiles:`n" "Yellow"
Write-Host @"
  # Ver logs de todos los servicios
  docker compose logs -f

  # Ver logs de un servicio específico
  docker compose logs -f reverse_proxy

  # Detener todos los servicios
  docker compose down

  # Reiniciar un servicio específico
  docker compose restart user_service

  # Ver estado de servicios
  docker compose ps

  # Actualizar submódulos
  git submodule update --remote --recursive

"@

# Verificar si hay errores en los logs
Write-ColorOutput "🔍 Verificación rápida de errores:`n" "Yellow"
$errors = docker compose logs --tail=100 2>&1 | Select-String -Pattern "error|failed|fatal" -CaseSensitive:$false
if ($errors.Count -gt 0) {
    Write-ColorOutput "⚠️  Se encontraron $($errors.Count) líneas con posibles errores en los logs" "Yellow"
    Write-Host "   Ejecuta 'docker compose logs' para más detalles"
} else {
    Write-ColorOutput "✅ No se detectaron errores obvios en los logs recientes" "Green"
}
Write-Host ""

Write-ColorOutput "🎉 ¡OwlBoard está listo para usar!" "Green"
Write-Host ""
