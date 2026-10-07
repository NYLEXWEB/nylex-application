from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.notification import NotificationResponse

router = APIRouter(prefix="/notifications", tags=["Notifications"])

@router.get("", response_model=List[NotificationResponse])
async def list_notifications(
    unread_only: bool = False,
    limit: int = 50,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query = {"userId": current_user["id"]}
    if unread_only:
        query["isRead"] = False

    notifications = await db.notifications.find(query).sort("createdAt", -1).limit(limit).to_list(limit)
    return [NotificationResponse(**n) for n in notifications]

@router.put("/{notif_id}/read")
async def mark_notification_read(
    notif_id: str,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    res = await db.notifications.update_one(
        {"id": notif_id, "userId": current_user["id"]},
        {"$set": {"isRead": True}}
    )
    if res.matched_count == 0:
        raise HTTPException(status_code=404, detail="Notification not found.")
    return {"message": "Notification marked as read."}

@router.put("/read-all")
async def mark_all_notifications_read(current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    await db.notifications.update_many(
        {"userId": current_user["id"], "isRead": False},
        {"$set": {"isRead": True}}
    )
    return {"message": "All notifications marked as read."}

@router.get("/unread-count")
async def get_unread_notification_count(current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    count = await db.notifications.count_documents({
        "userId": current_user["id"],
        "isRead": False
    })
    return {"unreadCount": count}
