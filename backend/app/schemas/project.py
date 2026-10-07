from typing import Optional, List
from pydantic import BaseModel, Field
from app.schemas.client import DomainInfoSchema

class DeliveryInfoSchema(BaseModel):
    deliveryDate: Optional[str] = None
    finalPaymentStatus: Optional[str] = "Pending"  # Paid, Pending, Partial
    supportStartDate: Optional[str] = None
    domainInfo: Optional[DomainInfoSchema] = None
    notes: Optional[str] = None

class ProjectCreate(BaseModel):
    projectName: str = Field(..., min_length=1)
    clientId: str = Field(..., min_length=1)
    projectType: str = "Website"
    description: Optional[str] = None
    quotedAmount: float = 0.0
    finalAmount: float = 0.0
    startDate: Optional[str] = None
    deadline: Optional[str] = None
    status: str = "Planning"  # Planning, In Progress, Review, Completed, Delivered, On Hold, Cancelled
    priority: str = "Medium"   # Low, Medium, High, Urgent
    assignedUsers: List[str] = Field(default_factory=list)
    domainInfo: Optional[DomainInfoSchema] = None

class ProjectUpdate(BaseModel):
    projectName: Optional[str] = None
    projectType: Optional[str] = None
    description: Optional[str] = None
    quotedAmount: Optional[float] = None
    finalAmount: Optional[float] = None
    startDate: Optional[str] = None
    deadline: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    assignedUsers: Optional[List[str]] = None
    domainInfo: Optional[DomainInfoSchema] = None
    deliveryInfo: Optional[DeliveryInfoSchema] = None

class ProjectDeliveryUpdate(BaseModel):
    deliveryDate: str
    supportStartDate: Optional[str] = None
    domainInfo: Optional[DomainInfoSchema] = None
    notes: Optional[str] = None

class ProjectResponse(BaseModel):
    id: str
    projectName: str
    clientId: str
    clientName: Optional[str] = None
    businessName: Optional[str] = None
    projectType: str
    description: Optional[str] = None
    quotedAmount: float = 0.0
    finalAmount: float = 0.0
    totalPaid: float = 0.0
    balanceDue: float = 0.0
    startDate: Optional[str] = None
    deadline: Optional[str] = None
    status: str
    priority: str
    assignedUsers: List[str] = Field(default_factory=list)
    assignedUserNames: List[str] = Field(default_factory=list)
    domainInfo: Optional[DomainInfoSchema] = None
    deliveryInfo: Optional[DeliveryInfoSchema] = None
    createdBy: Optional[str] = None
    createdAt: str
    updatedAt: str
    isDeleted: bool = False
