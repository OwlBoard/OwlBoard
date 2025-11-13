# OwlBoard Setup Script for Windows
# PowerShell script to set up OwlBoard on Windows

param(
    [switch]$SkipCerts,
    [switch]$Dev,
    [switch]$Help
)

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Colors
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Error { Write-Host "✗ $args" -ForegroundColor Red }
function Write-Warning { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-Info { Write-Host "ℹ $args" -ForegroundColor Cyan }
function Write-Header { 
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $args -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

if ($Help) {
    Write-Host @"
OwlBoard Setup Script for Windows

Usage: .\setup.ps1 [options]

Options:
  -SkipCerts    Skip certificate generation (use existing)
  -Dev          Development mode (skip some checks)
  -Help         Show this help message

Example:
  .\setup.ps1
  .\setup.ps1 -SkipCerts
  .\setup.ps1 -Dev

"@
    exit 0
}

Write-Header "Welcome to OwlBoard Setup (Windows)"
Write-Host "This script will set up your OwlBoard environment automatically."
Write-Host ""

# Step 1: Check prerequisites
Write-Header "Step 1: Checking Prerequisites"

$missingDeps = $false

# Check Docker
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Success "Docker is installed"
    $dockerVersion = docker --version
    Write-Host "  Version: $dockerVersion"
} else {
    Write-Error "Docker is not installed"
    Write-Host "  Please install Docker Desktop: https://www.docker.com/products/docker-desktop"
    $missingDeps = $true
}

# Check Docker Compose
if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
    Write-Success "Docker Compose is installed"
} elseif (docker compose version 2>$null) {
    Write-Success "Docker Compose (V2) is available"
} else {
    Write-Error "Docker Compose is not installed"
    $missingDeps = $true
}

# Check Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Success "Git is installed"
} else {
    Write-Error "Git is not installed"
    Write-Host "  Please install Git: https://git-scm.com/download/win"
    $missingDeps = $true
}

# Check OpenSSL
if (Get-Command openssl -ErrorAction SilentlyContinue) {
    Write-Success "OpenSSL is installed"
} else {
    Write-Warning "OpenSSL is not installed (required for certificates)"
    Write-Host "  Install with: choco install openssl"
    Write-Host "  Or: https://slproweb.com/products/Win32OpenSSL.html"
    $missingDeps = $true
}

if ($missingDeps) {
    Write-Error "Missing required dependencies. Please install them and run this script again."
    exit 1
}

# Check Docker daemon
try {
    docker info | Out-Null
    Write-Success "Docker daemon is running"
} catch {
    Write-Error "Docker daemon is not running. Please start Docker Desktop and try again."
    exit 1
}

# Step 2: Generate certificates
if (-not $SkipCerts) {
    Write-Header "Step 2: Generating SSL/TLS Certificates"
    
    if (Test-Path "Secure_Channel\ca\ca.crt") {
        Write-Warning "CA certificates already exist"
        if (-not $Dev) {
            $response = Read-Host "Do you want to regenerate them? (y/N)"
            if ($response -eq 'y' -or $response -eq 'Y') {
                Push-Location Secure_Channel
                bash generate_certs.sh
                bash generate_client_certs.sh
                Pop-Location
                Write-Success "Certificates generated"
            } else {
                Write-Info "Skipping certificate generation"
            }
        }
    } else {
        Write-Info "Generating certificates for the first time..."
        Push-Location Secure_Channel
        bash generate_certs.sh
        bash generate_client_certs.sh
        Pop-Location
        Write-Success "Certificates generated"
    }
} else {
    Write-Info "Skipping certificate generation (-SkipCerts flag)"
}

# Step 3: Docker environment cleanup
Write-Header "Step 3: Docker Environment Cleanup"

$existingContainers = docker ps -a --filter "name=owlboard" --format "{{.Names}}" 2>$null

if ($existingContainers) {
    Write-Warning "Found existing OwlBoard containers"
    if (-not $Dev) {
        $response = Read-Host "Do you want to remove them? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Info "Stopping and removing old containers..."
            docker compose down -v
            Write-Success "Old containers removed"
        }
    }
} else {
    Write-Success "No existing containers found"
}

# Step 4: Build and start services
Write-Header "Step 4: Building and Starting Services"

Write-Info "This may take several minutes on the first run..."
Write-Host ""

Write-Info "Building Docker images..."
docker compose build --no-cache
if ($LASTEXITCODE -eq 0) {
    Write-Success "Docker images built successfully"
} else {
    Write-Error "Failed to build Docker images"
    exit 1
}

Write-Info "Starting services..."
docker compose up -d
if ($LASTEXITCODE -eq 0) {
    Write-Success "Services started successfully"
} else {
    Write-Error "Failed to start services"
    exit 1
}

# Step 5: Wait for services
Write-Header "Step 5: Waiting for Services to Start"

Write-Info "Waiting for databases to be healthy (this may take 30-60 seconds)..."
Start-Sleep -Seconds 10

$maxWait = 60
$waited = 0

while ($waited -lt $maxWait) {
    $running = docker ps --filter "name=owlboard" --format "{{.Names}}" | Measure-Object -Line | Select-Object -ExpandProperty Lines
    
    Write-Host -NoNewline "`rWaiting for services... ($running containers running)"
    
    # Check if critical services are healthy
    $mysqlHealthy = docker ps --filter "name=mysql_db" --filter "health=healthy" -q
    $postgresHealthy = docker ps --filter "name=postgres_db" --filter "health=healthy" -q
    $mongoHealthy = docker ps --filter "name=mongo_db" --filter "health=healthy" -q
    
    if ($mysqlHealthy -and $postgresHealthy -and $mongoHealthy) {
        Write-Host ""
        Write-Success "All critical databases are healthy"
        break
    }
    
    Start-Sleep -Seconds 2
    $waited += 2
}

Write-Host ""

# Step 6: Display access information
Write-Header "Setup Complete! 🎉"

Write-Host ""
Write-Success "OwlBoard is now running!"
Write-Host ""
Write-Host "Access your applications at:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Desktop Frontend:    http://localhost:3002" -ForegroundColor White
Write-Host "  Mobile Frontend:     http://localhost:3001" -ForegroundColor White
Write-Host "  API Gateway:         http://localhost:8000" -ForegroundColor White
Write-Host "  Reverse Proxy:       http://localhost:9000" -ForegroundColor White
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  View logs:              docker compose logs -f [service_name]" -ForegroundColor Yellow
Write-Host "  Check status:           docker compose ps" -ForegroundColor Yellow
Write-Host "  Stop services:          docker compose down" -ForegroundColor Yellow
Write-Host "  Restart services:       docker compose restart" -ForegroundColor Yellow
Write-Host ""
Write-Host "For detailed documentation, see:" -ForegroundColor Cyan
Write-Host "  - README.md"
Write-Host "  - DEPLOYMENT.md"
Write-Host "  - ARCHITECTURE_SECURITY_REPORT.md"
Write-Host ""

# Optional: Show container status
if (-not $Dev) {
    $response = Read-Host "Do you want to see the container status? (Y/n)"
    if ($response -ne 'n' -and $response -ne 'N') {
        Write-Host ""
        docker compose ps
    }
}

Write-Success "Setup completed successfully!"
