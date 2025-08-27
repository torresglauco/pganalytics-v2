# backend/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from contextlib import asynccontextmanager
from app.core.database import create_tables, init_admin_user, wait_for_db, table_exists
from app.api.v1.auth import router as auth_router
import time

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("🚀 Starting pgAnalytics v3.0...")
    
    # Aguardar database estar disponível
    if wait_for_db():
        # Tentar criar tabelas
        if create_tables():
            # Aguardar um pouco antes de criar usuário admin
            time.sleep(2)
            init_admin_user()
            print("✅ Database initialization completed")
        else:
            print("❌ Database initialization failed")
    else:
        print("❌ Could not connect to database")
    
    yield
    print("🛑 Shutting down pgAnalytics...")

app = FastAPI(
    title="pgAnalytics v3.0 API",
    description="PostgreSQL Monitoring with JWT Authentication",
    version="3.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Auth Router
app.include_router(auth_router, prefix="/api/v1")

@app.get("/")
async def root():
    return {
        "message": "pgAnalytics v3.0 API",
        "version": "3.0.0",
        "status": "running",
        "features": [
            "JWT Authentication",
            "Role-based Access Control",
            "PostgreSQL Monitoring",
            "Real-time Metrics",
            "Alert Management"
        ]
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "pganalytics-v3",
        "version": "3.0.0"
    }

@app.get("/debug/tables")
async def debug_tables():
    """Debug endpoint para verificar tabelas"""
    from app.core.database import engine
    from sqlalchemy import text
    
    try:
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
            """))
            tables = [row[0] for row in result]
        
        return {
            "tables": tables,
            "users_table_exists": table_exists("users"),
            "auth_endpoints": [
                "/api/v1/auth/login",
                "/api/v1/auth/register", 
                "/api/v1/auth/me",
                "/api/v1/auth/refresh",
                "/api/v1/auth/logout"
            ]
        }
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
