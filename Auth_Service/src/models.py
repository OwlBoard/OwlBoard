"""
Database models for Auth Service
"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

from src.database import Base


# SQLAlchemy Models (for reading from User_Service database)
class User(Base):
    """User model - read-only access to User_Service database"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    is_active = Column(Boolean, default=True)


# Pydantic Models (for API requests/responses)
class LoginRequest(BaseModel):
    """Login request model"""
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    """Login response model"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: int
    username: str
    email: str


class RefreshRequest(BaseModel):
    """Refresh token request"""
    refresh_token: str


class TokenResponse(BaseModel):
    """Token response"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class VerifyTokenRequest(BaseModel):
    """Verify token request"""
    token: str


class VerifyTokenResponse(BaseModel):
    """Verify token response"""
    valid: bool
    user_id: Optional[int] = None
    username: Optional[str] = None
    email: Optional[str] = None
    expires_at: Optional[datetime] = None


class LogoutRequest(BaseModel):
    """Logout request"""
    token: str
