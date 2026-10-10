from datetime import datetime, timedelta, timezone
from typing import Optional, Any
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security_bearer = HTTPBearer(auto_error=False)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_ACCESS_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_REFRESH_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def decode_token(token: str, is_refresh: bool = False) -> dict:
    secret = settings.JWT_REFRESH_SECRET if is_refresh else settings.JWT_SECRET
    try:
        payload = jwt.decode(token, secret, algorithms=[settings.JWT_ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session expired or invalid credentials. Please login again.",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_bearer)
) -> dict:
    from app.core.database import get_database
    db = get_database()

    # 1. If credentials provided, validate token
    if credentials and credentials.credentials:
        try:
            token = credentials.credentials
            payload = decode_token(token, is_refresh=False)
            user_id = payload.get("sub")
            if user_id:
                user = await db.users.find_one({"id": user_id, "isDeleted": {"$ne": True}})
                if user and user.get("isActive", True):
                    return user
        except Exception:
            pass

    # 2. Seamless Direct Access: Fallback to Admin owner user so all operations work without login
    try:
        admin_user = await db.users.find_one({
            "$or": [{"email": "admin"}, {"role": "OWNER"}, {"id": "USR-ADMIN"}],
            "isDeleted": {"$ne": True}
        })
        if admin_user:
            return admin_user
    except Exception:
        pass

    return {
        "id": "USR-ADMIN",
        "name": "Admin (Owner)",
        "email": "admin",
        "role": "OWNER",
        "isActive": True
    }

async def get_current_active_user(
    current_user: dict = Depends(get_current_user)
) -> dict:
    return current_user

def require_roles(*allowed_roles: str):
    def role_checker(user: dict = Depends(get_current_active_user)):
        user_role = user.get("role", "")
        if user_role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden: Insufficient permissions for role {user_role}.",
            )
        return user
    return role_checker
