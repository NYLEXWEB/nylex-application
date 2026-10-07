from typing import Optional
from pydantic import BaseModel, Field

class TaskCreate(BaseModel):
    projectId: str = Field(..., min_length=1)
    title: str = Field(..., min_length=1)
    description: Optional[str] = None
    assignedTo: Optional[str] = None
    priority: str = "Medium"  # Low, Medium, High, Urgent
    dueDate: Optional[str] = None
    status: str = "Todo"      # Todo, In Progress, Completed, Blocked

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    assignedTo: Optional[str] = None
    priority: Optional[str] = None
    dueDate: Optional[str] = None
    status: Optional[str] = None

class TaskResponse(BaseModel):
    id: str
    projectId: str
    projectName: Optional[str] = None
    title: str
    description: Optional[str] = None
    assignedTo: Optional[str] = None
    assignedToName: Optional[str] = None
    priority: str
    dueDate: Optional[str] = None
    status: str
    createdBy: Optional[str] = None
    createdAt: str
    updatedAt: str
