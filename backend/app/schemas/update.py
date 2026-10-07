from typing import Optional
from pydantic import BaseModel, Field

class DailyUpdateCreate(BaseModel):
    projectId: str = Field(..., min_length=1)
    updateText: str = Field(..., min_length=1)
    completedSection: Optional[str] = None
    nextSection: Optional[str] = None
    blockerSection: Optional[str] = None
    date: Optional[str] = None  # YYYY-MM-DD

class DailyUpdateResponse(BaseModel):
    id: str
    projectId: str
    projectName: Optional[str] = None
    userId: str
    userName: Optional[str] = None
    updateText: str
    completedSection: Optional[str] = None
    nextSection: Optional[str] = None
    blockerSection: Optional[str] = None
    date: str
    createdAt: str
