from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.client import ClientCreate, ClientUpdate, ClientResponse
from app.utils.id_generator import generate_entity_id
from app.services.audit_service import log_audit_event
from app.services.notification_service import create_notification

router = APIRouter(prefix="/clients", tags=["Clients"])

@router.get("", response_model=List[ClientResponse])
async def list_clients(
    status: Optional[str] = None,
    search: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {"isDeleted": {"$ne": True}}
    if status and status != "All":
        query["status"] = status
    if search:
        query["$or"] = [
            {"clientName": {"$regex": search, "$options": "i"}},
            {"businessName": {"$regex": search, "$options": "i"}},
            {"phone": {"$regex": search, "$options": "i"}},
            {"email": {"$regex": search, "$options": "i"}},
        ]

    clients = await db.clients.find(query).sort("createdAt", -1).skip(skip).limit(limit).to_list(limit)
    return [ClientResponse(**c) for c in clients]

@router.post("", response_model=ClientResponse, status_code=status.HTTP_201_CREATED)
async def create_client(
    client_in: ClientCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    client_id = await generate_entity_id("CLT", "clients")
    now = datetime.now(timezone.utc).isoformat()
    
    # Resolve assigned user name if assigned
    assigned_name = None
    if client_in.assignedTo:
        assigned_user = await db.users.find_one({"id": client_in.assignedTo})
        if assigned_user:
            assigned_name = assigned_user.get("name")

    client_doc = client_in.model_dump()
    client_doc.update({
        "id": client_id,
        "assignedToName": assigned_name,
        "createdBy": current_user["id"],
        "createdByName": current_user["name"],
        "createdAt": now,
        "updatedAt": now,
        "isDeleted": False
    })

    await db.clients.insert_one(client_doc)

    # Audit & Notification
    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CREATE_CLIENT",
        entity_type="CLIENT",
        entity_id=client_id,
        description=f"Created client '{client_in.businessName}' ({client_in.clientName})."
    )

    if client_in.assignedTo and client_in.assignedTo != current_user["id"]:
        await create_notification(
            user_id=client_in.assignedTo,
            title="New Client Assigned",
            message=f"You have been assigned to client '{client_in.businessName}'.",
            notification_type="CLIENT_ASSIGNED",
            related_entity_type="CLIENT",
            related_entity_id=client_id,
        )

    return ClientResponse(**client_doc)

@router.get("/{client_id}", response_model=ClientResponse)
async def get_client(client_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    client = await db.clients.find_one({"id": client_id, "isDeleted": {"$ne": True}})
    if not client:
        raise HTTPException(status_code=404, detail="Client not found.")
    return ClientResponse(**client)

@router.put("/{client_id}", response_model=ClientResponse)
async def update_client(
    client_id: str,
    update_data: ClientUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    existing = await db.clients.find_one({"id": client_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Client not found.")

    update_fields = {k: v for k, v in update_data.model_dump().items() if v is not None}
    now = datetime.now(timezone.utc).isoformat()
    update_fields["updatedAt"] = now

    if "assignedTo" in update_fields and update_fields["assignedTo"]:
        assigned_user = await db.users.find_one({"id": update_fields["assignedTo"]})
        update_fields["assignedToName"] = assigned_user.get("name") if assigned_user else None

    res = await db.clients.find_one_and_update(
        {"id": client_id},
        {"$set": update_fields},
        return_document=True
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="UPDATE_CLIENT",
        entity_type="CLIENT",
        entity_id=client_id,
        description=f"Updated details for client '{res.get('businessName')}'.",
        details=update_fields
    )

    return ClientResponse(**res)

@router.delete("/{client_id}")
async def delete_client(client_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    existing = await db.clients.find_one({"id": client_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Client not found.")

    now = datetime.now(timezone.utc).isoformat()
    await db.clients.update_one(
        {"id": client_id},
        {"$set": {"isDeleted": True, "deletedAt": now, "deletedBy": current_user["id"]}}
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="ARCHIVE_CLIENT",
        entity_type="CLIENT",
        entity_id=client_id,
        description=f"Archived client '{existing.get('businessName')}'."
    )
    return {"message": "Client archived successfully."}

@router.get("/{client_id}/timeline")
async def get_client_timeline(client_id: str, current_user: dict = Depends(get_current_active_user)):
    """
    Section 12: Combines activities from:
    - Client creation/updates
    - Projects
    - Tasks
    - Payments
    - Quotations
    - Invoices
    - Follow-ups
    Sorted newest first.
    """
    db = get_database()
    timeline_events = []

    # 1. Projects
    projects = await db.projects.find({"clientId": client_id}).to_list(100)
    for p in projects:
        timeline_events.append({
            "date": p.get("createdAt", ""),
            "title": f"Project Created: {p.get('projectName')}",
            "description": f"Status: {p.get('status')} | Value: ₹{p.get('finalAmount') or p.get('quotedAmount')}",
            "type": "project",
            "icon": "folder"
        })
        if p.get("deliveryInfo", {}).get("deliveryDate"):
            timeline_events.append({
                "date": p["deliveryInfo"]["deliveryDate"],
                "title": f"Project Delivered: {p.get('projectName')}",
                "description": f"Final Delivery Completed",
                "type": "delivery",
                "icon": "verified"
            })

    # 2. Invoices
    invoices = await db.invoices.find({"clientId": client_id}).to_list(100)
    for inv in invoices:
        timeline_events.append({
            "date": inv.get("createdAt", inv.get("invoiceDate", "")),
            "title": f"Invoice Generated: {inv.get('invoiceNumber')}",
            "description": f"Total: ₹{inv.get('total')} | Status: {inv.get('status')}",
            "type": "invoice",
            "icon": "receipt"
        })

    # 3. Payments
    payments = await db.payments.find({"clientId": client_id}).to_list(100)
    for pay in payments:
        timeline_events.append({
            "date": pay.get("paymentDate", pay.get("createdAt", "")),
            "title": f"₹{pay.get('amount'):,.2f} Payment Received",
            "description": f"Method: {pay.get('paymentMethod')} | Type: {pay.get('paymentType')}",
            "type": "payment",
            "icon": "payments"
        })

    # 4. Quotations
    quotations = await db.quotations.find({"clientId": client_id}).to_list(100)
    for q in quotations:
        timeline_events.append({
            "date": q.get("createdAt", q.get("quotationDate", "")),
            "title": f"Quotation Generated: {q.get('quotationNumber')}",
            "description": f"Status: {q.get('status')} | Total: ₹{q.get('total')}",
            "type": "quotation",
            "icon": "request_quote"
        })

    # 5. Follow-ups
    followups = await db.followups.find({"clientId": client_id}).to_list(100)
    for f in followups:
        timeline_events.append({
            "date": f.get("scheduledDate", f.get("createdAt", "")),
            "title": f"Follow-up ({f.get('method')}): {f.get('status')}",
            "description": f.get("notes") or "Client follow-up scheduled",
            "type": "followup",
            "icon": "phone_callback"
        })

    # Sort newest first
    timeline_events.sort(key=lambda x: x.get("date", ""), reverse=True)
    return timeline_events
