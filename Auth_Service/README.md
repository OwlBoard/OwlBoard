# OwlBoard Auth Service

Centralized authentication service for the OwlBoard platform.

## Features

- **JWT-based Authentication**: Secure token-based authentication
- **Token Management**: Access and refresh token handling
- **Session Management**: Redis-based session storage
- **Rate Limiting**: Protection against brute force attacks
- **Account Lockout**: Automatic lockout after failed login attempts
- **Token Blacklisting**: Secure logout with token invalidation

## API Endpoints

### Health Check
- `GET /health` - Service health status

### Authentication
- `POST /auth/login` - User login
- `POST /auth/refresh` - Refresh access token
- `POST /auth/verify` - Verify token validity
- `POST /auth/logout` - User logout

### Documentation
- `GET /auth/docs` - Swagger UI documentation
- `GET /auth/redoc` - ReDoc documentation

## Environment Variables

```bash
# Environment
ENVIRONMENT=production

# JWT Configuration
JWT_SECRET_KEY=your-secret-key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Redis Configuration
REDIS_HOST=redis_db
REDIS_PORT=6379
REDIS_DB=1
REDIS_PASSWORD=password

# MySQL Configuration
DATABASE_URL=mysql+pymysql://user:password@mysql_db/user_db

# Security Settings
BCRYPT_ROUNDS=12
MAX_LOGIN_ATTEMPTS=5
LOCKOUT_DURATION_MINUTES=15
```

## Development

### Local Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Run the service:
```bash
uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

### Docker

Build and run with Docker Compose (from project root):
```bash
docker-compose up auth_service
```

## Security Features

- **Password Hashing**: Bcrypt with configurable rounds
- **JWT Tokens**: Secure token generation and validation
- **Token Blacklisting**: Prevents use of logged-out tokens
- **Rate Limiting**: Prevents brute force attacks
- **Account Lockout**: Temporary lockout after failed attempts
- **Token Expiration**: Automatic token expiry

## Database Schema

Uses read-only access to the `users` table from User_Service database:
- `id` - User ID
- `username` - Username
- `email` - Email address
- `password_hash` - Bcrypt password hash
- `is_active` - Account status
- `created_at` - Account creation timestamp
- `updated_at` - Last update timestamp
