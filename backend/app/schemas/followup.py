from typing import Optional
from pydantic import BaseModel, Field

class FollowupCreate(BaseModel):
    leadId: Optional[str] = None
    clientId: Optional[str] = None
    scheduledDate: str = Field(..., description="YYYY-MM-DD")
    scheduledTime: str = Field(..., description="HH:MM")
    method: str = "Call"  # Call, WhatsApp, Email, Meeting, Other
    notes: Optional[str] = None
    assignedTo: Optional[str] = None
    reminderMinutesBefore: int = 15  # 15, 30, 60
    status: str = "Pending"  # Pending, Completed, Cancelled, Rescheduled

class FollowupUpdate(BaseModel):
    scheduledDate: Optional[str] = None
    scheduledTime: Optional[str] = None
    method: Optional[str] = None
    notes: Optional[str] = None
    assignedTo: Optional[str] = None
    reminderMinutesBefore: Optional[int] = None
    status: Optional[str] = None

class FollowupResponse(BaseModel):
    id: str
    leadId: Optional[str] = None
    leadName: Optional[str] = None
    leadBusiness: Optional[str] = None
    clientId: Optional[str] = None
    clientName: Optional[str] = None
    scheduledDate: str
    scheduledTime: str
    method: str
    notes: Optional[str] = None
    assignedTo: Optional[str] = None
    assignedToName: Optional[str] = None
    reminderMinutesBefore: int = 15
    status: str
    createdBy: Optional[str] = None
    createdAt: str
    updatedAt: str
