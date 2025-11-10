# Browser Certificate Setup Guide

## Problem: SEC_ERROR_UNKNOWN_ISSUER

When accessing `https://localhost:8443` in your browser, you're getting the error **"SEC_ERROR_UNKNOWN_ISSUER"**. This occurs because your browser doesn't trust the self-signed Certificate Authority (CA) that signed the API Gateway's SSL certificate.

## ✅ Certificate Verification Status

Your certificates are properly configured:
- ✅ CA certificate is valid (expires 2035-11-08)
- ✅ API Gateway certificate is correctly signed by CA
- ✅ Certificate includes proper Subject Alternative Names: `localhost`, `127.0.0.1`, `api_gateway`
- ✅ Certificate chain verification: **OK**
- ✅ HTTPS endpoint is functional (responds correctly)

**The issue is only in the browser** - it doesn't trust your self-signed CA certificate.

---

## 🔧 Solution: Import CA Certificate into Browser

You have **3 options** to fix this issue:

### Option 1: Use HTTP (Recommended for Development)

The system is already configured to work with HTTP on port 8000:
- **Frontend URL**: http://localhost:3002
- **API URL**: http://localhost:8000/api

**This is the easiest solution** - the frontend is already configured with HTTP URLs. Just clear your browser cache (Ctrl+Shift+R) and use http://localhost:3002.

---

### Option 2: Import CA Certificate into Firefox (Recommended for HTTPS)

If you want to use HTTPS (port 8443), import the CA certificate:

#### For Firefox:

1. **Open Firefox Settings**
   - Type `about:preferences#privacy` in the address bar
   - Or: Menu → Settings → Privacy & Security

2. **Navigate to Certificates Section**
   - Scroll down to "Security" section
   - Click "View Certificates..." button

3. **Import CA Certificate**
   - Go to "Authorities" tab
   - Click "Import..." button
   - Navigate to: `Secure_Channel/ca/ca.crt`
   - Select the file and click "Open"

4. **Trust Settings**
   - Check: ☑ "Trust this CA to identify websites"
   - Click "OK"

5. **Restart Firefox**
   - Close and reopen Firefox
   - Navigate to https://localhost:8443

#### For Chrome/Chromium/Edge:

1. **Open Chrome Settings**
   - Type `chrome://settings/security` in the address bar
   - Or: Menu → Settings → Privacy and security → Security

2. **Manage Certificates**
   - Click "Manage certificates"
   - Go to "Authorities" tab

3. **Import CA Certificate**
   - Click "Import" button
   - Navigate to: `Secure_Channel/ca/ca.crt`
   - Select the file and click "Open"

4. **Trust Settings**
   - Check: ☑ "Trust this certificate for identifying websites"
   - Click "OK"

5. **Restart Chrome**
   - Close all Chrome windows
   - Reopen and navigate to https://localhost:8443

---

### Option 3: Accept Security Exception (Quick Test Only)

**⚠️ Not recommended for regular use**

For a quick test, you can manually accept the security exception:

1. Navigate to https://localhost:8443
2. Click "Advanced"
3. Click "Accept the Risk and Continue" (Firefox) or "Proceed to localhost (unsafe)" (Chrome)

**Note**: This only works for the current session and must be repeated after browser restart.

---

## 📝 CA Certificate Location

The CA certificate you need to import is located at:
```
/home/rcoon084/Unal/Arquisoft/OwlBoard/Secure_Channel/ca/ca.crt
```

**CA Details:**
- **Issuer**: OwlBoardInternalCA
- **Organization**: OwlBoard
- **Country**: CO
- **State**: Bogota
- **Valid From**: 2025-11-10 20:49:37 GMT
- **Valid Until**: 2035-11-08 20:49:37 GMT (10 years)

---

## 🔍 Verification After Import

After importing the CA certificate, verify it works:

1. **Navigate to HTTPS endpoint**:
   ```
   https://localhost:8443/api/users/login
   ```

2. **Check certificate in browser**:
   - Click the padlock icon in address bar
   - Click "Connection is secure" → "Certificate is valid"
   - Verify:
     - Issued by: OwlBoardInternalCA
     - Issued to: api_gateway
     - No security warnings

3. **Test API request**:
   ```bash
   curl -X POST https://localhost:8443/api/users/login \
     -H "Content-Type: application/json" \
     -d '{"username":"test","password":"test"}'
   ```
   Should return a validation error (422), not a certificate error.

---

## 🐛 Troubleshooting

### Certificate still not trusted after import

1. **Clear browser SSL cache**:
   - Firefox: `about:preferences#privacy` → Cookies and Site Data → Clear Data
   - Chrome: `chrome://settings/clearBrowserData` → Cached images and files

2. **Verify certificate is imported**:
   - Firefox: `about:preferences#privacy` → Certificates → View Certificates → Authorities
   - Look for "OwlBoard" → "OwlBoardInternalCA"

3. **Check certificate file**:
   ```bash
   openssl x509 -in Secure_Channel/ca/ca.crt -text -noout | grep -A2 "Issuer\|Subject"
   ```

### Browser shows "NET::ERR_CERT_AUTHORITY_INVALID"

- This is the same issue - CA not trusted
- Follow import steps for your specific browser

### Certificate works in Firefox but not Chrome

- Chrome and Edge use the system certificate store on Linux
- You may need to import into system trust store:
  ```bash
  # Ubuntu/Debian
  sudo cp Secure_Channel/ca/ca.crt /usr/local/share/ca-certificates/owlboard-ca.crt
  sudo update-ca-certificates
  ```

---

## 📚 Additional Resources

### Project Structure

```
OwlBoard/
├── Secure_Channel/
│   ├── ca/
│   │   └── ca.crt          ← Import this into browser
│   └── certs/
│       ├── api_gateway/
│       │   ├── server.crt  ← Signed by CA
│       │   └── server.key
│       ├── chat_service/
│       └── user_service/
├── docker-compose.yml       ← Mounts certificates to containers
└── owlboard-orchestrator/
    └── nginx.conf           ← HTTPS configuration
```

### Certificate Chain

```
OwlBoardInternalCA (ca.crt)
    └── api_gateway (server.crt)
    └── user_service (server.crt)
    └── chat_service (server.crt)
```

### Nginx Configuration

The API Gateway (`owlboard-orchestrator`) is configured with:
- **Port 80 (HTTP)**: Direct proxy to services
- **Port 443 (HTTPS)**: SSL termination with CA-signed certificate
- **Backend services**: HTTPS with SSL verification against CA

---

## ✅ Recommended Approach

**For Development**: Use HTTP (Option 1)
- Frontend: http://localhost:3002
- API: http://localhost:8000/api
- No certificate import needed
- Already configured in docker-compose.yml

**For Production-like Testing**: Import CA (Option 2)
- Frontend: https://localhost:3002
- API: https://localhost:8443/api
- Full SSL/TLS encryption
- Simulates production environment

---

## 🚀 Quick Start

**Easiest path to get the app working:**

1. **Start services**:
   ```bash
   cd /home/rcoon084/Unal/Arquisoft/OwlBoard
   docker compose up -d
   ```

2. **Clear browser cache**:
   - Press `Ctrl + Shift + R` in browser

3. **Access app via HTTP**:
   - Open: http://localhost:3002
   - Login should work without certificate errors

**If you need HTTPS**, follow Option 2 above to import the CA certificate into your browser.

---

## 📞 Support

If issues persist:
1. Check docker logs: `docker compose logs api_gateway`
2. Verify services are running: `docker compose ps`
3. Test HTTP endpoint: `curl http://localhost:8000/api/users/login`
4. Test HTTPS endpoint: `curl -k https://localhost:8443/api/users/login`

Certificate info: `openssl x509 -in Secure_Channel/ca/ca.crt -text -noout`
