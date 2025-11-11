# Installation Success - What's Next?

Congratulations! You've successfully set up OwlBoard. Here's everything you need to know to get started.

## 🎉 Your OwlBoard is Running!

### Access URLs

Your application is now available at:

- **🖥️ Desktop Frontend**: http://localhost:3002
- **📱 Mobile Frontend**: http://localhost:3001
- **🌐 API Gateway**: http://localhost:8000
- **🔄 Reverse Proxy**: http://localhost:9000

## 📚 Next Steps

### 1. Explore the Application

- Open http://localhost:3002 in your browser
- Create an account or log in
- Create your first dashboard
- Try drawing on the canvas
- Test the real-time chat feature
- Add comments to the board

### 2. Learn the Commands

#### Using Make (Recommended)

```bash
make help              # Show all available commands
make status            # Check service status
make logs              # View all logs
make logs-service SERVICE=user_service  # View specific service logs
make restart           # Restart all services
make stop              # Stop all services
```

#### Using Docker Compose Directly

```bash
docker compose ps                    # Check status
docker compose logs -f              # View all logs
docker compose logs -f user_service # View specific service
docker compose restart              # Restart all services
docker compose down                 # Stop all services
docker compose up -d                # Start all services
```

### 3. Understand the Architecture

Read the documentation:
- **[ARCHITECTURE_SECURITY_REPORT.md](./ARCHITECTURE_SECURITY_REPORT.md)** - Complete architecture overview
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Deployment details
- **[README.md](./README.md)** - Project overview

### 4. Check Service Health

```bash
# Quick health check
docker compose ps

# Expected output: All services "Up" with several marked as "healthy"

# Test endpoints
curl http://localhost:9000/health      # Should return "healthy"
curl http://localhost:8000/api/users   # Should return user data or empty array
```

## 🔧 Useful Operations

### View Logs

```bash
# All services
make logs

# Specific service
make logs-service SERVICE=chat_service

# Frontend services only
make frontend-logs

# Backend services only
make backend-logs

# Database logs
make db-logs
```

### Restart Services

```bash
# Restart all
make restart

# Restart specific service
make restart-service SERVICE=canvas_service

# Rebuild and restart (after code changes)
docker compose up --build -d
```

### Stop and Clean Up

```bash
# Stop all services (keeps data)
make stop

# Stop and remove volumes (clean slate)
make stop-clean

# Complete cleanup
make clean-all
```

## 🐛 Common Tasks

### Update a Service

```bash
# After modifying service code:
docker compose up --build -d service_name

# Example:
docker compose up --build -d user_service
```

### Access a Service Shell

```bash
# Using make
make shell SERVICE=user_service

# Or directly
docker compose exec user_service sh
```

### View Database Data

```bash
# MySQL (User Service)
docker compose exec mysql_db mysql -u user -ppassword user_db

# PostgreSQL (Canvas Service)
docker compose exec postgres_db psql -U admin canvas_db

# MongoDB (Comments Service)
docker compose exec mongo_db mongosh -u user -p password comments_db --authenticationDatabase admin

# Redis (Chat Service)
docker compose exec redis_db redis-cli -a password
```

### Backup Data

```bash
# MySQL backup
docker compose exec -T mysql_db mysqldump -u root -proot user_db > backup_user_db.sql

# PostgreSQL backup
docker compose exec -T postgres_db pg_dump -U admin canvas_db > backup_canvas_db.sql

# Or use make
make backup
```

## 📖 Learning Resources

### Documentation Files

1. **[QUICKSTART.md](./QUICKSTART.md)** - Quick start guide (you've done this!)
2. **[README.md](./README.md)** - Main documentation
3. **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Deployment guide
4. **[ARCHITECTURE_SECURITY_REPORT.md](./ARCHITECTURE_SECURITY_REPORT.md)** - Architecture & security
5. **[CONTRIBUTING.md](./CONTRIBUTING.md)** - How to contribute

### Service-Specific Documentation

Each service has its own README in its directory:
- `User_Service/README.md`
- `Chat_Service/README.md`
- `Comments_Service/README.md`
- `Canvas_Service/README.md`
- `Desktop_Front_End/README.md`
- `Mobile_Front_End/README.md`

## 🎓 Understanding Your Setup

### Services Running

You have 13 containers running:

**Frontend (2):**
- Desktop Frontend (NextJS) - Port 3002
- Mobile Frontend (Flutter) - Port 3001

**Gateways (2):**
- API Gateway (Nginx) - Port 8000
- Reverse Proxy (Nginx) - Port 9000

**Backend Services (4):**
- User Service (Python/FastAPI) - Internal
- Chat Service (Python/FastAPI) - Internal
- Comments Service (Python/FastAPI) - Internal
- Canvas Service (Go/Gin) - Internal

**Data Layer (5):**
- MySQL - User data
- PostgreSQL - Canvas data
- MongoDB - Comments data
- Redis - Chat cache
- RabbitMQ - Message broker

### Network Architecture

```
External Users
     ↓
Desktop (3002) / Mobile (3001)
     ↓
API Gateway (8000) / Reverse Proxy (9000)
     ↓
Backend Services (internal network)
     ↓
Databases (internal network)
```

### Security Features

✅ Network segmentation (public/private networks)
✅ TLS/mTLS encryption
✅ Port isolation (databases not exposed)
✅ Rate limiting (reverse proxy)
✅ CORS protection
✅ SSL certificates

## 🚀 Development Workflow

### Making Changes

1. **Edit code** in your favorite editor
2. **Rebuild the service**:
   ```bash
   docker compose up --build -d service_name
   ```
3. **Check logs**:
   ```bash
   make logs-service SERVICE=service_name
   ```
4. **Test the changes** in your browser

### Running Tests

```bash
# If tests are available for a service
docker compose exec user_service pytest
docker compose exec comments_service pytest
```

## 🆘 Troubleshooting

### Services Won't Start

```bash
# Check what's wrong
docker compose ps
docker compose logs

# Try rebuilding
docker compose up --build -d

# Or clean start
make stop-clean
./setup.sh
```

### Port Conflicts

If ports are in use:
```bash
# Find what's using the port
sudo lsof -i :3002

# Change ports in docker-compose.yml
# Then restart
docker compose down
docker compose up -d
```

### Performance Issues

```bash
# Check resources
docker stats

# Restart specific service
make restart-service SERVICE=service_name

# Complete restart
make restart
```

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

## 🤝 Contributing

Interested in contributing?

1. Read [CONTRIBUTING.md](./CONTRIBUTING.md)
2. Fork the repository
3. Create a feature branch
4. Make your changes
5. Submit a pull request

## 📞 Getting Help

- **Documentation**: Check the docs in this repository
- **Issues**: Open an issue on GitHub
- **Logs**: Always check `docker compose logs` first

## 🎯 Tips for Success

1. **Keep Docker Updated**: Use Docker Desktop 4.0+ or Docker Engine 20.10+
2. **Monitor Resources**: Use `docker stats` to monitor resource usage
3. **Regular Backups**: Use `make backup` to backup your data
4. **Read the Logs**: Most issues can be diagnosed from logs
5. **Use Make**: The Makefile has many convenient shortcuts

## 📊 System Status

Check your system status anytime:

```bash
make status    # or make health
```

This shows:
- Which containers are running
- Which services are healthy
- Current resource usage

## 🎨 Customization

### Environment Variables

Edit `.env` file (copy from `.env.example`):
```bash
cp .env.example .env
# Edit .env with your preferred values
docker compose down
docker compose up -d
```

### Ports

Edit `docker-compose.yml` to change exposed ports:
```yaml
ports:
  - "3002:3000"  # Change 3002 to your preferred port
```

### Resources

Adjust Docker resources in Docker Desktop:
- Settings → Resources → Advanced
- Increase CPU and Memory allocation

## 🌟 Success Checklist

- [x] All 13 containers running
- [x] Can access Desktop Frontend (3002)
- [x] Can access Mobile Frontend (3001)
- [x] Can access API Gateway (8000)
- [x] Health checks passing
- [ ] Created first account
- [ ] Created first dashboard
- [ ] Tested drawing on canvas
- [ ] Tested chat feature
- [ ] Tested comments feature

---

**Congratulations again! You're all set to use OwlBoard!** 🦉

For any questions or issues, refer to the documentation or open an issue on GitHub.

Happy collaborating! 🎨
