from typing import Optional, List
from pydantic import BaseModel, Field

class LineItemSchema(BaseModel):
    description: str
    quantity: float = 1.0
    rate: float = 0.0
    amount: float = 0.0

class QuotationCreate(BaseModel):
    clientId: str
    projectId: Optional[str] = None
    quotationDate: str
    validUntil: Optional[str] = None
    items: List[LineItemSchema] = Field(default_factory=list)
    discount: float = 0.0
    taxRate: float = 0.0
    notes: Optional[str] = None
    status: str = "Draft"  # Draft, Sent, Accepted, Rejected, Expired

class QuotationUpdate(BaseModel):
    quotationDate: Optional[str] = None
    validUntil: Optional[str] = None
    items: Optional[List[LineItemSchema]] = None
    discount: Optional[float] = None
    taxRate: Optional[float] = None
    notes: Optional[str] = None
    status: Optional[str] = None

class QuotationResponse(BaseModel):
    id: str
    quotationNumber: str
    clientId: str
    clientName: Optional[str] = None
    businessName: Optional[str] = None
    projectId: Optional[str] = None
    projectName: Optional[str] = None
    quotationDate: str
    validUntil: Optional[str] = None
    items: List[LineItemSchema]
    subtotal: float
    discount: float
    tax: float
    taxRate: float
    total: float
    notes: Optional[str] = None
    status: str
    pdfUrl: Optional[str] = None
    createdBy: Optional[str] = None
    createdAt: str
    updatedAt: str
    isDeleted: bool = False
