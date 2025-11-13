# 🚀 Quick Start Guide

Get OwlBoard running in under 5 minutes!

## Prerequisites

Before you begin, ensure you have:
- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Git**
- **OpenSSL** (usually pre-installed on Linux/Mac)

### Install Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install docker.io docker-compose git openssl -y
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

**macOS:**
```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Or use Homebrew:
brew install docker docker-compose git
```

**Windows:**
- Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- Install [Git for Windows](https://git-scm.com/download/win)
- Use PowerShell or WSL2 for the best experience

## 🎯 One-Command Setup

### Linux / macOS / WSL2

```bash
# Clone the repository
git clone https://github.com/OwlBoard/OwlBoard.git
cd OwlBoard

# Run the setup script
./setup.sh
```

### Windows (PowerShell)

```powershell
# Clone the repository
git clone https://github.com/OwlBoard/OwlBoard.git
cd OwlBoard

# Run the setup script
.\setup.ps1
```

### Check Requirements First (Optional)

Before running setup, you can verify your system meets all requirements:

```bash
# Linux/macOS/WSL2
./check-requirements.sh

# Windows - ensure all prerequisites are installed manually
```

That's it! The script will:
1. ✅ Check all prerequisites
2. ✅ Generate SSL/TLS certificates
3. ✅ Build all Docker images
4. ✅ Start all services
5. ✅ Wait for services to be healthy
6. ✅ Display access URLs

## 🌐 Access Your Application

Once setup is complete, access:

- **Desktop Frontend**: http://localhost:3002
- **Mobile Frontend**: http://localhost:3001
- **API Gateway**: http://localhost:8000
- **Reverse Proxy**: http://localhost:9000

## 🛠️ Common Commands

```bash
# View all running containers
docker compose ps

# View logs for all services
docker compose logs -f

# View logs for a specific service
docker compose logs -f nextjs_frontend

# Stop all services
docker compose down

# Stop and remove volumes (clean slate)
docker compose down -v

# Restart a specific service
docker compose restart user_service

# Rebuild and restart everything
docker compose up --build -d
```

## 🔧 Setup Options

```bash
# Skip certificate generation (if you already have them)
./setup.sh --skip-certs

# Development mode (skip prompts)
./setup.sh --dev

# Show help
./setup.sh --help
```

## 🐛 Troubleshooting

### Port Already in Use
If you get "port already in use" errors:
```bash
# Find what's using the port
sudo lsof -i :3002  # Replace with your port
# Or
sudo netstat -tulpn | grep :3002

# Kill the process or change the port in docker-compose.yml
```

### Docker Permission Denied
```bash
# Add your user to the docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Services Not Starting
```bash
# Check logs
docker compose logs

# Check individual service
docker compose logs user_service

# Restart all services
docker compose restart
```

### "Docker daemon not running"
- Make sure Docker Desktop is running (Mac/Windows)
- On Linux: `sudo systemctl start docker`

### Certificate Issues
```bash
# Regenerate certificates
cd Secure_Channel
./generate_certs.sh
./generate_client_certs.sh
cd ..

# Restart services
docker compose restart
```

## 📊 Verify Everything is Working

```bash
# Check all containers are running
docker compose ps

# Should show 13 containers, most marked as "healthy"

# Test API Gateway
curl http://localhost:8000/api/users

# Test Reverse Proxy health
curl http://localhost:9000/health

# Test Frontend
curl http://localhost:3002
```

## 🎓 Next Steps

1. **Read the full documentation:**
   - [README.md](README.md) - Complete project overview
   - [DEPLOYMENT.md](DEPLOYMENT.md) - Detailed deployment guide
   - [ARCHITECTURE_SECURITY_REPORT.md](ARCHITECTURE_SECURITY_REPORT.md) - Architecture details

2. **Explore the services:**
   - User Service: http://localhost:8000/api/users
   - Chat Service: http://localhost:8000/api/chat
   - Comments Service: http://localhost:8000/api/comments
   - Canvas Service: http://localhost:8000/api/canvas

3. **Check the logs:**
   ```bash
   docker compose logs -f
   ```

## 🆘 Still Having Issues?

1. Check the [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting
2. View service-specific logs: `docker compose logs [service-name]`
3. Verify Docker resources: Docker Desktop → Settings → Resources
4. Open an issue on GitHub with error logs

## 🔄 Starting Fresh

If you want to completely reset your environment:

```bash
# Stop and remove everything
docker compose down -v

# Remove all OwlBoard images
docker images | grep owlboard | awk '{print $3}' | xargs docker rmi -f

# Remove certificate files (optional)
rm -rf Secure_Channel/ca/ca.* Secure_Channel/certs/*/server.*

# Run setup again
./setup.sh
```

## 📝 Notes

- **First-time setup** takes 5-10 minutes (building images)
- **Subsequent starts** take 30-60 seconds
- All data is persisted in Docker volumes
- Certificates are generated automatically and valid for 2+ years

---

**Happy Coding!** 🦉
