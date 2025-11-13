# TLS/SSL Certificate Issue - Quick Fix Guide

## 🚨 Problem
Browser shows: **SEC_ERROR_UNKNOWN_ISSUER** when accessing https://localhost:8443

## ✅ What's Actually Working
- ✅ All Docker services running
- ✅ Nginx properly configured
- ✅ Certificates valid and correctly signed
- ✅ HTTP endpoint works: http://localhost:8000
- ✅ HTTPS endpoint works (curl -k confirms)

## 🎯 Root Cause
Your browser doesn't trust the self-signed CA certificate `OwlBoardInternalCA`. This is **expected behavior** for self-signed certificates.

---

## 🔧 FASTEST FIX: Use HTTP (Recommended)

Your system is already configured for HTTP development:

```bash
# 1. Start services (if not running)
docker compose up -d

# 2. Clear browser cache
Press: Ctrl + Shift + R

# 3. Access via HTTP
http://localhost:3002
```

**That's it!** No certificate import needed. HTTP is perfect for development.

---

## 🔐 ALTERNATIVE: Import CA for HTTPS

If you need HTTPS, import the CA certificate into your browser:

### Firefox (Easiest)
1. Type in address bar: `about:preferences#privacy`
2. Scroll to "Certificates" → Click "View Certificates"
3. "Authorities" tab → Click "Import"
4. Select file: `Secure_Channel/ca/ca.crt`
5. ☑ Check "Trust this CA to identify websites"
6. Click OK → Restart Firefox
7. Access: https://localhost:8443

### Chrome/Edge
1. Type in address bar: `chrome://settings/security`
2. Click "Manage certificates"
3. "Authorities" tab → Click "Import"
4. Select file: `Secure_Channel/ca/ca.crt`
5. ☑ Check "Trust this certificate for identifying websites"
6. Click OK → Restart browser
7. Access: https://localhost:8443

---

## 🧪 Verify It Works

### Test HTTP (no cert needed)
```bash
curl http://localhost:8000/api/users/login
# Should return: 422 error (expected - missing credentials)
```

### Test HTTPS (skip verification)
```bash
curl -k https://localhost:8443/api/users/login
# Should return: 422 error (expected - missing credentials)
```

### Check services running
```bash
docker compose ps
# All services should show "Up"
```

---

## 📁 Files You Need

**CA Certificate Location:**
```
/home/rcoon084/Unal/Arquisoft/OwlBoard/Secure_Channel/ca/ca.crt
```

**Full Documentation:**
- `BROWSER_CERTIFICATE_SETUP.md` - Detailed browser setup
- `DIAGNOSTIC_REPORT.md` - Complete system analysis

---

## 🆘 Still Having Issues?

1. **Services not running?**
   ```bash
   docker compose down
   docker compose up -d
   docker compose logs -f
   ```

2. **HTTP not working?**
   - Check port 8000 is free: `sudo lsof -i :8000`
   - Try: `curl -v http://localhost:8000/api/users/login`

3. **HTTPS after import still fails?**
   - Clear browser cache completely
   - Restart browser (fully close all windows)
   - Verify cert imported: Firefox → about:preferences#privacy → Certificates → View Certificates → Authorities → Look for "OwlBoard"

---

## 💡 TL;DR

**Problem**: Browser doesn't trust self-signed certificate  
**Solution**: Use HTTP (http://localhost:8000) or import CA cert into browser  
**Status**: Everything is working - this is just a browser trust issue  

**For 99% of development work, just use HTTP. It's already set up and works perfectly.**
