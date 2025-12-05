#!/bin/bash
# OwlBoard - Automated Setup Script
# Este script configura todo el sistema OwlBoard desde cero

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                     OwlBoard Setup Script                     ║"
echo "║              Configuración Automatizada Completa              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Step 1: Verificar prerequisitos
echo -e "${BLUE}[1/5] Verificando prerequisitos...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado. Por favor instala Docker primero.${NC}"
    exit 1
fi

if ! command -v docker compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose no está instalado. Por favor instala Docker Compose primero.${NC}"
    exit 1
fi

if ! command -v openssl &> /dev/null; then
    echo -e "${RED}❌ OpenSSL no está instalado. Por favor instala OpenSSL primero.${NC}"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git no está instalado. Por favor instala Git primero.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker version: $(docker --version)${NC}"
echo -e "${GREEN}✅ Docker Compose version: $(docker compose version)${NC}"
echo -e "${GREEN}✅ OpenSSL version: $(openssl version)${NC}"
echo -e "${GREEN}✅ Git version: $(git --version)${NC}"
echo -e "${GREEN}✅ Git version: $(git --version)${NC}"
echo ""

# Step 1.5: Inicializar y actualizar submódulos de Git
echo -e "${BLUE}[1.5/6] Inicializando submódulos de Git...${NC}"

# Verificar si estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ No estás en un repositorio Git. Este script debe ejecutarse desde el directorio raíz de OwlBoard.${NC}"
    exit 1
fi

# Verificar si hay submódulos configurados
if [ ! -f ".gitmodules" ]; then
    echo -e "${YELLOW}⚠️  No se encontró archivo .gitmodules${NC}"
else
    echo "Inicializando submódulos..."
    git submodule init
    
    echo "Actualizando submódulos (esto puede tomar varios minutos)..."
    git submodule update --init --recursive
    
    # Verificar que los submódulos críticos existan
    critical_modules=("User_Service" "Canvas_Service" "Chat_Service" "Comments_Service" "Desktop_Front_End" "Mobile_Front_End" "owlboard-orchestrator")
    
    all_present=true
    for module in "${critical_modules[@]}"; do
        if [ ! -d "$module" ] || [ -z "$(ls -A "$module" 2>/dev/null)" ]; then
            echo -e "${RED}❌ Submódulo '$module' no está clonado correctamente${NC}"
            all_present=false
        else
            echo -e "${GREEN}✅ Submódulo '$module' OK${NC}"
        fi
    done
    
    if [ "$all_present" = false ]; then
        echo -e "${RED}❌ Algunos submódulos no están disponibles. Intenta:${NC}"
        echo "   git submodule update --init --recursive --force"
        exit 1
    fi
fi
echo ""

# Step 2: Generar certificados SSL/TLS
echo -e "${BLUE}[2/6] Generando certificados SSL/TLS...${NC}"

if [ ! -f "Secure_Channel/ca/ca.crt" ]; then
    echo "Generando certificados para todos los servicios..."
    cd Secure_Channel
    
    # Generar certificados del servidor
    if [ -f "generate_certs.sh" ]; then
        chmod +x generate_certs.sh
        ./generate_certs.sh
        echo -e "${GREEN}✅ Certificados de servidor generados${NC}"
    else
        echo -e "${YELLOW}⚠️  Script generate_certs.sh no encontrado, saltando...${NC}"
    fi
    
    # Generar certificados de cliente para mTLS
    if [ -f "generate_client_certs.sh" ]; then
        chmod +x generate_client_certs.sh
        ./generate_client_certs.sh
        echo -e "${GREEN}✅ Certificados de cliente generados${NC}"
    else
        echo -e "${YELLOW}⚠️  Script generate_client_certs.sh no encontrado, saltando...${NC}"
    fi
    
    cd ..
else
    echo -e "${GREEN}✅ Certificados ya existen, saltando generación${NC}"
fi
echo ""

# Step 3: Crear archivo .env si no existe
echo -e "${BLUE}[3/6] Configurando variables de entorno...${NC}"

if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ Archivo .env creado desde .env.example${NC}"
    else
        echo -e "${YELLOW}⚠️  .env.example no encontrado, creando .env básico...${NC}"
        cat > .env << 'EOF'
# JWT Configuration
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production-min-32-chars-recommended-64
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Environment
ENVIRONMENT=development
EOF
        echo -e "${GREEN}✅ Archivo .env básico creado${NC}"
    fi
else
    echo -e "${GREEN}✅ Archivo .env ya existe${NC}"
fi
echo ""

# Step 4: Limpiar contenedores y volúmenes previos (opcional)
echo -e "${BLUE}[4/6] Limpiando instalación previa (si existe)...${NC}"

if [ "$(docker ps -aq -f name=owlboard)" ]; then
    echo "Deteniendo contenedores existentes..."
    docker compose down -v 2>/dev/null || true
    echo -e "${GREEN}✅ Contenedores anteriores eliminados${NC}"
else
    echo -e "${GREEN}✅ No hay contenedores previos${NC}"
fi
echo ""

# Step 5: Construir e iniciar todos los servicios
echo -e "${BLUE}[5/6] Construyendo e iniciando servicios...${NC}"
echo "Esto puede tomar varios minutos dependiendo de tu conexión..."
echo ""

docker compose up --build -d

echo ""
echo -e "${BLUE}Esperando a que los servicios estén listos...${NC}"
sleep 10

# Step 6: Verificar que todos los servicios estén corriendo
echo -e "${BLUE}[6/6] Verificando servicios...${NC}"
echo ""

# Contar servicios saludables
healthy_count=$(docker compose ps | grep -c "Up" || true)
total_count=$(docker compose ps | wc -l || true)
total_count=$((total_count - 1))  # Restar línea de encabezado

echo -e "Servicios iniciados: ${GREEN}${healthy_count}/${total_count}${NC}"
echo ""

# Verificar servicios críticos
critical_services=("reverse_proxy" "load_balancer" "mysql_db" "postgres_db" "redis_db" "mongo_db")
echo "Verificando servicios críticos:"
for service in "${critical_services[@]}"; do
    if docker compose ps | grep -q "$service.*Up"; then
        echo -e "  ${GREEN}✅${NC} $service"
    else
        echo -e "  ${RED}❌${NC} $service (no está corriendo)"
    fi
done
echo ""

# Verificar estado de servicios
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ ¡Instalación completada con éxito!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Mostrar URLs de acceso
echo -e "${YELLOW}📱 URLs de Acceso:${NC}"
echo ""
echo -e "  🖥️  Desktop Frontend:  ${CYAN}https://localhost:3002${NC}"
echo -e "  📱 Mobile Frontend:   ${CYAN}https://localhost:3001${NC}"
echo -e "  🌐 API Gateway:       ${CYAN}https://localhost/api${NC}"
echo -e "  ❤️  Health Check:     ${CYAN}https://localhost/health${NC}"
echo ""

echo -e "${YELLOW}⚠️  Nota sobre certificados SSL:${NC}"
echo "  Los certificados son auto-firmados. Tu navegador mostrará una advertencia."
echo "  Haz clic en 'Avanzado' y 'Continuar' para aceptar el certificado."
echo ""

# Mostrar estado de servicios
echo -e "${YELLOW}📊 Estado de Servicios:${NC}"
echo ""
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | head -20
echo ""

# Comandos útiles
echo -e "${YELLOW}🛠️  Comandos Útiles:${NC}"
echo ""
echo "  # Ver logs de todos los servicios"
echo "  docker compose logs -f"
echo ""
echo "  # Ver logs de un servicio específico"
echo "  docker compose logs -f reverse_proxy"
echo ""
echo "  # Detener todos los servicios"
echo "  docker compose down"
echo ""
echo "  # Reiniciar un servicio específico"
echo "  docker compose restart user_service"
echo ""
echo "  # Ver estado de servicios"
echo "  docker compose ps"
echo ""
echo "  # Actualizar submódulos"
echo "  git submodule update --remote --recursive"
echo ""

# Verificar si hay errores en los logs
echo -e "${YELLOW}🔍 Verificación rápida de errores:${NC}"
echo ""
error_count=$(docker compose logs --tail=100 2>&1 | grep -i "error\|failed\|fatal" | wc -l || true)
if [ "$error_count" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Se encontraron $error_count líneas con posibles errores en los logs${NC}"
    echo "   Ejecuta 'docker compose logs' para más detalles"
else
    echo -e "${GREEN}✅ No se detectaron errores obvios en los logs recientes${NC}"
fi
echo ""

echo -e "${GREEN}🎉 ¡OwlBoard está listo para usar!${NC}"
echo ""
