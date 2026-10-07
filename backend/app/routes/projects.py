from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.project import ProjectCreate, ProjectUpdate, ProjectDeliveryUpdate, ProjectResponse
from app.utils.id_generator import generate_entity_id
from app.services.audit_service import log_audit_event
from app.services.notification_service import create_notification
from app.services.finance_service import recalculate_project_finances

router = APIRouter(prefix="/projects", tags=["Projects"])

@router.get("", response_model=List[ProjectResponse])
async def list_projects(
    client_id: Optional[str] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    user_id: Optional[str] = None,
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
    if user_id and user_id != "All":
        query["assignedUsers"] = user_id
    if search:
        query["$or"] = [
            {"projectName": {"$regex": search, "$options": "i"}},
            {"description": {"$regex": search, "$options": "i"}},
        ]

    projects = await db.projects.find(query).sort("createdAt", -1).skip(skip).limit(limit).to_list(limit)
    return [ProjectResponse(**p) for p in projects]

@router.post("", response_model=ProjectResponse, status_code=status.HTTP_201_CREATED)
async def create_project(
    project_in: ProjectCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    proj_id = await generate_entity_id("PRJ", "projects")
    now = datetime.now(timezone.utc).isoformat()

    client = await db.clients.find_one({"id": project_in.clientId})
    if not client:
        raise HTTPException(status_code=400, detail="Referenced client does not exist.")

    # Resolve assigned user names
    assigned_names = []
    if project_in.assignedUsers:
        users = await db.users.find({"id": {"$in": project_in.assignedUsers}}).to_list(10)
        assigned_names = [u["name"] for u in users]

    final_amt = project_in.finalAmount or project_in.quotedAmount

    proj_doc = project_in.model_dump()
    proj_doc.update({
        "id": proj_id,
        "clientName": client.get("clientName"),
        "businessName": client.get("businessName"),
        "finalAmount": final_amt,
        "totalPaid": 0.0,
        "balanceDue": final_amt,
        "assignedUserNames": assigned_names,
        "createdBy": current_user["id"],
        "createdAt": now,
        "updatedAt": now,
        "isDeleted": False
    })

    await db.projects.insert_one(proj_doc)

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CREATE_PROJECT",
        entity_type="PROJECT",
        entity_id=proj_id,
        description=f"Created project '{project_in.projectName}' for {client.get('businessName')}."
    )

    for uid in project_in.assignedUsers:
        if uid != current_user["id"]:
            await create_notification(
                user_id=uid,
                title="Assigned to Project",
                message=f"You have been assigned to project '{project_in.projectName}'.",
                notification_type="PROJECT_ASSIGNED",
                related_entity_type="PROJECT",
                related_entity_id=proj_id,
            )

    return ProjectResponse(**proj_doc)

@router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(project_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    project = await db.projects.find_one({"id": project_id, "isDeleted": {"$ne": True}})
    if not project:
        raise HTTPException(status_code=404, detail="Project not found.")
    return ProjectResponse(**project)

@router.put("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: str,
    update_data: ProjectUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    existing = await db.projects.find_one({"id": project_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Project not found.")

    update_fields = {k: v for k, v in update_data.model_dump().items() if v is not None}
    now = datetime.now(timezone.utc).isoformat()
    update_fields["updatedAt"] = now

    if "assignedUsers" in update_fields and update_fields["assignedUsers"]:
        users = await db.users.find({"id": {"$in": update_fields["assignedUsers"]}}).to_list(10)
        update_fields["assignedUserNames"] = [u["name"] for u in users]

    res = await db.projects.find_one_and_update(
        {"id": project_id},
        {"$set": update_fields},
        return_document=True
    )

    # Recalculate finances if amount changed
    if "finalAmount" in update_fields or "quotedAmount" in update_fields:
        await recalculate_project_finances(project_id)
        res = await db.projects.find_one({"id": project_id})

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="UPDATE_PROJECT",
        entity_type="PROJECT",
        entity_id=project_id,
        description=f"Updated project '{res.get('projectName')}' (Status: {res.get('status')})."
    )

    return ProjectResponse(**res)

@router.put("/{project_id}/deliver", response_model=ProjectResponse)
async def mark_project_delivered(
    project_id: str,
    delivery_data: ProjectDeliveryUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    """
    Section 33: DELIVERY INFORMATION
    Stores delivery date, domain information, support start date, and transitions status to 'Delivered'.
    """
    db = get_database()
    existing = await db.projects.find_one({"id": project_id, "isDeleted": {"$ne": True}})
    if not existing:
        raise HTTPException(status_code=404, detail="Project not found.")

    now = datetime.now(timezone.utc).isoformat()
    balance = float(existing.get("balanceDue", 0.0))
    pay_status = "Paid" if balance <= 0 else "Pending"

    delivery_info = {
        "deliveryDate": delivery_data.deliveryDate,
        "finalPaymentStatus": pay_status,
        "supportStartDate": delivery_data.supportStartDate or delivery_data.deliveryDate,
        "domainInfo": delivery_data.domainInfo.model_dump() if delivery_data.domainInfo else existing.get("domainInfo"),
        "notes": delivery_data.notes,
    }

    update_fields = {
        "status": "Delivered",
        "deliveryInfo": delivery_info,
        "updatedAt": now,
    }
    if delivery_data.domainInfo:
        update_fields["domainInfo"] = delivery_data.domainInfo.model_dump()

    res = await db.projects.find_one_and_update(
        {"id": project_id},
        {"$set": update_fields},
        return_document=True
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="DELIVER_PROJECT",
        entity_type="PROJECT",
        entity_id=project_id,
        description=f"Delivered project '{existing.get('projectName')}' on {delivery_data.deliveryDate}."
    )

    return ProjectResponse(**res)

@router.get("/{project_id}/activity")
async def get_project_activity_feed(project_id: str, current_user: dict = Depends(get_current_active_user)):
    """
    Section 21: PROJECT ACTIVITY FEED
    Sorts newest first:
    - Task created / completed
    - Daily updates
    - Invoices & Quotations
    - Payments
    - Status changes
    """
    db = get_database()
    feed = []

    # Daily updates
    updates = await db.daily_updates.find({"projectId": project_id}).to_list(100)
    for u in updates:
        feed.append({
            "timestamp": u.get("createdAt", ""),
            "author": u.get("userName", "NYLEX"),
            "title": f"Daily Update ({u.get('date')})",
            "description": u.get("updateText"),
            "type": "daily_update"
        })

    # Tasks
    tasks = await db.tasks.find({"projectId": project_id}).to_list(100)
    for t in tasks:
        feed.append({
            "timestamp": t.get("updatedAt", t.get("createdAt", "")),
            "author": t.get("assignedToName", "NYLEX"),
            "title": f"Task: {t.get('title')}",
            "description": f"Status: {t.get('status')} | Priority: {t.get('priority')}",
            "type": "task"
        })

    # Invoices & Payments
    invoices = await db.invoices.find({"projectId": project_id}).to_list(50)
    for inv in invoices:
        feed.append({
            "timestamp": inv.get("createdAt", ""),
            "author": "NYLEX Finance",
            "title": f"Invoice Created: {inv.get('invoiceNumber')}",
            "description": f"Amount: ₹{inv.get('total')} | Balance: ₹{inv.get('balanceAmount')}",
            "type": "invoice"
        })

    payments = await db.payments.find({"projectId": project_id}).to_list(50)
    for p in payments:
        feed.append({
            "timestamp": p.get("createdAt", ""),
            "author": p.get("receivedByName", "NYLEX"),
            "title": f"Payment: ₹{p.get('amount')}",
            "description": f"Method: {p.get('paymentMethod')} | Type: {p.get('paymentType')}",
            "type": "payment"
        })

    feed.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
    return feed
