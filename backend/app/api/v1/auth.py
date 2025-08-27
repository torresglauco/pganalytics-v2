# backend/app/api/v1/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.core.dependencies import get_current_user, get_current_active_user, require_admin
from app.services.auth_service import AuthService
from app.models.user import User
from app.schemas.auth import (
    UserCreate, 
    UserResponse, 
    UserUpdate,
    LoginRequest, 
    Token, 
    RefreshTokenRequest,
    PasswordChange
)

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()

@router.post("/register", response_model=UserResponse)
async def register(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """Registrar novo usuário"""
    user = AuthService.create_user(db, user_data)
    return user

@router.post("/login", response_model=Token)
async def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    """Login do usuário"""
    user = AuthService.authenticate_user(
        db, 
        login_data.username, 
        login_data.password
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    tokens = AuthService.create_tokens(user)
    return tokens

@router.post("/refresh", response_model=Token)
async def refresh_token(
    token_data: RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    """Renovar access token"""
    tokens = AuthService.refresh_access_token(token_data.refresh_token, db)
    return tokens

@router.post("/logout")
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    current_user: User = Depends(get_current_active_user)
):
    """Logout do usuário"""
    AuthService.logout_user(current_user.id, credentials.credentials)
    return {"message": "Successfully logged out"}

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: User = Depends(get_current_active_user)
):
    """Obter informações do usuário atual"""
    return current_user

@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_data: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Atualizar informações do usuário atual"""
    # Usuário só pode alterar email e full_name
    allowed_fields = {"email", "full_name"}
    update_data = {k: v for k, v in user_data.dict(exclude_unset=True).items() 
                   if k in allowed_fields}
    
    updated_user = AuthService.update_user(db, current_user.id, update_data)
    return updated_user

@router.post("/change-password")
async def change_password(
    password_data: PasswordChange,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Alterar senha do usuário"""
    return AuthService.change_password(
        db, 
        current_user, 
        password_data.current_password, 
        password_data.new_password
    )

# Admin endpoints
@router.get("/users", response_model=List[UserResponse])
async def list_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Listar usuários (Admin only)"""
    users = AuthService.get_users(db, skip, limit)
    return users

@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Obter usuário por ID (Admin only)"""
    user = AuthService.get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return user

@router.put("/users/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int,
    user_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Atualizar usuário (Admin only)"""
    update_data = user_data.dict(exclude_unset=True)
    updated_user = AuthService.update_user(db, user_id, update_data)
    return updated_user

@router.delete("/users/{user_id}")
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    """Deletar usuário (Admin only)"""
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own account"
        )
    
    return AuthService.delete_user(db, user_id)
