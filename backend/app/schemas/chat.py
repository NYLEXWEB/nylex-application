from typing import Optional
from pydantic import BaseModel, Field

class ChatMessageCreate(BaseModel):
    message: str = Field(..., min_length=1)
    recipientId: Optional[str] = None
    chatType: str = "general"  # "general" or "project"
    projectId: Optional[str] = None

class ChatMessageResponse(BaseModel):
    id: str
    senderId: str
    senderName: Optional[str] = None
    recipientId: Optional[str] = None
    chatType: str = "general"
    projectId: Optional[str] = None
    message: str
    isRead: bool = False
    createdAt: str
