# backend/app/services/auth_service.py
from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException, status
from datetime import datetime, timedelta
from typing import Optional
from app.models.user import User, UserRole
from app.schemas.auth import UserCreate, LoginRequest, TokenData
from app.core.security import (
    verify_password, 
    get_password_hash, 
    create_access_token, 
    create_refresh_token,
    verify_token,
    ACCESS_TOKEN_EXPIRE_MINUTES
)

try:
    import redis
    redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)
except:
    redis_client = None

class AuthService:
    
    @staticmethod
    def create_user(db: Session, user_data: UserCreate) -> User:
        """Criar novo usuário"""
        
        # Verificar se username já existe
        if db.query(User).filter(User.username == user_data.username).first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already registered"
            )
        
        # Verificar se email já existe
        if db.query(User).filter(User.email == user_data.email).first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Criar usuário
        hashed_password = get_password_hash(user_data.password)
        
        db_user = User(
            username=user_data.username,
            email=user_data.email,
            full_name=user_data.full_name,
            role=user_data.role,
            hashed_password=hashed_password,
            is_active=True,
            is_verified=False
        )
        
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        return db_user
    
    @staticmethod
    def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
        """Autenticar usuário"""
        user = db.query(User).filter(
            (User.username == username) | (User.email == username)
        ).first()
        
        if not user:
            return None
            
        if not user.verify_password(password):
            return None
            
        # Atualizar last_login
        user.last_login = datetime.utcnow()
        db.commit()
        
        return user
    
    @staticmethod
    def create_tokens(user: User) -> dict:
        """Criar tokens de acesso e refresh"""
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        # Dados para o token
        token_data = {
            "sub": user.username,
            "user_id": user.id,
            "role": user.role.value,
            "email": user.email
        }
        
        access_token = create_access_token(
            data=token_data,
            expires_delta=access_token_expires
        )
        
        refresh_token = create_refresh_token(data=token_data)
        
        # Salvar refresh token no Redis (se disponível)
        if redis_client:
            try:
                redis_client.setex(
                    f"refresh_token:{user.id}",
                    timedelta(days=7),
                    refresh_token
                )
            except:
                pass
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
    
    @staticmethod
    def refresh_access_token(refresh_token: str, db: Session) -> dict:
        """Refresh access token"""
        payload = verify_token(refresh_token, "refresh")
        
        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        user_id = payload.get("user_id")
        
        # Verificar se refresh token existe no Redis (se disponível)
        if redis_client:
            try:
                stored_token = redis_client.get(f"refresh_token:{user_id}")
                if stored_token != refresh_token:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Invalid refresh token"
                    )
            except:
                pass
        
        # Buscar usuário
        user = db.query(User).filter(User.id == user_id).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )
        
        # Criar novos tokens
        return AuthService.create_tokens(user)
    
    @staticmethod
    def logout_user(user_id: int, access_token: str):
        """Logout do usuário"""
        if redis_client:
            try:
                # Adicionar access token à blacklist
                payload = verify_token(access_token, "access")
                if payload:
                    exp = payload.get("exp")
                    if exp:
                        import time
                        ttl = exp - int(time.time())
                        if ttl > 0:
                            redis_client.setex(f"blacklist:{access_token}", ttl, "true")
                
                # Remover refresh token
                redis_client.delete(f"refresh_token:{user_id}")
            except:
                pass
    
    @staticmethod
    def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
        """Buscar usuário por ID"""
        return db.query(User).filter(User.id == user_id).first()
    
    @staticmethod
    def get_users(db: Session, skip: int = 0, limit: int = 100):
        """Listar usuários"""
        return db.query(User).offset(skip).limit(limit).all()
    
    @staticmethod
    def update_user(db: Session, user_id: int, user_data: dict) -> User:
        """Atualizar usuário"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        for field, value in user_data.items():
            if hasattr(user, field) and value is not None:
                setattr(user, field, value)
        
        user.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(user)
        
        return user
    
    @staticmethod
    def delete_user(db: Session, user_id: int):
        """Deletar usuário"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        db.delete(user)
        db.commit()
        
        # Remover tokens do Redis
        if redis_client:
            try:
                redis_client.delete(f"refresh_token:{user_id}")
            except:
                pass
        
        return {"message": "User deleted successfully"}
    
    @staticmethod
    def change_password(db: Session, user: User, current_password: str, new_password: str):
        """Alterar senha do usuário"""
        if not user.verify_password(current_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect"
            )
        
        user.hashed_password = get_password_hash(new_password)
        user.updated_at = datetime.utcnow()
        db.commit()
        
        # Invalidar todos os tokens do usuário
        if redis_client:
            try:
                redis_client.delete(f"refresh_token:{user.id}")
            except:
                pass
        
        return {"message": "Password changed successfully"}
