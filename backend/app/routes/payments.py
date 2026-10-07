from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.payment import PaymentCreate, PaymentResponse
from app.utils.id_generator import generate_entity_id
from app.services.finance_service import recalculate_invoice_payments, recalculate_project_finances
from app.services.audit_service import log_audit_event
from app.services.notification_service import broadcast_notification

router = APIRouter(prefix="/payments", tags=["Payments"])

@router.get("", response_model=List[PaymentResponse])
async def list_payments(
    client_id: Optional[str] = None,
    project_id: Optional[str] = None,
    invoice_id: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {}
    if client_id:
        query["clientId"] = client_id
    if project_id:
        query["projectId"] = project_id
    if invoice_id:
        query["invoiceId"] = invoice_id

    payments = await db.payments.find(query).sort("paymentDate", -1).skip(skip).limit(limit).to_list(limit)
    return [PaymentResponse(**p) for p in payments]

@router.post("", response_model=PaymentResponse, status_code=status.HTTP_201_CREATED)
async def create_payment(
    pay_in: PaymentCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    pay_id = await generate_entity_id("PAY", "payments")
    now = datetime.now(timezone.utc).isoformat()

    client = await db.clients.find_one({"id": pay_in.clientId})
    if not client:
        raise HTTPException(status_code=400, detail="Referenced client does not exist.")

    project_name = None
    if pay_in.projectId:
        proj = await db.projects.find_one({"id": pay_in.projectId})
        if proj:
            project_name = proj.get("projectName")

    invoice_number = None
    if pay_in.invoiceId:
        inv = await db.invoices.find_one({"id": pay_in.invoiceId})
        if inv:
            invoice_number = inv.get("invoiceNumber")
            # If project ID was not supplied, inherit from invoice
            if not pay_in.projectId and inv.get("projectId"):
                pay_in.projectId = inv.get("projectId")

    pay_doc = pay_in.model_dump()
    pay_doc.update({
        "id": pay_id,
        "paymentNumber": pay_id,
        "clientName": client.get("clientName"),
        "businessName": client.get("businessName"),
        "projectName": project_name,
        "invoiceNumber": invoice_number,
        "receivedBy": current_user["id"],
        "receivedByName": current_user["name"],
        "createdAt": now,
    })

    await db.payments.insert_one(pay_doc)

    # 1. Recalculate Invoice financials if invoice linked
    if pay_in.invoiceId:
        await recalculate_invoice_payments(pay_in.invoiceId)

    # 2. Recalculate Project financials if project linked
    if pay_in.projectId:
        await recalculate_project_finances(pay_in.projectId)

    # 3. Audit log
    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="ADD_PAYMENT",
        entity_type="PAYMENT",
        entity_id=pay_id,
        description=f"Received payment of ₹{pay_in.amount:,.2f} via {pay_in.paymentMethod} ({pay_in.paymentType}) for {client.get('businessName')}."
    )

    # 4. Notify Partner
    await broadcast_notification(
        title=f"₹{pay_in.amount:,.2f} Payment Received",
        message=f"{current_user['name']} recorded payment from {client.get('businessName')}.",
        notification_type="PAYMENT_RECEIVED",
        related_entity_type="PAYMENT",
        related_entity_id=pay_id,
        exclude_user_id=current_user["id"]
    )

    return PaymentResponse(**pay_doc)

@router.get("/{payment_id}", response_model=PaymentResponse)
async def get_payment(payment_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    pay = await db.payments.find_one({"id": payment_id})
    if not pay:
        raise HTTPException(status_code=404, detail="Payment not found.")
    return PaymentResponse(**pay)
