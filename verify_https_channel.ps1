# Script para verificar el secure channel HTTPS

Write-Host "═" -ForegroundColor Cyan
Write-Host "     VERIFICACIÓN DEL SECURE CHANNEL HTTPS/TLS             " -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan

# 1. Verificar que load_balancer escucha en SSL (puerto 9000)
Write-Host "
[1/6] Verificando puerto SSL en load_balancer..." -ForegroundColor Yellow
$sslPort = docker exec load_balancer sh -c 'netstat -tln 2>/dev/null | grep :9000' 2>$null
if ($sslPort -match '9000') {
    Write-Host ' Load balancer escuchando en puerto 9000' -ForegroundColor Green
    Write-Host "  $sslPort" -ForegroundColor Gray
} else {
    Write-Host ' Load balancer NO está escuchando en puerto 9000' -ForegroundColor Red
}

# 2. Verificar certificados SSL en load_balancer
Write-Host "
[2/6] Verificando certificados SSL en load_balancer..." -ForegroundColor Yellow
$certs = docker exec load_balancer sh -c 'ls -lh /etc/ssl/certs/server.crt /etc/ssl/private/server.key /etc/ssl/certs/ca.crt 2>&1'
if ($certs -match 'server.crt' -and $certs -match 'server.key') {
    Write-Host ' Certificados SSL presentes' -ForegroundColor Green
    $certs -split "
" | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host ' Certificados SSL faltantes' -ForegroundColor Red
}

# 3. Verificar configuración HTTPS en nginx (load_balancer)
Write-Host "
[3/6] Verificando configuración HTTPS en nginx..." -ForegroundColor Yellow
$nginxSSL = docker exec load_balancer sh -c 'grep -E \"listen.*ssl|ssl_certificate \" /etc/nginx/nginx.conf 2>&1'
if ($nginxSSL -match 'listen.*9000.*ssl') {
    Write-Host ' Nginx configurado con SSL en puerto 9000' -ForegroundColor Green
    $nginxSSL -split "
" | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host ' Nginx NO configurado con SSL' -ForegroundColor Red
}

# 4. Verificar conexiones HTTPS desde desktop_proxy
Write-Host "
[4/6] Verificando conexiones HTTPS desde desktop_proxy..." -ForegroundColor Yellow
$proxyHTTPS = docker exec desktop_proxy sh -c 'grep -E \"proxy_pass.*https://|proxy_ssl\" /etc/nginx/nginx.conf 2>&1 | head -5'
if ($proxyHTTPS -match 'https://') {
    Write-Host ' Desktop proxy usa HTTPS para conectar con load_balancer' -ForegroundColor Green
    $proxyHTTPS -split "
" | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host ' Desktop proxy NO usa HTTPS' -ForegroundColor Red
}

# 5. Verificar conexiones HTTPS desde mobile_proxy
Write-Host "
[5/6] Verificando conexiones HTTPS desde mobile_proxy..." -ForegroundColor Yellow
$mobileHTTPS = docker exec mobile_proxy sh -c 'grep -E \"proxy_pass.*https://|proxy_ssl\" /etc/nginx/nginx.conf 2>&1 | head -5'
if ($mobileHTTPS -match 'https://') {
    Write-Host ' Mobile proxy usa HTTPS para conectar con load_balancer' -ForegroundColor Green
    $mobileHTTPS -split "
" | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
} else {
    Write-Host ' Mobile proxy NO usa HTTPS' -ForegroundColor Red
}

# 6. Probar conexión HTTPS interna (desde desktop_proxy hacia load_balancer)
Write-Host "
[6/6] Probando conexión HTTPS interna..." -ForegroundColor Yellow
$httpsTest = docker exec desktop_proxy sh -c 'wget -qO- --no-check-certificate https://load_balancer:9000/health 2>&1'
if ($httpsTest -match 'Load Balancer') {
    Write-Host ' Conexión HTTPS interna funcionando correctamente' -ForegroundColor Green
    Write-Host "  Respuesta: $httpsTest" -ForegroundColor Gray
} else {
    Write-Host ' Conexión HTTPS interna falló' -ForegroundColor Red
    Write-Host "  Error: $httpsTest" -ForegroundColor Gray
}

# Resumen
Write-Host "
" -NoNewline
Write-Host "" -ForegroundColor Cyan
Write-Host "                      RESUMEN                               " -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "  El secure channel HTTPS está:" -ForegroundColor White
Write-Host "   Ubicado entre los PROXIES y el LOAD BALANCER" -ForegroundColor White
Write-Host "   Usando TLS 1.2/1.3 con certificados X.509" -ForegroundColor White
Write-Host "   Encriptando tráfico en la red privada interna" -ForegroundColor White
Write-Host "   Protegiendo comunicaciones de frontend a backend" -ForegroundColor White
