from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.followup import FollowupCreate, FollowupUpdate, FollowupResponse
from app.utils.id_generator import generate_entity_id
from app.services.audit_service import log_audit_event
from app.services.notification_service import create_notification

router = APIRouter(prefix="/followups", tags=["Follow-ups"])

@router.get("", response_model=List[FollowupResponse])
async def list_followups(
    status: Optional[str] = None,
    lead_id: Optional[str] = None,
    client_id: Optional[str] = None,
    assigned_to: Optional[str] = None,
    is_today: Optional[bool] = False,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {}
    if status and status != "All":
        query["status"] = status
    if lead_id:
        query["leadId"] = lead_id
    if client_id:
        query["clientId"] = client_id
    if assigned_to and assigned_to != "All":
        query["assignedTo"] = assigned_to
    if is_today:
        today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        query["scheduledDate"] = today_str

    followups = await db.followups.find(query).sort([("scheduledDate", 1), ("scheduledTime", 1)]).to_list(100)
    return [FollowupResponse(**f) for f in followups]

@router.post("", response_model=FollowupResponse, status_code=status.HTTP_201_CREATED)
async def create_followup(
    followup_in: FollowupCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    flp_id = await generate_entity_id("FLP", "followups")
    now = datetime.now(timezone.utc).isoformat()

    lead_name, lead_business, client_name = None, None, None
    if followup_in.leadId:
        lead = await db.leads.find_one({"id": followup_in.leadId})
        if lead:
            lead_name = lead.get("name")
            lead_business = lead.get("businessName")
            # Also update lead's nextFollowUp field
            await db.leads.update_one(
                {"id": followup_in.leadId},
                {"$set": {"nextFollowUp": f"{followup_in.scheduledDate} {followup_in.scheduledTime}"}}
            )

    if followup_in.clientId:
        client = await db.clients.find_one({"id": followup_in.clientId})
        if client:
            client_name = client.get("businessName") or client.get("clientName")

    assigned_name = None
    target_user_id = followup_in.assignedTo or current_user["id"]
    user_doc = await db.users.find_one({"id": target_user_id})
    if user_doc:
        assigned_name = user_doc.get("name")

    flp_doc = followup_in.model_dump()
    flp_doc.update({
        "id": flp_id,
        "leadName": lead_name,
        "leadBusiness": lead_business,
        "clientName": client_name,
        "assignedTo": target_user_id,
        "assignedToName": assigned_name,
        "createdBy": current_user["id"],
        "createdAt": now,
        "updatedAt": now,
    })

    await db.followups.insert_one(flp_doc)

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CREATE_FOLLOWUP",
        entity_type="FOLLOWUP",
        entity_id=flp_id,
        description=f"Scheduled {followup_in.method} follow-up for {lead_name or client_name or 'contact'} on {followup_in.scheduledDate} at {followup_in.scheduledTime}."
    )

    if target_user_id != current_user["id"]:
        await create_notification(
            user_id=target_user_id,
            title="Follow-up Assigned",
            message=f"Follow-up with {lead_name or client_name} scheduled for {followup_in.scheduledDate} {followup_in.scheduledTime}.",
            notification_type="FOLLOWUP_ASSIGNED",
            related_entity_type="FOLLOWUP",
            related_entity_id=flp_id,
        )

    return FollowupResponse(**flp_doc)

@router.put("/{followup_id}", response_model=FollowupResponse)
async def update_followup(
    followup_id: str,
    update_data: FollowupUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    existing = await db.followups.find_one({"id": followup_id})
    if not existing:
        raise HTTPException(status_code=404, detail="Follow-up not found.")

    update_fields = {k: v for k, v in update_data.model_dump().items() if v is not None}
    now = datetime.now(timezone.utc).isoformat()
    update_fields["updatedAt"] = now

    if "assignedTo" in update_fields and update_fields["assignedTo"]:
        u = await db.users.find_one({"id": update_fields["assignedTo"]})
        update_fields["assignedToName"] = u.get("name") if u else None

    res = await db.followups.find_one_and_update(
        {"id": followup_id},
        {"$set": update_fields},
        return_document=True
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="UPDATE_FOLLOWUP",
        entity_type="FOLLOWUP",
        entity_id=followup_id,
        description=f"Updated follow-up status/details to {res.get('status')}."
    )

    return FollowupResponse(**res)

@router.put("/{followup_id}/complete")
async def complete_followup(followup_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    now = datetime.now(timezone.utc).isoformat()
    res = await db.followups.find_one_and_update(
        {"id": followup_id},
        {"$set": {"status": "Completed", "updatedAt": now}},
        return_document=True
    )
    if not res:
        raise HTTPException(status_code=404, detail="Follow-up not found.")

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="COMPLETE_FOLLOWUP",
        entity_type="FOLLOWUP",
        entity_id=followup_id,
        description=f"Completed follow-up for {res.get('leadName') or res.get('clientName')}."
    )
    return {"message": "Follow-up marked as completed."}
