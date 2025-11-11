# OwlBoard Makefile
# Convenient commands for managing the OwlBoard application

.PHONY: help setup start stop restart logs status clean certificates test

# Default target
.DEFAULT_GOAL := help

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)OwlBoard - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

setup: ## Run the automated setup script (first-time setup)
	@echo "$(BLUE)Running OwlBoard setup...$(NC)"
	@chmod +x setup.sh
	@./setup.sh

setup-dev: ## Run setup in development mode (skip prompts)
	@echo "$(BLUE)Running OwlBoard setup (dev mode)...$(NC)"
	@chmod +x setup.sh
	@./setup.sh --dev

certificates: ## Generate SSL/TLS certificates
	@echo "$(BLUE)Generating certificates...$(NC)"
	@cd Secure_Channel && chmod +x generate_certs.sh && ./generate_certs.sh
	@cd Secure_Channel && chmod +x generate_client_certs.sh && ./generate_client_certs.sh
	@echo "$(GREEN)✓ Certificates generated$(NC)"

build: ## Build all Docker images
	@echo "$(BLUE)Building Docker images...$(NC)"
	@docker compose build
	@echo "$(GREEN)✓ Build complete$(NC)"

build-no-cache: ## Build all Docker images without cache
	@echo "$(BLUE)Building Docker images (no cache)...$(NC)"
	@docker compose build --no-cache
	@echo "$(GREEN)✓ Build complete$(NC)"

start: ## Start all services
	@echo "$(BLUE)Starting OwlBoard services...$(NC)"
	@docker compose up -d
	@echo "$(GREEN)✓ Services started$(NC)"
	@echo ""
	@echo "Access your application at:"
	@echo "  Desktop: http://localhost:3002"
	@echo "  Mobile:  http://localhost:3001"
	@echo "  API:     http://localhost:8000"

start-fg: ## Start all services in foreground (with logs)
	@echo "$(BLUE)Starting OwlBoard services...$(NC)"
	@docker compose up

stop: ## Stop all services
	@echo "$(YELLOW)Stopping OwlBoard services...$(NC)"
	@docker compose down
	@echo "$(GREEN)✓ Services stopped$(NC)"

stop-clean: ## Stop all services and remove volumes
	@echo "$(RED)Stopping services and removing volumes...$(NC)"
	@docker compose down -v
	@echo "$(GREEN)✓ Services stopped and volumes removed$(NC)"

restart: ## Restart all services
	@echo "$(BLUE)Restarting OwlBoard services...$(NC)"
	@docker compose restart
	@echo "$(GREEN)✓ Services restarted$(NC)"

restart-service: ## Restart a specific service (use: make restart-service SERVICE=user_service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: Please specify SERVICE=service_name$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Restarting $(SERVICE)...$(NC)"
	@docker compose restart $(SERVICE)
	@echo "$(GREEN)✓ $(SERVICE) restarted$(NC)"

logs: ## Show logs from all services
	@docker compose logs -f

logs-service: ## Show logs from a specific service (use: make logs-service SERVICE=user_service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: Please specify SERVICE=service_name$(NC)"; \
		exit 1; \
	fi
	@docker compose logs -f $(SERVICE)

status: ## Show status of all services
	@echo "$(BLUE)OwlBoard Service Status:$(NC)"
	@echo ""
	@docker compose ps
	@echo ""
	@echo "$(BLUE)Healthy Services:$(NC)"
	@docker ps --filter "health=healthy" --format "  ✓ {{.Names}}" | grep -E "owlboard|mysql|postgres|mongo|redis|rabbitmq" || echo "  No healthy services found"

ps: ## Show running containers (alias for status)
	@docker compose ps

health: ## Check health of all services
	@echo "$(BLUE)Checking service health...$(NC)"
	@echo ""
	@docker compose ps --format "table {{.Name}}\t{{.Status}}" | grep -E "NAMES|healthy|unhealthy" || docker compose ps

shell: ## Open a shell in a service container (use: make shell SERVICE=user_service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: Please specify SERVICE=service_name$(NC)"; \
		exit 1; \
	fi
	@docker compose exec $(SERVICE) /bin/sh || docker compose exec $(SERVICE) /bin/bash

clean: ## Remove all stopped containers, networks, and unused images
	@echo "$(YELLOW)Cleaning up Docker resources...$(NC)"
	@docker compose down
	@docker system prune -f
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

clean-all: ## Remove everything including volumes and images
	@echo "$(RED)WARNING: This will remove all containers, volumes, and images$(NC)"
	@read -p "Are you sure? (y/N): " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		docker system prune -af --volumes; \
		echo "$(GREEN)✓ Complete cleanup done$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

dev: ## Start development environment (build + start)
	@echo "$(BLUE)Starting development environment...$(NC)"
	@docker compose up --build -d
	@echo "$(GREEN)✓ Development environment ready$(NC)"

prod: ## Start production environment
	@echo "$(BLUE)Starting production environment...$(NC)"
	@docker compose -f docker-compose.yml up -d
	@echo "$(GREEN)✓ Production environment started$(NC)"

verify: ## Verify the setup is working correctly
	@echo "$(BLUE)Verifying OwlBoard setup...$(NC)"
	@echo ""
	@echo "Checking services..."
	@docker compose ps
	@echo ""
	@echo "Testing endpoints..."
	@echo -n "  Desktop Frontend:     "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:3002 | grep -q "200" && echo "$(GREEN)✓ OK$(NC)" || echo "$(RED)✗ Failed$(NC)"
	@echo -n "  Mobile Frontend:      "
	@curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 | grep -q "200" && echo "$(GREEN)✓ OK$(NC)" || echo "$(RED)✗ Failed$(NC)"
	@echo -n "  Reverse Proxy Health: "
	@curl -s http://localhost:9000/health | grep -q "healthy" && echo "$(GREEN)✓ OK$(NC)" || echo "$(RED)✗ Failed$(NC)"
	@echo ""

update: ## Update all services to latest images
	@echo "$(BLUE)Updating services...$(NC)"
	@docker compose pull
	@docker compose up -d
	@echo "$(GREEN)✓ Services updated$(NC)"

backup: ## Create a backup of all volumes
	@echo "$(BLUE)Creating backup...$(NC)"
	@mkdir -p backups
	@docker compose exec -T mysql_db mysqldump -u root -proot user_db > backups/user_db_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✓ Backup created in backups/$(NC)"

test: ## Run tests (if available)
	@echo "$(BLUE)Running tests...$(NC)"
	@echo "$(YELLOW)Note: Add your test commands here$(NC)"

install-deps: ## Install required system dependencies
	@echo "$(BLUE)Checking dependencies...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)Docker not found. Please install Docker.$(NC)"; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || docker compose version >/dev/null 2>&1 || { echo "$(RED)Docker Compose not found.$(NC)"; exit 1; }
	@command -v openssl >/dev/null 2>&1 || { echo "$(RED)OpenSSL not found.$(NC)"; exit 1; }
	@echo "$(GREEN)✓ All dependencies are installed$(NC)"

info: ## Show information about the setup
	@echo "$(BLUE)OwlBoard Information$(NC)"
	@echo ""
	@echo "Project Directory: $$(pwd)"
	@echo "Docker Compose Version: $$(docker compose version --short 2>/dev/null || docker-compose version --short)"
	@echo "Docker Version: $$(docker --version)"
	@echo ""
	@echo "Services:"
	@echo "  Frontend:    Desktop (NextJS), Mobile (Flutter)"
	@echo "  Gateways:    API Gateway, Reverse Proxy"
	@echo "  Backend:     User, Chat, Comments, Canvas"
	@echo "  Databases:   MySQL, PostgreSQL, MongoDB, Redis"
	@echo "  Messaging:   RabbitMQ"
	@echo ""
	@echo "URLs:"
	@echo "  Desktop:     http://localhost:3002"
	@echo "  Mobile:      http://localhost:3001"
	@echo "  API Gateway: http://localhost:8000"
	@echo ""

# Service-specific shortcuts
frontend-logs: ## Show frontend logs (desktop + mobile)
	@docker compose logs -f nextjs_frontend mobile_frontend

backend-logs: ## Show backend service logs
	@docker compose logs -f user_service canvas_service comments_service chat_service

db-logs: ## Show database logs
	@docker compose logs -f mysql_db postgres_db mongo_db redis_db

gateway-logs: ## Show gateway logs
	@docker compose logs -f api_gateway reverse_proxy
