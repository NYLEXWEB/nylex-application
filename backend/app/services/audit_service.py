import logging
from datetime import datetime, timezone
from typing import Optional, Dict, Any
from app.core.database import get_database
from app.utils.id_generator import generate_uuid

logger = logging.getLogger("nylex.audit")

async def log_audit_event(
    user_id: str,
    user_name: str,
    action: str,
    entity_type: str,
    entity_id: str,
    description: str,
    details: Optional[Dict[str, Any]] = None
):
    """
    Records an immutable audit log entry in MongoDB.
    """
    try:
        db = get_database()
        now = datetime.now(timezone.utc).isoformat()
        audit_entry = {
            "id": generate_uuid("AUD-"),
            "userId": user_id,
            "userName": user_name,
            "action": action,
            "entityType": entity_type,
            "entityId": entity_id,
            "description": description,
            "details": details or {},
            "timestamp": now,
        }
        await db.audit_logs.insert_one(audit_entry)
    except Exception as e:
        logger.error(f"Failed to record audit log: {e}")
