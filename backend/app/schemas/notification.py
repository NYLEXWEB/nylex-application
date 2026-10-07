from typing import Optional, Dict, Any
from pydantic import BaseModel

class NotificationResponse(BaseModel):
    id: str
    userId: str
    title: str
    message: str
    type: str
    relatedEntityType: Optional[str] = None
    relatedEntityId: Optional[str] = None
    isRead: bool = False
    createdAt: str
    metadata: Optional[Dict[str, Any]] = None
