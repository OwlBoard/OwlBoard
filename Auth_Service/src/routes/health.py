"""
Health check endpoints
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import redis

from src.database import get_db, get_redis

router = APIRouter()


@router.get("/health")
async def health_check(db: Session = Depends(get_db), redis_client: redis.Redis = Depends(get_redis)):
    """
    Health check endpoint
    Verifies database and Redis connectivity
    """
    try:
        # Test database connection
        db.execute("SELECT 1")
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"
    
    try:
        # Test Redis connection
        redis_client.ping()
        redis_status = "healthy"
    except Exception as e:
        redis_status = f"unhealthy: {str(e)}"
    
    overall_status = "healthy" if db_status == "healthy" and redis_status == "healthy" else "unhealthy"
    
    return {
        "service": "auth_service",
        "status": overall_status,
        "database": db_status,
        "redis": redis_status
    }
