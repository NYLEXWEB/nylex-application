from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect, HTTPException, Query, status
from app.core.database import get_database
from app.core.security import get_current_active_user, decode_token
from app.schemas.chat import ChatMessageCreate, ChatMessageResponse
from app.utils.id_generator import generate_uuid
from app.websocket.connection_manager import manager
from app.services.notification_service import create_notification

router = APIRouter(prefix="/chat", tags=["Internal Chat"])

@router.get("/messages", response_model=List[ChatMessageResponse])
async def get_messages(
    chat_type: str = "general",
    project_id: Optional[str] = None,
    limit: int = 100,
    skip: int = 0,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {"chatType": chat_type}
    if chat_type == "project" and project_id:
        query["projectId"] = project_id

    messages = await db.messages.find(query).sort("createdAt", -1).skip(skip).limit(limit).to_list(limit)
    messages.reverse()  # oldest first for chat flow
    return [ChatMessageResponse(**m) for m in messages]

@router.post("/messages", response_model=ChatMessageResponse, status_code=status.HTTP_201_CREATED)
async def send_message(
    msg_in: ChatMessageCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    msg_id = generate_uuid("MSG-")
    now = datetime.now(timezone.utc).isoformat()

    msg_doc = msg_in.model_dump()
    msg_doc.update({
        "id": msg_id,
        "senderId": current_user["id"],
        "senderName": current_user["name"],
        "isRead": False,
        "createdAt": now,
    })

    await db.messages.insert_one(msg_doc)

    # Broadcast message via WebSocket
    await manager.broadcast({
        "type": "new_message",
        "message": msg_doc
    })

    # If recipient specified or in general chat, notify offline partner
    other_users = await db.users.find({"id": {"$ne": current_user["id"]}, "isDeleted": {"$ne": True}}).to_list(5)
    for u in other_users:
        if not manager.is_user_online(u["id"]):
            await create_notification(
                user_id=u["id"],
                title=f"New Chat from {current_user['name']}",
                message=msg_in.message[:100],
                notification_type="CHAT_MESSAGE",
                related_entity_type="CHAT",
                related_entity_id=msg_id,
            )

    return ChatMessageResponse(**msg_doc)

@router.put("/read")
async def mark_messages_read(
    chat_type: str = "general",
    project_id: Optional[str] = None,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query = {
        "senderId": {"$ne": current_user["id"]},
        "chatType": chat_type,
        "isRead": False
    }
    if chat_type == "project" and project_id:
        query["projectId"] = project_id

    await db.messages.update_many(query, {"$set": {"isRead": True}})
    return {"message": "Messages marked as read."}

@router.get("/unread-count")
async def get_unread_count(current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    count = await db.messages.count_documents({
        "senderId": {"$ne": current_user["id"]},
        "isRead": False
    })
    return {"unreadCount": count}

@router.websocket("/ws/{user_id}")
async def websocket_chat_endpoint(websocket: WebSocket, user_id: str):
    await manager.connect(user_id, websocket)
    db = get_database()
    try:
        while True:
            data = await websocket.receive_json()
            event_type = data.get("type")
            
            if event_type == "send_message":
                msg_text = data.get("message", "").strip()
                if msg_text:
                    now = datetime.now(timezone.utc).isoformat()
                    user = await db.users.find_one({"id": user_id})
                    user_name = user.get("name") if user else "User"
                    msg_doc = {
                        "id": generate_uuid("MSG-"),
                        "senderId": user_id,
                        "senderName": user_name,
                        "recipientId": data.get("recipientId"),
                        "chatType": data.get("chatType", "general"),
                        "projectId": data.get("projectId"),
                        "message": msg_text,
                        "isRead": False,
                        "createdAt": now,
                    }
                    await db.messages.insert_one(msg_doc)
                    await manager.broadcast({
                        "type": "new_message",
                        "message": msg_doc
                    })
            elif event_type == "typing":
                await manager.broadcast({
                    "type": "typing",
                    "userId": user_id,
                    "isTyping": data.get("isTyping", False),
                    "chatType": data.get("chatType", "general"),
                    "projectId": data.get("projectId"),
                })
    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
        await manager.broadcast_status(user_id, is_online=False)
    except Exception as e:
        manager.disconnect(user_id, websocket)
