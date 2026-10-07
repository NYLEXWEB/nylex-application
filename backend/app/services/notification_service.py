import logging
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List
from app.core.database import get_database
from app.utils.id_generator import generate_uuid

logger = logging.getLogger("nylex.notifications")

async def create_notification(
    user_id: str,
    title: str,
    message: str,
    notification_type: str,
    related_entity_type: Optional[str] = None,
    related_entity_id: Optional[str] = None,
    metadata: Optional[Dict[str, Any]] = None
):
    """
    Creates an in-app notification and dispatches to WebSocket if user is connected.
    """
    try:
        db = get_database()
        now = datetime.now(timezone.utc).isoformat()
        notif_id = generate_uuid("NOT-")
        notification = {
            "id": notif_id,
            "userId": user_id,
            "title": title,
            "message": message,
            "type": notification_type,
            "relatedEntityType": related_entity_type,
            "relatedEntityId": related_entity_id,
            "isRead": False,
            "createdAt": now,
            "metadata": metadata or {},
        }
        await db.notifications.insert_one(notification)
        
        # Dispatch via WebSocket if active
        try:
            from app.websocket.connection_manager import manager
            await manager.send_personal_message(
                user_id,
                {
                    "type": "notification",
                    "data": {
                        "id": notif_id,
                        "title": title,
                        "message": message,
                        "notificationType": notification_type,
                        "relatedEntityType": related_entity_type,
                        "relatedEntityId": related_entity_id,
                        "createdAt": now,
                    }
                }
            )
        except Exception as ws_err:
            logger.debug(f"User {user_id} not connected to WebSocket for instant notification: {ws_err}")

        return notification
    except Exception as e:
        logger.error(f"Failed to create notification: {e}")
        return None

async def broadcast_notification(
    title: str,
    message: str,
    notification_type: str,
    related_entity_type: Optional[str] = None,
    related_entity_id: Optional[str] = None,
    exclude_user_id: Optional[str] = None
):
    """
    Broadcasts a notification to both NYLEX users (except sender if specified).
    """
    db = get_database()
    users = await db.users.find({"isDeleted": {"$ne": True}, "isActive": True}).to_list(10)
    for u in users:
        if exclude_user_id and u["id"] == exclude_user_id:
            continue
        await create_notification(
            user_id=u["id"],
            title=title,
            message=message,
            notification_type=notification_type,
            related_entity_type=related_entity_type,
            related_entity_id=related_entity_id,
        )
