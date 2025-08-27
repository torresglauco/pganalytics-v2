# backend/app/core/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import Optional
import redis
from app.core.database import get_db
from app.core.security import verify_token
from app.models.user import User, UserRole
from app.schemas.auth import TokenData

security = HTTPBearer()

try:
    redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)
except:
    redis_client = None

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Obter usuário atual do token JWT"""
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    token = credentials.credentials
    
    # Verificar se token está na blacklist (se Redis disponível)
    if redis_client:
        try:
            if redis_client.get(f"blacklist:{token}"):
                raise credentials_exception
        except:
            pass
    
    # Verificar token
    payload = verify_token(token, "access")
    if payload is None:
        raise credentials_exception
    
    username: str = payload.get("sub")
    user_id: int = payload.get("user_id")
    
    if username is None or user_id is None:
        raise credentials_exception
    
    # Buscar usuário no banco
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    return user

async def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Obter usuário ativo atual"""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    return current_user

def require_role(required_role: UserRole):
    """Decorator para exigir role específica"""
    def role_checker(current_user: User = Depends(get_current_active_user)):
        if current_user.role != required_role and current_user.role != UserRole.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Operation requires {required_role.value} role"
            )
        return current_user
    return role_checker

# Aliases para roles específicas
require_admin = require_role(UserRole.ADMIN)
require_dba = require_role(UserRole.DBA)

def blacklist_token(token: str):
    """Adicionar token à blacklist"""
    if redis_client:
        try:
            payload = verify_token(token, "access")
            if payload:
                exp = payload.get("exp")
                if exp:
                    import time
                    ttl = exp - int(time.time())
                    if ttl > 0:
                        redis_client.setex(f"blacklist:{token}", ttl, "true")
        except:
            pass
