from typing import List, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import get_current_active_user, require_roles
from app.schemas.user import UserResponse, UserUpdateRequest
from app.websocket.connection_manager import manager

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("", response_model=List[UserResponse])
async def list_users(current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    users = await db.users.find({"isDeleted": {"$ne": True}}).to_list(100)
    return [UserResponse(**u) for u in users]

@router.get("/presence")
async def get_presence(current_user: dict = Depends(get_current_active_user)) -> Dict[str, bool]:
    db = get_database()
    users = await db.users.find({"isDeleted": {"$ne": True}}).to_list(10)
    return {u["id"]: manager.is_user_online(u["id"]) for u in users}

@router.get("/{user_id}", response_model=UserResponse)
async def get_user_by_id(user_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    user = await db.users.find_one({"id": user_id, "isDeleted": {"$ne": True}})
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")
    return UserResponse(**user)

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: str,
    update_data: UserUpdateRequest,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    update_fields = {k: v for k, v in update_data.model_dump().items() if v is not None}
    update_fields["updatedAt"] = datetime.now(timezone.utc).isoformat()

    res = await db.users.find_one_and_update(
        {"id": user_id},
        {"$set": update_fields},
        return_document=True
    )
    if not res:
        raise HTTPException(status_code=404, detail="User not found.")
    return UserResponse(**res)
