# CORS Issues Fix - Network Segmentation Update

## Problem
After implementing network segmentation, the frontend was getting CORS errors:
```
Cross-Origin Request Blocked: The Same Origin Policy disallows reading the remote resource at https://localhost:8443/api/users/8. (Reason: CORS request did not succeed). Status code: (null).
```

## Root Cause
The frontend code had hardcoded URLs pointing directly to `https://localhost:8443`, which was:
1. **No longer exposed** due to network segmentation (backend services isolated on private network)
2. **Using wrong protocol** (HTTPS instead of HTTP)
3. **Bypassing the API Gateway** which handles CORS and routing

## Solution
Updated all frontend code to use environment variables that point to the API Gateway (`http://localhost:8000`) instead of direct backend service URLs.

## Files Modified

### 1. Frontend Components
**File**: `Desktop_Front_End/src/app/user/[userId]/dashboards/page.tsx`
- **Changed**: Hardcoded `https://localhost:8443/api/users` → Environment variable
- **New Code**: Uses `process.env.NEXT_PUBLIC_USER_SERVICE_URL || 'http://localhost:8000/api/users'`
- **Impact**: User dashboard fetching and creation now go through API Gateway

### 2. WebSocket Hooks
**File**: `Desktop_Front_End/src/hooks/useChatWebSocket.ts`
- **Changed**: Hardcoded `wss://localhost:8443/api/chat/ws` → Dynamic WebSocket URL
- **New Code**: Automatically detects protocol and uses API Gateway host
- **Logic**: 
  ```typescript
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  const wsHost = process.env.NEXT_PUBLIC_API_URL?.replace('http://', '').replace('https://', '').split('/')[0] || 'localhost:8000';
  ```

**File**: `Desktop_Front_End/src/hooks/useCommentsWebSocket.ts`
- **Changed**: Hardcoded `wss://localhost:8443/api/comments/ws` → Dynamic WebSocket URL
- **Same logic** as chat WebSocket

### 3. API Service Files
**File**: `Desktop_Front_End/src/services/userApi.ts`
- **Changed**: `'https://localhost:8443/api'` → `'http://localhost:8000/api/users'`
- **Supports both**: `NEXT_PUBLIC_USER_SERVICE_URL` and `REACT_APP_USER_SERVICE_URL`

**File**: `Desktop_Front_End/src/services/canvasApi.ts`
- **Changed**: `'https://localhost:8443/api'` → `'http://localhost:8000/api/canvas'`
- **Supports both**: `NEXT_PUBLIC_CANVAS_SERVICE_URL` and `REACT_APP_CANVAS_SERVICE_URL`

**File**: `Desktop_Front_End/src/services/chatApi.ts`
- **Changed**: Hardcoded `wss://localhost:8443/api/chat/ws` → Dynamic WebSocket URL
- **Same dynamic logic** as hooks

**File**: `Desktop_Front_End/src/services/commentsApi.ts`
- **Changed**: `'https://localhost:8443/api/comments'` → `'http://localhost:8000/api/comments'`
- **Supports both**: `NEXT_PUBLIC_COMMENTS_SERVICE_URL` and `REACT_APP_COMMENTS_SERVICE_URL`

### 4. Server-Side Rendering
**File**: `Desktop_Front_End/src/app/profile/[id]/page_ssr.tsx`
- **Changed**: `'https://localhost:8443/api'` → `'http://api_gateway/api/users'`
- **Impact**: Server-side API calls use internal Docker network name

## Environment Variables Configuration

### docker-compose.yml (Already Configured)
```yaml
nextjs_frontend:
  environment:
    # Client-side API URLs (accessed from browser)
    - NEXT_PUBLIC_API_URL=http://localhost:8000/api
    - NEXT_PUBLIC_USER_SERVICE_URL=http://localhost:8000/api/users
    - NEXT_PUBLIC_COMMENTS_SERVICE_URL=http://localhost:8000/api/comments
    - NEXT_PUBLIC_CHAT_SERVICE_URL=http://localhost:8000/api/chat
    - NEXT_PUBLIC_CANVAS_SERVICE_URL=http://localhost:8000/api/canvas
    
    # Server-side API URLs (internal Docker network)
    - API_URL=http://api_gateway/api
    - USER_SERVICE_URL=http://api_gateway/api/users
    - COMMENTS_SERVICE_URL=http://api_gateway/api/comments
    - CHAT_SERVICE_URL=http://api_gateway/api/chat
    - CANVAS_SERVICE_URL=http://api_gateway/api/canvas
```

## Network Architecture Flow

### Before Fix (Broken)
```
Browser → https://localhost:8443 (NOT EXPOSED) ❌
          ↓
        CORS Error
```

### After Fix (Working)
```
Browser → http://localhost:8000 (API Gateway) ✅
          ↓ (owlboard-public-network)
       api_gateway (CORS handling)
          ↓ (owlboard-private-network)
     Backend Services (user_service, chat_service, etc.)
          ↓
       Databases
```

## WebSocket Architecture

### HTTP → WebSocket Upgrade
```
1. Client connects to: ws://localhost:8000/api/chat/ws/...
2. API Gateway receives connection
3. Nginx proxy_pass with WebSocket headers:
   - Upgrade: websocket
   - Connection: upgrade
4. Backend service establishes WebSocket
5. Bidirectional communication maintained
```

## Testing Checklist

✅ **Frontend Access**:
- Desktop: http://localhost:3002
- Mobile: http://localhost:3001

✅ **API Gateway**: 
- HTTP: http://localhost:8000
- Routes through to backend services

✅ **CORS Headers**:
- Configured in API Gateway nginx.conf
- Allows origins from frontend applications

✅ **WebSocket Connections**:
- Chat: ws://localhost:8000/api/chat/ws/...
- Comments: ws://localhost:8000/api/comments/ws/...

✅ **Backend Isolation**:
- No direct external access to backend services
- All communication through API Gateway
- Private network prevents external routing

## Key Benefits

1. **Single Entry Point**: All API calls go through API Gateway
2. **CORS Management**: Centralized CORS handling in one place
3. **Security**: Backend services isolated on private network
4. **Flexibility**: Easy to change backend service URLs without frontend changes
5. **Protocol Agnostic**: Automatically adapts to HTTP/HTTPS and WS/WSS

## Rebuild Instructions

After any frontend code changes:
```bash
cd /home/rcoon084/Unal/Arquisoft/OwlBoard
docker compose down
docker compose up --build -d
```

## Verification

Check that all services are running:
```bash
docker compose ps
```

Check API Gateway logs:
```bash
docker compose logs -f api_gateway
```

Check frontend logs:
```bash
docker compose logs -f nextjs_frontend
```

## Notes

- The lint errors shown are **pre-existing TypeScript configuration issues**, not related to our changes
- All hardcoded URLs have been replaced with environment variables
- WebSocket connections now properly route through API Gateway
- Network segmentation is fully functional with working CORS
