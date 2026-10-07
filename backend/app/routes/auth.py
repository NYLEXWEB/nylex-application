from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import (
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    get_current_active_user,
)
from app.schemas.user import UserLoginRequest, TokenResponse, RefreshTokenRequest, UserResponse
from app.services.audit_service import log_audit_event

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=TokenResponse)
async def login(login_data: UserLoginRequest):
    db = get_database()
    user = await db.users.find_one({"email": login_data.email.lower(), "isDeleted": {"$ne": True}})
    if not user or not verify_password(login_data.password, user.get("hashedPassword", "")):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )
    if not user.get("isActive", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated. Contact admin.",
        )

    now = datetime.now(timezone.utc).isoformat()
    await db.users.update_one({"id": user["id"]}, {"$set": {"lastLoginAt": now}})
    user["lastLoginAt"] = now

    token_payload = {"sub": user["id"], "role": user.get("role", "PARTNER"), "email": user["email"]}
    access_token = create_access_token(token_payload)
    refresh_token = create_refresh_token(token_payload)

    await log_audit_event(
        user_id=user["id"],
        user_name=user["name"],
        action="LOGIN",
        entity_type="USER",
        entity_id=user["id"],
        description=f"User {user['name']} logged in successfully."
    )

    return TokenResponse(
        accessToken=access_token,
        refreshToken=refresh_token,
        user=UserResponse(**user)
    )

@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(request: RefreshTokenRequest):
    payload = decode_token(request.refreshToken, is_refresh=True)
    user_id = payload.get("sub")
    db = get_database()
    user = await db.users.find_one({"id": user_id, "isDeleted": {"$ne": True}})
    if not user or not user.get("isActive", True):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token or inactive user.")

    token_payload = {"sub": user["id"], "role": user.get("role", "PARTNER"), "email": user["email"]}
    new_access_token = create_access_token(token_payload)
    new_refresh_token = create_refresh_token(token_payload)

    return TokenResponse(
        accessToken=new_access_token,
        refreshToken=new_refresh_token,
        user=UserResponse(**user)
    )

@router.post("/logout")
async def logout(current_user: dict = Depends(get_current_active_user)):
    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="LOGOUT",
        entity_type="USER",
        entity_id=current_user["id"],
        description=f"User {current_user['name']} logged out."
    )
    return {"message": "Logged out successfully."}

@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(current_user: dict = Depends(get_current_active_user)):
    return UserResponse(**current_user)
