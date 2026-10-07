from typing import Optional, List
from pydantic import BaseModel, Field
from app.schemas.quotation import LineItemSchema

class InvoiceCreate(BaseModel):
    clientId: str
    projectId: Optional[str] = None
    invoiceDate: str
    dueDate: str
    items: List[LineItemSchema] = Field(default_factory=list)
    discount: float = 0.0
    taxRate: float = 0.0
    notes: Optional[str] = None
    status: str = "Draft"  # Draft, Sent, Partially Paid, Paid, Overdue, Cancelled

class InvoiceUpdate(BaseModel):
    invoiceDate: Optional[str] = None
    dueDate: Optional[str] = None
    items: Optional[List[LineItemSchema]] = None
    discount: Optional[float] = None
    taxRate: Optional[float] = None
    notes: Optional[str] = None
    status: Optional[str] = None

class InvoiceResponse(BaseModel):
    id: str
    invoiceNumber: str
    clientId: str
    clientName: Optional[str] = None
    businessName: Optional[str] = None
    projectId: Optional[str] = None
    projectName: Optional[str] = None
    invoiceDate: str
    dueDate: str
    items: List[LineItemSchema]
    subtotal: float
    discount: float
    tax: float
    taxRate: float
    total: float
    paidAmount: float = 0.0
    balanceAmount: float = 0.0
    status: str
    notes: Optional[str] = None
    pdfUrl: Optional[str] = None
    createdBy: Optional[str] = None
    createdAt: str
    updatedAt: str
    isDeleted: bool = False
