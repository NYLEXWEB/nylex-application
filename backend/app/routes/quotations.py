from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Response, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.quotation import QuotationCreate, QuotationUpdate, QuotationResponse
from app.utils.id_generator import generate_entity_id
from app.services.finance_service import calculate_invoice_totals
from app.services.pdf_service import generate_quotation_pdf
from app.services.audit_service import log_audit_event

router = APIRouter(prefix="/quotations", tags=["Quotations"])

@router.get("", response_model=List[QuotationResponse])
async def list_quotations(
    client_id: Optional[str] = None,
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {"isDeleted": {"$ne": True}}
    if client_id:
        query["clientId"] = client_id
    if status and status != "All":
        query["status"] = status

    quotations = await db.quotations.find(query).sort("createdAt", -1).skip(skip).limit(limit).to_list(limit)
    return [QuotationResponse(**q) for q in quotations]

@router.post("", response_model=QuotationResponse, status_code=status.HTTP_201_CREATED)
async def create_quotation(
    quo_in: QuotationCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    quo_id = await generate_entity_id("QT", "quotations")
    now = datetime.now(timezone.utc).isoformat()

    client = await db.clients.find_one({"id": quo_in.clientId})
    if not client:
        raise HTTPException(status_code=400, detail="Referenced client does not exist.")

    project_name = None
    if quo_in.projectId:
        proj = await db.projects.find_one({"id": quo_in.projectId})
        if proj:
            project_name = proj.get("projectName")

    items_list = [item.model_dump() for item in quo_in.items]
    for it in items_list:
        it["amount"] = round(float(it.get("quantity", 1)) * float(it.get("rate", 0)), 2)

    totals = calculate_invoice_totals(items_list, quo_in.discount, quo_in.taxRate)

    quo_doc = quo_in.model_dump()
    quo_doc.update({
        "id": quo_id,
        "quotationNumber": quo_id,
        "clientName": client.get("clientName"),
        "businessName": client.get("businessName"),
        "projectName": project_name,
        "items": items_list,
        **totals,
        "pdfUrl": f"/api/quotations/{quo_id}/pdf",
        "createdBy": current_user["id"],
        "createdAt": now,
        "updatedAt": now,
        "isDeleted": False
    })

    await db.quotations.insert_one(quo_doc)

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CREATE_QUOTATION",
        entity_type="QUOTATION",
        entity_id=quo_id,
        description=f"Created quotation {quo_id} for {client.get('businessName')} (Total: ₹{totals['total']})."
    )

    return QuotationResponse(**quo_doc)

@router.get("/{quotation_id}", response_model=QuotationResponse)
async def get_quotation(quotation_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    quo = await db.quotations.find_one({"id": quotation_id, "isDeleted": {"$ne": True}})
    if not quo:
        raise HTTPException(status_code=404, detail="Quotation not found.")
    return QuotationResponse(**quo)

@router.get("/{quotation_id}/pdf")
async def download_quotation_pdf(quotation_id: str):
    db = get_database()
    quo = await db.quotations.find_one({"id": quotation_id})
    if not quo:
        raise HTTPException(status_code=404, detail="Quotation not found.")
    client = await db.clients.find_one({"id": quo.get("clientId")}) or {}
    pdf_bytes = generate_quotation_pdf(quo, client)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"inline; filename={quotation_id}.pdf"}
    )

@router.put("/{quotation_id}", response_model=QuotationResponse)
async def update_quotation(
    quotation_id: str,
    update_data: QuotationUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    existing = await db.quotations.find_one({"id": quotation_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Quotation not found.")

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

    res = await db.quotations.find_one_and_update(
        {"id": quotation_id},
        {"$set": update_fields},
        return_document=True
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="UPDATE_QUOTATION",
        entity_type="QUOTATION",
        entity_id=quotation_id,
        description=f"Updated quotation {quotation_id} (Status: {res.get('status')})."
    )

    return QuotationResponse(**res)
