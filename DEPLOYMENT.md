# OwlBoard Deployment Guide

## 🚀 Quick Start (Local Development)

### Prerequisites
- Docker and Docker Compose installed
- Ports 3001, 3002, 8000, 8001, 8002, 8080, 5000, 5432, 6379, 27018, 3306, 5672, 15672 available

### Run the Application

```bash
# Clone the repository
git clone --recursive https://github.com/OwlBoard/OwlBoard.git
cd OwlBoard

# Start all services
docker-compose up --build

# Access the applications:
# - Desktop Frontend: http://localhost:3002
# - Mobile Frontend: http://localhost:3001
# - API Gateway: http://localhost:8000
```

## 🔧 Configuration

### Port Conflicts
If you have port conflicts, edit `docker-compose.yml`:

```yaml
services:
  api_gateway:
    ports:
      - "8001:80"  # Change 8000 to 8001 (or any available port)
```

Then update the frontend environment variables to match:
```yaml
  nextjs_frontend:
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8001/api  # Match your new port
```

### Network Configuration
The application uses Docker's internal network for service-to-service communication:
- **Internal URLs** (inside containers): Use service names like `http://api_gateway/api`
- **External URLs** (from browser): Use `http://localhost:8000/api`

## 🌐 Production Deployment

### 1. Update Environment Variables

Edit `docker-compose.yml` and replace `localhost` with your domain:

```yaml
nextjs_frontend:
  environment:
    # Client-side URLs (browser requests)
    - NEXT_PUBLIC_API_URL=https://your-domain.com/api
    - NEXT_PUBLIC_USER_SERVICE_URL=https://your-domain.com/api
    # ... rest of the variables
    
mobile_frontend:
  environment:
    - EXTERNAL_API_URL=https://your-domain.com/api
```

### 2. Enable HTTPS
For production, configure nginx with SSL certificates:
- Use Let's Encrypt with Certbot
- Update API Gateway nginx.conf to listen on port 443
- Add SSL certificate configuration

### 3. Update CORS Settings
In production, restrict CORS to your actual domain:

Edit `owlboard-orchestrator/nginx.conf`:
```nginx
# Change from:
add_header 'Access-Control-Allow-Origin' '*' always;

# To:
add_header 'Access-Control-Allow-Origin' 'https://your-domain.com' always;
```

## 🏗️ Architecture

```
User Browser
    ↓
API Gateway (nginx) :8000
    ↓
├── User Service :8000
├── Comments Service :8000
├── Chat Service :8000
└── Canvas Service :8080
    ↓
├── MySQL (User DB) :3306
├── MongoDB (Comments) :27018
├── Redis (Chat) :6379
├── PostgreSQL (Canvas) :5432
└── RabbitMQ (Messaging) :5672
```

## 🐛 Troubleshooting

### CORS Errors
- Ensure API Gateway is running: `docker-compose ps api_gateway`
- Check nginx logs: `docker logs api_gateway`
- Verify environment variables match your deployment

### 404 Errors on API Calls
- Verify services are healthy: `docker-compose ps`
- Check service logs: `docker logs <service_name>`
- Ensure environment variables use correct ports

### WebSocket Connection Failures
- Check that API Gateway nginx has WebSocket support enabled
- Verify `Connection: upgrade` headers are being proxied
- Check browser console for detailed WebSocket errors

### Database Connection Issues
- Wait for health checks to pass: `docker-compose ps`
- Check database logs: `docker logs mysql_db` (or other DB)
- Verify DATABASE_URL environment variables

## 📊 Service Endpoints

- **Desktop Frontend**: http://localhost:3002
- **Mobile Frontend**: http://localhost:3001
- **API Gateway**: http://localhost:8000
- **User Service** (direct): http://localhost:5000
- **Comments Service** (direct): http://localhost:8001
- **Chat Service** (direct): http://localhost:8002
- **Canvas Service** (direct): http://localhost:8080
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

## 🔒 Security Considerations

For production deployment:
1. Change all default passwords in docker-compose.yml
2. Use environment variables or secrets management
3. Enable HTTPS with valid SSL certificates
4. Restrict CORS to your actual domains
5. Set up proper firewall rules
6. Use Docker secrets instead of environment variables for sensitive data
7. Regularly update base images and dependencies

## 📝 Development

### Making Changes to Submodules

This project uses Git submodules. When making changes:

```bash
# Enter a submodule
cd User_Service

# Create a feature/hotfix branch
git checkout -b hotfix/my-fix

# Make changes, commit, and push
git add .
git commit -m "fix: description"
git push -u origin hotfix/my-fix

# Return to main repo and update submodule reference
cd ..
git add User_Service
git commit -m "chore: update User_Service submodule"
```

## 🆘 Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review Docker logs for specific services
