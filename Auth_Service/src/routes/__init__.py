"""
Route handlers for Auth Service
"""
from fastapi import APIRouter

from src.routes.auth import router as auth_router
from src.routes.health import router as health_router

__all__ = ["auth_router", "health_router"]
