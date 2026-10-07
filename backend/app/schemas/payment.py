from typing import Optional
from pydantic import BaseModel, Field

class PaymentCreate(BaseModel):
    clientId: str
    projectId: Optional[str] = None
    invoiceId: Optional[str] = None
    amount: float = Field(..., gt=0, description="Payment amount must be greater than zero")
    paymentDate: str
    paymentMethod: str = "UPI"  # UPI, Bank Transfer, Cash, Razorpay, Other
    paymentType: str = "Advance"  # Advance, Partial, Balance, Full
    referenceNumber: Optional[str] = None
    notes: Optional[str] = None

class PaymentResponse(BaseModel):
    id: str
    paymentNumber: str
    clientId: str
    clientName: Optional[str] = None
    businessName: Optional[str] = None
    projectId: Optional[str] = None
    projectName: Optional[str] = None
    invoiceId: Optional[str] = None
    invoiceNumber: Optional[str] = None
    amount: float
    paymentDate: str
    paymentMethod: str
    paymentType: str
    referenceNumber: Optional[str] = None
    notes: Optional[str] = None
    receivedBy: Optional[str] = None
    receivedByName: Optional[str] = None
    createdAt: str
