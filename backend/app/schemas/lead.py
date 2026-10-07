from typing import Optional
from pydantic import BaseModel, EmailStr, Field

class LeadCreate(BaseModel):
    name: str = Field(..., min_length=1)
    businessName: Optional[str] = None
    phone: str = Field(..., min_length=5)
    whatsapp: Optional[str] = None
    email: Optional[EmailStr] = None
    location: Optional[str] = None
    serviceRequired: Optional[str] = None
    expectedBudget: Optional[float] = 0.0
    leadSource: str = "Direct"  # Instagram, WhatsApp, Facebook, Website, Referral, Direct, Existing Client, Other
    assignedTo: Optional[str] = None
    priority: str = "Medium"    # Low, Medium, High, Urgent
    status: str = "New"         # New, Contacted, Follow-up, Proposal, Negotiation, Won, Lost
    notes: Optional[str] = None
    nextFollowUp: Optional[str] = None

class LeadUpdate(BaseModel):
    name: Optional[str] = None
    businessName: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    email: Optional[EmailStr] = None
    location: Optional[str] = None
    serviceRequired: Optional[str] = None
    expectedBudget: Optional[float] = None
    leadSource: Optional[str] = None
    assignedTo: Optional[str] = None
    priority: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None
    nextFollowUp: Optional[str] = None

class LeadStatusUpdate(BaseModel):
    status: str
    notes: Optional[str] = None

class LeadConvertRequest(BaseModel):
    createProject: bool = True
    projectName: Optional[str] = None
    projectType: Optional[str] = None
    quotedAmount: Optional[float] = 0.0
    deadline: Optional[str] = None
    notes: Optional[str] = None

class LeadResponse(BaseModel):
    id: str
    name: str
    businessName: Optional[str] = None
    phone: str
    whatsapp: Optional[str] = None
    email: Optional[str] = None
    location: Optional[str] = None
    serviceRequired: Optional[str] = None
    expectedBudget: float = 0.0
    leadSource: str
    assignedTo: Optional[str] = None
    assignedToName: Optional[str] = None
    priority: str
    status: str
    notes: Optional[str] = None
    nextFollowUp: Optional[str] = None
    convertedClientId: Optional[str] = None
    convertedProjectId: Optional[str] = None
    createdBy: Optional[str] = None
    createdByName: Optional[str] = None
    createdAt: str
    updatedAt: str
    isDeleted: bool = False
