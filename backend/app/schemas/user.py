from typing import Optional
from pydantic import BaseModel, Field

class UserLoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    accessToken: str
    refreshToken: str
    tokenType: str = "Bearer"
    user: "UserResponse"

class RefreshTokenRequest(BaseModel):
    refreshToken: str

class UserCreateRequest(BaseModel):
    name: str
    email: str
    phone: Optional[str] = None
    role: str = "PARTNER"  # OWNER, PARTNER
    password: str

class UserUpdateRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = None
    profilePhoto: Optional[str] = None
    isActive: Optional[bool] = None

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    phone: Optional[str] = None
    role: str
    profilePhoto: Optional[str] = None
    isActive: bool = True
    createdAt: Optional[str] = None
    updatedAt: Optional[str] = None
    lastLoginAt: Optional[str] = None

TokenResponse.model_rebuild()
