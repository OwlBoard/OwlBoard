"""
Authentication endpoints
Handles login, logout, token refresh, and token verification
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from jose import jwt, JWTError
from passlib.context import CryptContext
import redis

from src.config import settings
from src.database import get_db, get_redis
from src.models import (
    User, LoginRequest, LoginResponse, RefreshRequest, 
    TokenResponse, VerifyTokenRequest, VerifyTokenResponse, LogoutRequest
)

router = APIRouter()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a password against a hash"""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(data: dict) -> str:
    """Create JWT refresh token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_token(token: str) -> dict:
    """Decode and validate JWT token"""
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )


@router.post("/login", response_model=LoginResponse)
async def login(
    credentials: LoginRequest,
    db: Session = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis)
):
    """
    Login endpoint
    Authenticates user and returns access and refresh tokens
    """
    # Check for account lockout
    lockout_key = f"lockout:{credentials.email}"
    if redis_client.exists(lockout_key):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Account temporarily locked due to too many failed login attempts"
        )
    
    # Find user by email
    user = db.query(User).filter(User.email == credentials.email).first()
    
    if not user or not verify_password(credentials.password, user.password_hash):
        # Increment failed login attempts
        attempts_key = f"login_attempts:{credentials.email}"
        attempts = redis_client.incr(attempts_key)
        redis_client.expire(attempts_key, settings.LOCKOUT_DURATION_MINUTES * 60)
        
        if attempts >= settings.MAX_LOGIN_ATTEMPTS:
            # Lock account
            redis_client.setex(lockout_key, settings.LOCKOUT_DURATION_MINUTES * 60, "1")
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many failed login attempts. Account locked temporarily."
            )
        
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled"
        )
    
    # Clear failed login attempts
    redis_client.delete(f"login_attempts:{credentials.email}")
    
    # Create tokens
    token_data = {
        "sub": str(user.id),
        "username": user.username,
        "email": user.email
    }
    
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)
    
    # Store refresh token in Redis
    redis_client.setex(
        f"refresh_token:{user.id}",
        settings.REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60,
        refresh_token
    )
    
    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user.id,
        username=user.username,
        email=user.email
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshRequest,
    db: Session = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis)
):
    """
    Refresh access token using refresh token
    """
    # Decode refresh token
    try:
        payload = decode_token(request.refresh_token)
    except HTTPException:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type"
        )
    
    user_id = int(payload.get("sub"))
    
    # Verify refresh token exists in Redis
    stored_token = redis_client.get(f"refresh_token:{user_id}")
    if not stored_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token not found or invalid"
        )
    
    # Ensure type consistency for comparison
    if str(stored_token) != str(request.refresh_token):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token not found or invalid"
        )
    
    # Get user
    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    # Create new access token
    token_data = {
        "sub": str(user.id),
        "username": user.username,
        "email": user.email
    }
    
    access_token = create_access_token(token_data)
    
    return TokenResponse(
        access_token=access_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


@router.post("/verify", response_model=VerifyTokenResponse)
async def verify_token(
    request: VerifyTokenRequest,
    redis_client: redis.Redis = Depends(get_redis)
):
    """
    Verify if a token is valid
    Used by other services to validate tokens
    """
    try:
        # Check if token is blacklisted
        if redis_client.exists(f"blacklist:{request.token}"):
            return VerifyTokenResponse(valid=False)
        
        payload = decode_token(request.token)
        
        return VerifyTokenResponse(
            valid=True,
            user_id=int(payload.get("sub")),
            username=payload.get("username"),
            email=payload.get("email"),
            expires_at=datetime.fromtimestamp(payload.get("exp"))
        )
    except HTTPException:
        return VerifyTokenResponse(valid=False)


@router.post("/logout")
async def logout(
    request: LogoutRequest,
    redis_client: redis.Redis = Depends(get_redis)
):
    """
    Logout endpoint
    Blacklists the token to prevent further use
    """
    try:
        payload = decode_token(request.token)
        exp = payload.get("exp")
        
        # Calculate time until token expires
        ttl = exp - int(datetime.utcnow().timestamp())
        
        if ttl > 0:
            # Add token to blacklist
            redis_client.setex(f"blacklist:{request.token}", ttl, "1")
        
        # Remove refresh token if it's a refresh token
        if payload.get("type") == "refresh":
            user_id = int(payload.get("sub"))
            redis_client.delete(f"refresh_token:{user_id}")
        
        return {"message": "Successfully logged out"}
    except HTTPException:
        # Token is invalid, but we still return success
        return {"message": "Successfully logged out"}
