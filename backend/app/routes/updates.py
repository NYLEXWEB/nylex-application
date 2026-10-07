from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.update import DailyUpdateCreate, DailyUpdateResponse
from app.utils.id_generator import generate_entity_id
from app.services.audit_service import log_audit_event
from app.services.notification_service import broadcast_notification

router = APIRouter(prefix="/updates", tags=["Daily Project Updates"])

@router.get("", response_model=List[DailyUpdateResponse])
async def list_daily_updates(
    project_id: Optional[str] = None,
    user_id: Optional[str] = None,
    date: Optional[str] = None,
    limit: int = 50,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {}
    if project_id:
        query["projectId"] = project_id
    if user_id:
        query["userId"] = user_id
    if date:
        query["date"] = date

    updates = await db.daily_updates.find(query).sort("createdAt", -1).limit(limit).to_list(limit)
    return [DailyUpdateResponse(**u) for u in updates]

@router.post("", response_model=DailyUpdateResponse, status_code=status.HTTP_201_CREATED)
async def create_daily_update(
    update_in: DailyUpdateCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    upd_id = await generate_entity_id("UPD", "daily_updates")
    now = datetime.now(timezone.utc)
    now_iso = now.isoformat()
    today_date = update_in.date or now.strftime("%Y-%m-%d")

    project = await db.projects.find_one({"id": update_in.projectId})
    if not project:
        raise HTTPException(status_code=400, detail="Referenced project not found.")

    upd_doc = update_in.model_dump()
    upd_doc.update({
        "id": upd_id,
        "projectName": project.get("projectName"),
        "userId": current_user["id"],
        "userName": current_user["name"],
        "date": today_date,
        "createdAt": now_iso,
    })

    await db.daily_updates.insert_one(upd_doc)

    # Log to audit and broadcast notification to partner
    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="POST_DAILY_UPDATE",
        entity_type="PROJECT",
        entity_id=update_in.projectId,
        description=f"Posted daily update for '{project.get('projectName')}': {update_in.updateText[:60]}..."
    )

    await broadcast_notification(
        title=f"Update: {project.get('projectName')}",
        message=f"{current_user['name']} posted a progress update.",
        notification_type="DAILY_UPDATE",
        related_entity_type="PROJECT",
        related_entity_id=update_in.projectId,
        exclude_user_id=current_user["id"]
    )

    return DailyUpdateResponse(**upd_doc)
