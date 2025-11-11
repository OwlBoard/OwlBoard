# Load Balancer Deployment Checklist

Use this checklist to ensure successful deployment of the load balancing implementation.

## Pre-Deployment

- [ ] **Backup current state**
  ```bash
  docker compose ps > pre-deployment-status.txt
  git add -A && git commit -m "backup: pre-load-balancer state"
  ```

- [ ] **Verify Docker resources**
  ```bash
  docker system df  # Ensure sufficient disk space
  docker system prune -f  # Clean up unused resources
  ```

- [ ] **Check current service health**
  ```bash
  docker compose ps  # All services should be healthy
  ```

- [ ] **Review configuration files**
  - [ ] `docker-compose.yml` syntax validated
  - [ ] `load_balancer_nginx.conf` reviewed
  - [ ] Certificate volumes mounted correctly

## Deployment Steps

- [ ] **Stop existing services**
  ```bash
  docker compose down
  ```

- [ ] **Validate new configuration**
  ```bash
  docker compose config > /dev/null && echo "✓ Valid"
  ```

- [ ] **Build new images**
  ```bash
  docker compose build --no-cache load_balancer
  ```

- [ ] **Start all services**
  ```bash
  docker compose up -d
  ```

- [ ] **Wait for services to be healthy** (90 seconds)
  ```bash
  sleep 90
  ```

## Post-Deployment Verification

### Service Health
- [ ] **Check container count**
  ```bash
  docker compose ps | wc -l  # Should be 17 (header + 16 services)
  ```

- [ ] **Verify all containers running**
  ```bash
  docker compose ps | grep -c "Up"  # Should be 16
  ```

- [ ] **Check load balancer health**
  ```bash
  curl -f http://localhost:8000/health || echo "FAILED"
  curl -f http://localhost:9000/health || echo "FAILED"
  ```

- [ ] **Check load balancer status**
  ```bash
  curl http://localhost:8000/lb-status
  # Expected: "Active Backends: 4"
  ```

### Gateway Health
- [ ] **Verify all 4 gateways running**
  ```bash
  for i in {1..4}; do
    docker compose ps api_gateway_$i | grep -q "Up" && echo "✓ Gateway $i UP" || echo "✗ Gateway $i DOWN"
  done
  ```

- [ ] **Check gateway connectivity**
  ```bash
  for i in {1..4}; do
    docker exec api_gateway_$i curl -s http://localhost/health > /dev/null && echo "✓ Gateway $i responding"
  done
  ```

### Frontend Access
- [ ] **Desktop frontend accessible**
  ```bash
  curl -I http://localhost:3002 | grep -q "200" && echo "✓ Desktop OK"
  ```

- [ ] **Mobile frontend accessible**
  ```bash
  curl -I http://localhost:3001 | grep -q "200" && echo "✓ Mobile OK"
  ```

- [ ] **API Gateway accessible through load balancer**
  ```bash
  curl -I http://localhost:8000/api/users | grep -q "200\|301\|302" && echo "✓ API OK"
  ```

### Load Distribution
- [ ] **Test load distribution**
  ```bash
  for i in {1..10}; do curl -s http://localhost:8000/health > /dev/null; done
  docker compose logs load_balancer | grep upstream: | tail -10
  # Should see mix of api_gateway_1, 2, 3, 4
  ```

- [ ] **Verify least_conn algorithm**
  ```bash
  docker exec load_balancer cat /etc/nginx/nginx.conf | grep -q "least_conn" && echo "✓ Algorithm configured"
  ```

### Backend Services
- [ ] **User Service responding**
  ```bash
  curl -I http://localhost:8000/api/users | grep -q "200\|301\|302" && echo "✓ User Service"
  ```

- [ ] **Canvas Service responding**
  ```bash
  curl -I http://localhost:8000/api/canvas | grep -q "200\|301\|302" && echo "✓ Canvas Service"
  ```

- [ ] **Chat Service responding**
  ```bash
  curl -I http://localhost:8000/api/chat | grep -q "200\|301\|302" && echo "✓ Chat Service"
  ```

- [ ] **Comments Service responding**
  ```bash
  curl -I http://localhost:8000/api/comments | grep -q "200\|301\|302" && echo "✓ Comments Service"
  ```

### Database Connectivity
- [ ] **Databases not externally accessible** (security check)
  ```bash
  nc -zv localhost 3306 2>&1 | grep -q "Connection refused" && echo "✓ MySQL isolated"
  nc -zv localhost 5432 2>&1 | grep -q "Connection refused" && echo "✓ PostgreSQL isolated"
  nc -zv localhost 27017 2>&1 | grep -q "Connection refused" && echo "✓ MongoDB isolated"
  nc -zv localhost 6379 2>&1 | grep -q "Connection refused" && echo "✓ Redis isolated"
  ```

- [ ] **Backend services can reach databases**
  ```bash
  docker compose logs user_service | grep -q "Connected to database" && echo "✓ DB connection working"
  ```

## Failover Testing

- [ ] **Test gateway failover**
  ```bash
  # Stop one gateway
  docker compose stop api_gateway_2
  
  # Verify system still works
  curl -f http://localhost:8000/health && echo "✓ Failover working"
  
  # Restart gateway
  docker compose start api_gateway_2
  ```

- [ ] **Verify automatic recovery**
  ```bash
  sleep 10
  docker compose logs load_balancer | grep api_gateway_2 | tail -5
  # Should see api_gateway_2 receiving traffic again
  ```

## Performance Testing

- [ ] **Load test with concurrent requests**
  ```bash
  for i in {1..50}; do
    curl -s http://localhost:8000/health > /dev/null &
  done
  wait
  echo "✓ Handled 50 concurrent requests"
  ```

- [ ] **Monitor resource usage**
  ```bash
  docker stats --no-stream load_balancer api_gateway_1 api_gateway_2 api_gateway_3 api_gateway_4
  # Check CPU and memory usage
  ```

## Monitoring Setup

- [ ] **Configure log rotation** (if not already done)
  ```bash
  docker compose logs --tail=1000 load_balancer > /var/log/owlboard-lb.log
  ```

- [ ] **Set up health check monitoring**
  ```bash
  # Add to cron for continuous monitoring
  */5 * * * * curl -f http://localhost:8000/health || echo "Load balancer DOWN" | mail -s "OwlBoard Alert" admin@example.com
  ```

- [ ] **Document monitoring endpoints**
  - Health: `http://localhost:8000/health`
  - Status: `http://localhost:8000/lb-status`
  - Logs: `docker compose logs -f load_balancer`

## Documentation Review

- [ ] **Read implementation guide**
  - [ ] `LOAD_BALANCER_IMPLEMENTATION.md` reviewed

- [ ] **Read quick start guide**
  - [ ] `LOAD_BALANCER_QUICKSTART.md` reviewed

- [ ] **Review architecture diagram**
  - [ ] `LOAD_BALANCER_DIAGRAM.txt` understood

- [ ] **Update team documentation**
  - [ ] Team notified of new architecture
  - [ ] Monitoring procedures updated
  - [ ] Incident response plan updated

## Rollback Preparation

- [ ] **Document rollback steps**
  ```bash
  # If needed to rollback:
  docker compose down
  git checkout HEAD~1 docker-compose.yml
  docker compose up -d --build
  ```

- [ ] **Verify rollback plan tested**
  - [ ] Rollback steps documented
  - [ ] Backup of previous configuration available
  - [ ] Data volume persistence confirmed

## Sign-Off

- [ ] **All checks passed**
- [ ] **System stable for 30 minutes**
- [ ] **No errors in logs**
- [ ] **Frontend accessible and functional**
- [ ] **Backend services responding correctly**
- [ ] **Load distribution working as expected**
- [ ] **Failover tested successfully**
- [ ] **Team notified of completion**

---

## Quick Command Reference

### Check Everything
```bash
# One-liner to check all critical components
echo "=== Service Status ===" && docker compose ps && \
echo "=== Load Balancer Health ===" && curl -s http://localhost:8000/health && \
echo "=== Load Balancer Status ===" && curl -s http://localhost:8000/lb-status && \
echo "=== Gateway Count ===" && docker compose ps | grep api_gateway | wc -l && \
echo "=== Frontend Desktop ===" && curl -I http://localhost:3002 2>&1 | head -1 && \
echo "=== Frontend Mobile ===" && curl -I http://localhost:3001 2>&1 | head -1
```

### Monitor Load Distribution
```bash
# Watch real-time load distribution
docker compose logs -f load_balancer | grep --line-buffered upstream:
```

### Emergency Stop
```bash
# Stop everything if issues arise
docker compose down
```

### Emergency Restart
```bash
# Restart just the load balancer
docker compose restart load_balancer
```

---

## Success Criteria

✅ All 16 containers running  
✅ Load balancer healthy on ports 8000 and 9000  
✅ 4 API gateways receiving traffic  
✅ Frontends accessible  
✅ Backend services responding  
✅ Databases isolated but accessible to services  
✅ Failover working correctly  
✅ No errors in logs  
✅ System stable  

## Deployment Date

**Date**: _________________  
**Deployed By**: _________________  
**Verified By**: _________________  
**Status**: [ ] Success [ ] Rolled Back [ ] Issues (see notes)  
**Notes**: _________________________________________________
