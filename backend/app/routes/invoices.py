from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Response, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.invoice import InvoiceCreate, InvoiceUpdate, InvoiceResponse
from app.utils.id_generator import generate_entity_id
from app.services.finance_service import calculate_invoice_totals, recalculate_invoice_payments
from app.services.pdf_service import generate_invoice_pdf
from app.services.audit_service import log_audit_event

router = APIRouter(prefix="/invoices", tags=["Invoices"])

@router.get("", response_model=List[InvoiceResponse])
async def list_invoices(
    client_id: Optional[str] = None,
    project_id: Optional[str] = None,
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {"isDeleted": {"$ne": True}}
    if client_id:
        query["clientId"] = client_id
    if project_id:
        query["projectId"] = project_id
    if status and status != "All":
        query["status"] = status

    invoices = await db.invoices.find(query).sort("createdAt", -1).skip(skip).limit(limit).to_list(limit)
    return [InvoiceResponse(**inv) for inv in invoices]

@router.post("", response_model=InvoiceResponse, status_code=status.HTTP_201_CREATED)
async def create_invoice(
    inv_in: InvoiceCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    inv_id = await generate_entity_id("INV", "invoices")
    now = datetime.now(timezone.utc).isoformat()

    client = await db.clients.find_one({"id": inv_in.clientId})
    if not client:
        raise HTTPException(status_code=400, detail="Referenced client does not exist.")

    project_name = None
    if inv_in.projectId:
        proj = await db.projects.find_one({"id": inv_in.projectId})
        if proj:
            project_name = proj.get("projectName")

    items_list = [item.model_dump() for item in inv_in.items]
    for it in items_list:
        it["amount"] = round(float(it.get("quantity", 1)) * float(it.get("rate", 0)), 2)

    totals = calculate_invoice_totals(items_list, inv_in.discount, inv_in.taxRate)

    inv_doc = inv_in.model_dump()
    inv_doc.update({
        "id": inv_id,
        "invoiceNumber": inv_id,
        "clientName": client.get("clientName"),
        "businessName": client.get("businessName"),
        "projectName": project_name,
        "items": items_list,
        **totals,
        "paidAmount": 0.0,
        "balanceAmount": totals["total"],
        "pdfUrl": f"/api/invoices/{inv_id}/pdf",
        "createdBy": current_user["id"],
        "createdAt": now,
        "updatedAt": now,
        "isDeleted": False
    })

    await db.invoices.insert_one(inv_doc)

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CREATE_INVOICE",
        entity_type="INVOICE",
        entity_id=inv_id,
        description=f"Generated invoice {inv_id} for {client.get('businessName')} (Total: ₹{totals['total']})."
    )

    return InvoiceResponse(**inv_doc)

@router.get("/{invoice_id}", response_model=InvoiceResponse)
async def get_invoice(invoice_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    inv = await db.invoices.find_one({"id": invoice_id, "isDeleted": {"$ne": True}})
    if not inv:
        raise HTTPException(status_code=404, detail="Invoice not found.")
    return InvoiceResponse(**inv)

@router.get("/{invoice_id}/pdf")
async def download_invoice_pdf(invoice_id: str):
    db = get_database()
    inv = await db.invoices.find_one({"id": invoice_id})
    if not inv:
        raise HTTPException(status_code=404, detail="Invoice not found.")
    client = await db.clients.find_one({"id": inv.get("clientId")}) or {}
    pdf_bytes = generate_invoice_pdf(inv, client)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"inline; filename={invoice_id}.pdf"}
    )

@router.put("/{invoice_id}", response_model=InvoiceResponse)
async def update_invoice(
    invoice_id: str,
    update_data: InvoiceUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    existing = await db.invoices.find_one({"id": invoice_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Invoice not found.")

    update_fields = {k: v for k, v in update_data.model_dump().items() if v is not None}
    now = datetime.now(timezone.utc).isoformat()
    update_fields["updatedAt"] = now

    if "items" in update_fields or "discount" in update_fields or "taxRate" in update_fields:
        items = update_fields.get("items") or existing.get("items", [])
        for it in items:
            it["amount"] = round(float(it.get("quantity", 1)) * float(it.get("rate", 0)), 2)
        disc = update_fields.get("discount", existing.get("discount", 0.0))
        tax_r = update_fields.get("taxRate", existing.get("taxRate", 0.0))
        totals = calculate_invoice_totals(items, disc, tax_r)
        update_fields.update(totals)
        update_fields["items"] = items

    res = await db.invoices.find_one_and_update(
        {"id": invoice_id},
        {"$set": update_fields},
        return_document=True
    )

    # Automatically recompute balances and status
    await recalculate_invoice_payments(invoice_id)
    updated_inv = await db.invoices.find_one({"id": invoice_id})

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="UPDATE_INVOICE",
        entity_type="INVOICE",
        entity_id=invoice_id,
        description=f"Updated invoice {invoice_id}."
    )

    return InvoiceResponse(**updated_inv)
