# 🦉 OwlBoard

**A collaborative digital whiteboard platform with real-time collaboration**

[![Docker](https://img.shields.io/badge/docker-ready-blue)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-green)](./LICENSE)

Main repository for the OwlBoard project - a collaborative digital whiteboard platform with microservices architecture, real-time chat, comments, and secure communication.

---

## 🚀 Quick Start (< 5 minutes)

```bash
# 1. Clone the repository
git clone https://github.com/OwlBoard/OwlBoard.git
cd OwlBoard

# 2. Run the automated setup script
./setup.sh

# 3. Access the application
# Desktop: http://localhost:3002
# Mobile:  http://localhost:3001
```

**That's it!** The setup script handles everything automatically:
- ✅ Validates prerequisites (Docker, Docker Compose, OpenSSL)
- ✅ Generates SSL/TLS certificates for secure communication
- ✅ Builds all Docker images
- ✅ Starts all 13 services (frontend, backend, databases)
- ✅ Waits for services to be healthy
- ✅ Displays access URLs and useful commands

📚 **For detailed instructions**, see [QUICKSTART.md](./QUICKSTART.md)

---

## Organization Repositories

This is the main repository that orchestrates the entire OwlBoard ecosystem. Below are links to all the repositories in the OwlBoard organization:

### 🖥️ Frontend
- **[Desktop_Front_End](https://github.com/OwlBoard/Desktop_Front_End)** - Repository for the web front end (JavaScript)
- **[Mobile_Front_End](https://github.com/OwlBoard/Mobile_Front_End)** - Repository for the mobile front end (Dart)

### ⚙️ Services
- **[User_Service](https://github.com/OwlBoard/User_Service)** - User management service (Python)
- **[Canvas_Service](https://github.com/OwlBoard/Canvas_Service)** - Canvas/whiteboard service (Dockerfile)
- **[Comments_Service](https://github.com/OwlBoard/Comments_Service)** - Comments and collaboration service (Dockerfile)
- **[Chat_Service](https://github.com/OwlBoard/Chat_Service)** - Real-time chat service (Dockerfile)
- **[owlboard-orchestrator](https://github.com/OwlBoard/owlboard-orchestrator)** - API Gateway and orchestration service (Nginx)

## 🚀 Quick Start

This main repository contains the Docker Compose configuration to run the entire OwlBoard system. All required repositories are included as Git submodules for easy setup.

### Local Development Setup

1. **Clone this repository with submodules:**
   ```bash
   git clone --recursive https://github.com/OwlBoard/OwlBoard.git
   cd OwlBoard
   ```

2. **Update all submodules to their latest versions (optional):**
   ```bash
   git submodule update --remote --recursive
   ```

3. **Start all services using Docker Compose:**
   ```bash
   docker-compose up --build
   ```

4. **Access the applications:**
   - 🖥️ **Desktop Frontend**: http://localhost:3002
   - 📱 **Mobile Frontend**: http://localhost:3001
   - 🌐 **API Gateway**: http://localhost:8000

5. **Service API Documentation:**
   - User Service: http://localhost:5000/docs
   - Comments Service: http://localhost:8001/docs
   - Chat Service: http://localhost:8002/docs
   - Canvas Service: http://localhost:8080 (Swagger docs if available)

## 📚 Documentation

- **[SECURITY_ARCHITECTURE_DMZ.md](./SECURITY_ARCHITECTURE_DMZ.md)** - Complete DMZ security architecture guide
- **[DMZ_QUICK_REFERENCE.md](./DMZ_QUICK_REFERENCE.md)** - Quick reference for daily operations
- **[SECURITY_COMPARISON.md](./SECURITY_COMPARISON.md)** - Before/after security improvements
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Detailed deployment guide for local development and production
- Port configuration and troubleshooting
- Production deployment checklist
- Security considerations

## 🏗️ Architecture

OwlBoard uses a **DMZ (Demilitarized Zone) microservices architecture** with:
- **Public Reverse Proxy** - Single entry point with DDoS protection and rate limiting
- **Internal Load Balancer** - Distributes traffic across 4 API Gateway replicas
- **API Gateways (4 replicas)** - Routes requests with mTLS support
- **Backend Services** - Independent microservices for each feature (all on private network)
- **Frontend Applications** - Separate web and mobile interfaces (isolated on private network)
- **Databases** - MySQL, MongoDB, PostgreSQL, Redis (completely isolated, no external ports)

### Security Features
- ✅ **Single Public Entry Point** - Only reverse proxy exposed to internet
- ✅ **Network Isolation** - 18 services on private network (internal: true)
- ✅ **Rate Limiting** - 50 req/sec with DDoS protection
- ✅ **SSL/TLS Everywhere** - TLS 1.2+ with strong ciphers
- ✅ **Defense in Depth** - 5 security layers
- ✅ **Zero Database Exposure** - No external database ports
- ✅ **Attack Surface Reduction** - 85% smaller than traditional architecture

📚 **See [SECURITY_ARCHITECTURE_DMZ.md](./SECURITY_ARCHITECTURE_DMZ.md) for detailed security documentation**
- **Message Queue** - RabbitMQ for async communication

## 🐛 Troubleshooting

If you encounter issues:
1. Check all containers are running: `docker-compose ps`
2. View service logs: `docker logs <service_name>`
3. Ensure no port conflicts on your system
4. See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed troubleshooting

## 🤝 Contributing

When contributing to submodules:
1. Create a branch in the specific submodule repository
2. Make your changes and push to the submodule repo
3. Update the submodule reference in this main repository
4. Follow Gitflow branching strategy (feature/, hotfix/, release/)
