import uuid
from datetime import datetime, timezone

async def generate_entity_id(prefix: str, collection_name: str, id_field: str = "id") -> str:
    from app.core.database import get_database
    db = get_database()
    current_year = datetime.now(timezone.utc).year
    
    # Count existing documents for this year to create sequential human-readable IDs
    try:
        count = await db[collection_name].count_documents({})
        seq_num = count + 1
        return f"{prefix}-{current_year}-{seq_num:03d}"
    except Exception:
        # Fallback to unique short uuid if DB count fails
        short_id = uuid.uuid4().hex[:6].upper()
        return f"{prefix}-{current_year}-{short_id}"

def generate_uuid(prefix: str = "") -> str:
    unique_str = uuid.uuid4().hex[:10]
    return f"{prefix}{unique_str}" if prefix else unique_str
