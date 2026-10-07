from typing import List, Optional
from fastapi import APIRouter, Depends
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.audit import AuditLogResponse

router = APIRouter(prefix="/audit-logs", tags=["Audit Logs"])

@router.get("", response_model=List[AuditLogResponse])
async def list_audit_logs(
    entity_type: Optional[str] = None,
    user_id: Optional[str] = None,
    limit: int = 100,
    skip: int = 0,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query = {}
    if entity_type and entity_type != "All":
        query["entityType"] = entity_type
    if user_id and user_id != "All":
        query["userId"] = user_id

    logs = await db.audit_logs.find(query).sort("timestamp", -1).skip(skip).limit(limit).to_list(limit)
    return [AuditLogResponse(**log) for log in logs]
