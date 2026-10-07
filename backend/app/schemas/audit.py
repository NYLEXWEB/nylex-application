from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict, Field

class AuditLogCreate(BaseModel):
    userId: str
    userName: str
    action: str
    entityType: str
    entityId: str
    description: str
    details: Optional[Dict[str, Any]] = Field(default=None)

class AuditLogResponse(BaseModel):
    model_config = ConfigDict(extra="ignore", from_attributes=True)

    id: str
    userId: str
    userName: str
    action: str
    entityType: str
    entityId: str
    description: str
    timestamp: str
    details: Optional[Dict[str, Any]] = Field(default=None)
