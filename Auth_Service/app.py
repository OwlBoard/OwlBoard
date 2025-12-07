"""
OwlBoard Authentication Service
FastAPI-based centralized authentication service
"""
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from contextlib import asynccontextmanager
import uvicorn

from src.config import settings
from src.database import engine, Base
from src.routes import auth_router, health_router
from src.logger_config import setup_logging

# Setup logging
logger = setup_logging()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan events for the application"""
    logger.info("Starting Auth Service...")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    
    # Create database tables
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created/verified")
    except Exception as e:
        logger.error(f"Error creating database tables: {e}")
    
    yield
    
    logger.info("Shutting down Auth Service...")

# Initialize FastAPI app
app = FastAPI(
    title="OwlBoard Auth Service",
    description="Centralized authentication service for OwlBoard platform",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/auth/docs",
    redoc_url="/auth/redoc",
    openapi_url="/auth/openapi.json"
)

# CORS middleware - Note: In production, this is handled by API Gateway
# Keeping commented for reference
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=settings.CORS_ORIGINS,
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# Include routers
app.include_router(health_router, tags=["Health"])
app.include_router(auth_router, prefix="/auth", tags=["Authentication"])

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "OwlBoard Auth Service",
        "version": "1.0.0",
        "status": "running",
        "environment": settings.ENVIRONMENT
    }

if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.ENVIRONMENT == "development",
        log_level="info"
    )
