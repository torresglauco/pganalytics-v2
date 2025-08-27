#!/usr/bin/env python3
"""
PG Analytics API v2.0.0 - Ultra Minimal Version
Compatible with Python 3.13 and any Python version
"""

import json
import hashlib
import hmac
import time
import base64
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

# Tentar importar dependências opcionais
try:
    from fastapi import FastAPI, HTTPException, Depends, Request
    from fastapi.responses import JSONResponse
    from fastapi.middleware.cors import CORSMiddleware
    FASTAPI_AVAILABLE = True
except ImportError:
    FASTAPI_AVAILABLE = False

try:
    import jwt
    JWT_AVAILABLE = True
except ImportError:
    JWT_AVAILABLE = False

try:
    import bcrypt
    BCRYPT_AVAILABLE = True
except ImportError:
    BCRYPT_AVAILABLE = False

try:
    import uvicorn
    UVICORN_AVAILABLE = True
except ImportError:
    UVICORN_AVAILABLE = False

# Configurações
SECRET_KEY = "pganalytics-ultra-simple-secret-2024"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Função de hash simples (fallback se bcrypt não estiver disponível)
def simple_hash(password: str) -> str:
    """Hash simples usando hashlib se bcrypt não estiver disponível"""
    return hashlib.sha256(f"pganalytics_{password}_salt".encode()).hexdigest()

def verify_simple_hash(password: str, hashed: str) -> bool:
    """Verificar hash simples"""
    return simple_hash(password) == hashed

# JWT simples se PyJWT não estiver disponível
def create_simple_token(data: dict) -> str:
    """Criar token simples se JWT não estiver disponível"""
    payload = {
        **data,
        "exp": int(time.time()) + (ACCESS_TOKEN_EXPIRE_MINUTES * 60),
        "iat": int(time.time())
    }
    payload_json = json.dumps(payload, sort_keys=True)
    signature = hmac.new(
        SECRET_KEY.encode(),
        payload_json.encode(),
        hashlib.sha256
    ).hexdigest()
    
    token_data = {
        "payload": payload,
        "signature": signature
    }
    return base64.b64encode(json.dumps(token_data).encode()).decode()

def verify_simple_token(token: str) -> dict:
    """Verificar token simples"""
    try:
        token_data = json.loads(base64.b64decode(token).decode())
        payload = token_data["payload"]
        signature = token_data["signature"]
        
        # Verificar assinatura
        payload_json = json.dumps(payload, sort_keys=True)
        expected_signature = hmac.new(
            SECRET_KEY.encode(),
            payload_json.encode(),
            hashlib.sha256
        ).hexdigest()
        
        if signature != expected_signature:
            raise ValueError("Invalid signature")
        
        # Verificar expiração
        if payload.get("exp", 0) < time.time():
            raise ValueError("Token expired")
        
        return payload
    except Exception as e:
        raise ValueError(f"Invalid token: {str(e)}")

# Banco de dados em memória
fake_users_db = {
    "admin": {
        "id": 1,
        "username": "admin",
        "email": "admin@pganalytics.com",
        "full_name": "Administrador",
        "is_active": True,
        "created_at": "2024-01-01T00:00:00Z",
        "password_hash": simple_hash("admin")
    },
    "user": {
        "id": 2,
        "username": "user",
        "email": "user@pganalytics.com",
        "full_name": "Usuário",
        "is_active": True,
        "created_at": "2024-01-01T00:00:00Z",
        "password_hash": simple_hash("user")
    },
    "test": {
        "id": 3,
        "username": "test",
        "email": "test@pganalytics.com",
        "full_name": "Teste",
        "is_active": True,
        "created_at": "2024-01-01T00:00:00Z",
        "password_hash": simple_hash("test")
    }
}

def authenticate_user(username: str, password: str) -> Optional[dict]:
    """Autenticar usuário"""
    user = fake_users_db.get(username)
    if not user:
        return None
    
    if BCRYPT_AVAILABLE:
        # Usar bcrypt se disponível (não implementado neste exemplo simples)
        pass
    
    # Usar hash simples
    if verify_simple_hash(password, user["password_hash"]):
        return user
    return None

def create_access_token(data: dict) -> str:
    """Criar token de acesso"""
    if JWT_AVAILABLE:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        to_encode = data.copy()
        to_encode.update({"exp": expire})
        return jwt.encode(to_encode, SECRET_KEY, algorithm="HS256")
    else:
        return create_simple_token(data)

def verify_token(token: str) -> dict:
    """Verificar token"""
    if JWT_AVAILABLE:
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
            return payload
        except jwt.PyJWTError as e:
            raise ValueError(f"Invalid token: {str(e)}")
    else:
        return verify_simple_token(token)

# Aplicação FastAPI ou servidor simples
if FASTAPI_AVAILABLE:
    app = FastAPI(
        title="PG Analytics API Ultra-Minimal",
        version="2.0.0",
        description="Ultra minimal version compatible with Python 3.13"
    )
    
    # CORS simples
    @app.middleware("http")
    async def cors_handler(request: Request, call_next):
        response = await call_next(request)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "*"
        response.headers["Access-Control-Allow-Credentials"] = "true"
        return response
    
    @app.options("/{path:path}")
    async def options_handler(path: str):
        return JSONResponse(content={}, headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*"
        })
    
    @app.get("/")
    async def root():
        return {
            "message": "PG Analytics API Ultra-Minimal v2.0.0",
            "status": "running",
            "python_version": f"{python_version_info.major}.{python_version_info.minor}",
            "dependencies": {
                "fastapi": FASTAPI_AVAILABLE,
                "jwt": JWT_AVAILABLE,
                "bcrypt": BCRYPT_AVAILABLE,
                "uvicorn": UVICORN_AVAILABLE
            },
            "test_users": ["admin", "user", "test"],
            "endpoints": {
                "login": "/api/v1/auth/login",
                "me": "/api/v1/auth/me",
                "health": "/health"
            }
        }
    
    @app.get("/health")
    async def health():
        return {
            "status": "healthy",
            "version": "2.0.0-minimal",
            "timestamp": datetime.utcnow().isoformat()
        }
    
    @app.post("/api/v1/auth/login")
    async def login(request: Request):
        try:
            body = await request.json()
            username = body.get("username")
            password = body.get("password")
            
            if not username or not password:
                raise HTTPException(status_code=400, detail="Username and password required")
            
            user = authenticate_user(username, password)
            if not user:
                raise HTTPException(status_code=401, detail="Incorrect username or password")
            
            access_token = create_access_token({"sub": user["username"]})
            refresh_token = create_access_token({"sub": user["username"], "type": "refresh"})
            
            return {
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "bearer"
            }
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
    
    @app.get("/api/v1/auth/me")
    async def get_user(request: Request):
        try:
            auth_header = request.headers.get("authorization")
            if not auth_header or not auth_header.startswith("Bearer "):
                raise HTTPException(status_code=401, detail="Missing or invalid authorization header")
            
            token = auth_header.split(" ")[1]
            payload = verify_token(token)
            username = payload.get("sub")
            
            user = fake_users_db.get(username)
            if not user:
                raise HTTPException(status_code=401, detail="User not found")
            
            return {
                "id": user["id"],
                "username": user["username"],
                "email": user["email"],
                "full_name": user["full_name"],
                "is_active": user["is_active"],
                "created_at": user["created_at"]
            }
            
        except ValueError as e:
            raise HTTPException(status_code=401, detail=str(e))
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
    
    @app.post("/api/v1/auth/logout")
    async def logout():
        return {"message": "Successfully logged out"}

# Função principal
if __name__ == "__main__":
    import sys
    python_version_info = sys.version_info
    
    print("🚀 PG Analytics API Ultra-Minimal")
    print("=" * 50)
    print(f"🐍 Python: {python_version_info.major}.{python_version_info.minor}.{python_version_info.micro}")
    print(f"📦 FastAPI: {'✅' if FASTAPI_AVAILABLE else '❌'}")
    print(f"🔑 JWT: {'✅' if JWT_AVAILABLE else '❌ (usando implementação simples)'}")
    print(f"🔒 bcrypt: {'✅' if BCRYPT_AVAILABLE else '❌ (usando hash simples)'}")
    print(f"🌐 Uvicorn: {'✅' if UVICORN_AVAILABLE else '❌'}")
    print("")
    print("👤 Usuários de teste:")
    for username in fake_users_db.keys():
        print(f"   • {username} / senha: {username}")
    print("")
    
    if FASTAPI_AVAILABLE and UVICORN_AVAILABLE:
        print("🌐 Iniciando servidor FastAPI...")
        print("   • API: http://localhost:8000")
        print("   • Docs: http://localhost:8000/docs")
        print("   • Health: http://localhost:8000/health")
        print("")
        print("🛑 Para parar: Ctrl+C")
        print("=" * 50)
        
        uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
    else:
        print("❌ FastAPI ou Uvicorn não disponível!")
        print("💡 Instale manualmente: pip install fastapi uvicorn")
        print("")
        print("🔧 Ou execute um servidor HTTP simples:")
        print("   python -m http.server 8000")
