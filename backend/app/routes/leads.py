from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.lead import (
    LeadCreate,
    LeadUpdate,
    LeadStatusUpdate,
    LeadConvertRequest,
    LeadResponse,
)
from app.utils.id_generator import generate_entity_id
from app.services.audit_service import log_audit_event
from app.services.notification_service import create_notification

router = APIRouter(prefix="/leads", tags=["Leads"])

@router.get("", response_model=List[LeadResponse])
async def list_leads(
    status: Optional[str] = None,
    priority: Optional[str] = None,
    search: Optional[str] = None,
    assigned_to: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {"isDeleted": {"$ne": True}}
    if status and status != "All":
        query["status"] = status
    if priority and priority != "All":
        query["priority"] = priority
    if assigned_to and assigned_to != "All":
        query["assignedTo"] = assigned_to
    if search:
        query["$or"] = [
            {"name": {"$regex": search, "$options": "i"}},
            {"businessName": {"$regex": search, "$options": "i"}},
            {"phone": {"$regex": search, "$options": "i"}},
            {"email": {"$regex": search, "$options": "i"}},
        ]

    leads = await db.leads.find(query).sort("createdAt", -1).skip(skip).limit(limit).to_list(limit)
    return [LeadResponse(**l) for l in leads]

@router.post("", response_model=LeadResponse, status_code=status.HTTP_201_CREATED)
async def create_lead(
    lead_in: LeadCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    lead_id = await generate_entity_id("LED", "leads")
    now = datetime.now(timezone.utc).isoformat()

    assigned_name = None
    if lead_in.assignedTo:
        user_doc = await db.users.find_one({"id": lead_in.assignedTo})
        if user_doc:
            assigned_name = user_doc.get("name")

    lead_doc = lead_in.model_dump()
    lead_doc.update({
        "id": lead_id,
        "assignedToName": assigned_name,
        "createdBy": current_user["id"],
        "createdByName": current_user["name"],
        "createdAt": now,
        "updatedAt": now,
        "isDeleted": False
    })

    await db.leads.insert_one(lead_doc)

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CREATE_LEAD",
        entity_type="LEAD",
        entity_id=lead_id,
        description=f"Created lead '{lead_in.name}' ({lead_in.businessName or 'Individual'})."
    )

    if lead_in.assignedTo and lead_in.assignedTo != current_user["id"]:
        await create_notification(
            user_id=lead_in.assignedTo,
            title="New Lead Assigned",
            message=f"You have been assigned lead '{lead_in.name}'.",
            notification_type="LEAD_ASSIGNED",
            related_entity_type="LEAD",
            related_entity_id=lead_id,
        )

    return LeadResponse(**lead_doc)

@router.get("/{lead_id}", response_model=LeadResponse)
async def get_lead(lead_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    lead = await db.leads.find_one({"id": lead_id, "isDeleted": {"$ne": True}})
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found.")
    return LeadResponse(**lead)

@router.put("/{lead_id}", response_model=LeadResponse)
async def update_lead(
    lead_id: str,
    update_data: LeadUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    existing = await db.leads.find_one({"id": lead_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Lead not found.")

    update_fields = {k: v for k, v in update_data.model_dump().items() if v is not None}
    now = datetime.now(timezone.utc).isoformat()
    update_fields["updatedAt"] = now

    if "assignedTo" in update_fields and update_fields["assignedTo"]:
        user_doc = await db.users.find_one({"id": update_fields["assignedTo"]})
        update_fields["assignedToName"] = user_doc.get("name") if user_doc else None

    res = await db.leads.find_one_and_update(
        {"id": lead_id},
        {"$set": update_fields},
        return_document=True
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="UPDATE_LEAD",
        entity_type="LEAD",
        entity_id=lead_id,
        description=f"Updated details for lead '{res.get('name')}'.",
        details=update_fields
    )

    return LeadResponse(**res)

@router.put("/{lead_id}/status", response_model=LeadResponse)
async def change_lead_status(
    lead_id: str,
    status_data: LeadStatusUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    existing = await db.leads.find_one({"id": lead_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Lead not found.")

    old_status = existing.get("status")
    now = datetime.now(timezone.utc).isoformat()
    
    update_dict = {
        "status": status_data.status,
        "updatedAt": now,
    }
    if status_data.notes:
        existing_notes = existing.get("notes") or ""
        update_dict["notes"] = f"{existing_notes}\n[{now[:10]}] Status changed to {status_data.status}: {status_data.notes}".strip()

    res = await db.leads.find_one_and_update(
        {"id": lead_id},
        {"$set": update_dict},
        return_document=True
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CHANGE_LEAD_STATUS",
        entity_type="LEAD",
        entity_id=lead_id,
        description=f"Changed lead status from {old_status} to {status_data.status}."
    )

    return LeadResponse(**res)

@router.delete("/{lead_id}")
async def delete_lead(lead_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    existing = await db.leads.find_one({"id": lead_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Lead not found.")

    now = datetime.now(timezone.utc).isoformat()
    await db.leads.update_one(
        {"id": lead_id},
        {"$set": {"isDeleted": True, "deletedAt": now, "deletedBy": current_user["id"]}}
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="ARCHIVE_LEAD",
        entity_type="LEAD",
        entity_id=lead_id,
        description=f"Archived lead '{existing.get('name')}'."
    )
    return {"message": "Lead archived successfully."}

@router.post("/{lead_id}/convert")
async def convert_lead_to_client(
    lead_id: str,
    convert_data: LeadConvertRequest,
    current_user: dict = Depends(get_current_active_user)
):
    """
    Section 14: LEAD → CLIENT CONVERSION
    Automatically transfers relevant lead data into the client record.
    Maintains relationship: Original Lead -> Client -> Project.
    """
    db = get_database()
    lead = await db.leads.find_one({"id": lead_id, "isDeleted": {"$ne": True}})
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found.")

    now = datetime.now(timezone.utc).isoformat()
    client_id = await generate_entity_id("CLT", "clients")
    
    # 1. Create Client from Lead data
    client_doc = {
        "id": client_id,
        "clientName": lead.get("name"),
        "businessName": lead.get("businessName") or f"{lead.get('name')} Enterprise",
        "phone": lead.get("phone"),
        "whatsapp": lead.get("whatsapp"),
        "email": lead.get("email"),
        "location": lead.get("location"),
        "address": lead.get("location"),
        "leadSource": lead.get("leadSource", "Converted Lead"),
        "assignedTo": lead.get("assignedTo"),
        "assignedToName": lead.get("assignedToName"),
        "notes": f"Converted from Lead {lead_id}.\n{lead.get('notes') or ''}".strip(),
        "status": "Active",
        "originalLeadId": lead_id,
        "createdBy": current_user["id"],
        "createdByName": current_user["name"],
        "createdAt": now,
        "updatedAt": now,
        "isDeleted": False,
    }
    await db.clients.insert_one(client_doc)

    project_id = None
    if convert_data.createProject:
        project_id = await generate_entity_id("PRJ", "projects")
        proj_name = convert_data.projectName or f"{client_doc['businessName']} - {lead.get('serviceRequired') or 'Web Development'}"
        proj_doc = {
            "id": project_id,
            "projectName": proj_name,
            "clientId": client_id,
            "projectType": convert_data.projectType or lead.get("serviceRequired") or "Website",
            "description": f"Initial client project from lead {lead_id}.",
            "quotedAmount": float(convert_data.quotedAmount or lead.get("expectedBudget") or 0.0),
            "finalAmount": float(convert_data.quotedAmount or lead.get("expectedBudget") or 0.0),
            "totalPaid": 0.0,
            "balanceDue": float(convert_data.quotedAmount or lead.get("expectedBudget") or 0.0),
            "startDate": now[:10],
            "deadline": convert_data.deadline,
            "status": "Planning",
            "priority": "Medium",
            "assignedUsers": [lead.get("assignedTo")] if lead.get("assignedTo") else [current_user["id"]],
            "assignedUserNames": [lead.get("assignedToName")] if lead.get("assignedToName") else [current_user["name"]],
            "createdBy": current_user["id"],
            "createdAt": now,
            "updatedAt": now,
            "isDeleted": False,
        }
        await db.projects.insert_one(proj_doc)

    # 2. Update Lead status to 'Won' with references
    await db.leads.update_one(
        {"id": lead_id},
        {"$set": {
            "status": "Won",
            "convertedClientId": client_id,
            "convertedProjectId": project_id,
            "updatedAt": now,
        }}
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CONVERT_LEAD",
        entity_type="LEAD",
        entity_id=lead_id,
        description=f"Converted lead '{lead.get('name')}' to Client '{client_doc['businessName']}' (Client ID: {client_id}, Project ID: {project_id})."
    )

    return {
        "message": "Lead successfully converted to Client.",
        "clientId": client_id,
        "projectId": project_id,
        "client": client_doc,
    }
