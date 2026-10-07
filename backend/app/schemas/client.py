from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field

class DomainInfoSchema(BaseModel):
    domainName: Optional[str] = None
    domainExtension: Optional[str] = None
    registrar: Optional[str] = None
    purchaseEmail: Optional[str] = None
    purchaseDate: Optional[str] = None
    expiryDate: Optional[str] = None

class ClientCreate(BaseModel):
    clientName: str = Field(..., min_length=1)
    businessName: str = Field(..., min_length=1)
    phone: str = Field(..., min_length=5)
    whatsapp: Optional[str] = None
    email: Optional[EmailStr] = None
    location: Optional[str] = None
    address: Optional[str] = None
    website: Optional[str] = None
    instagram: Optional[str] = None
    leadSource: Optional[str] = "Direct"
    assignedTo: Optional[str] = None
    notes: Optional[str] = None
    status: str = "Active"  # Active, Completed, Inactive
    domainInfo: Optional[DomainInfoSchema] = None

class ClientUpdate(BaseModel):
    clientName: Optional[str] = None
    businessName: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    email: Optional[EmailStr] = None
    location: Optional[str] = None
    address: Optional[str] = None
    website: Optional[str] = None
    instagram: Optional[str] = None
    leadSource: Optional[str] = None
    assignedTo: Optional[str] = None
    notes: Optional[str] = None
    status: Optional[str] = None
    domainInfo: Optional[DomainInfoSchema] = None

class ClientResponse(BaseModel):
    id: str
    clientName: str
    businessName: str
    phone: str
    whatsapp: Optional[str] = None
    email: Optional[str] = None
    location: Optional[str] = None
    address: Optional[str] = None
    website: Optional[str] = None
    instagram: Optional[str] = None
    leadSource: Optional[str] = None
    assignedTo: Optional[str] = None
    assignedToName: Optional[str] = None
    notes: Optional[str] = None
    status: str
    domainInfo: Optional[DomainInfoSchema] = None
    createdBy: Optional[str] = None
    createdByName: Optional[str] = None
    createdAt: str
    updatedAt: str
    isDeleted: bool = False
