from typing import Dict, Any, List
from fastapi import APIRouter, Depends, Query
from app.core.database import get_database
from app.core.security import get_current_active_user

router = APIRouter(prefix="/search", tags=["Global Search"])

@router.get("")
async def global_search(
    q: str = Query(..., min_length=1, description="Search query string"),
    current_user: dict = Depends(get_current_active_user)
) -> Dict[str, List[Dict[str, Any]]]:
    """
    Section 29: Fast global search across all 7 NYLEX entities.
    """
    db = get_database()
    regex_pattern = {"$regex": q, "$options": "i"}

    # 1. Clients
    clients = await db.clients.find({
        "isDeleted": {"$ne": True},
        "$or": [
            {"clientName": regex_pattern},
            {"businessName": regex_pattern},
            {"phone": regex_pattern},
            {"email": regex_pattern},
        ]
    }).limit(10).to_list(10)

    # 2. Leads
    leads = await db.leads.find({
        "isDeleted": {"$ne": True},
        "$or": [
            {"name": regex_pattern},
            {"businessName": regex_pattern},
            {"phone": regex_pattern},
            {"email": regex_pattern},
        ]
    }).limit(10).to_list(10)

    # 3. Projects
    projects = await db.projects.find({
        "isDeleted": {"$ne": True},
        "$or": [
            {"projectName": regex_pattern},
            {"description": regex_pattern},
            {"clientName": regex_pattern},
            {"businessName": regex_pattern},
        ]
    }).limit(10).to_list(10)

    # 4. Tasks
    tasks = await db.tasks.find({
        "$or": [
            {"title": regex_pattern},
            {"description": regex_pattern},
            {"projectName": regex_pattern},
        ]
    }).limit(10).to_list(10)

    # 5. Invoices
    invoices = await db.invoices.find({
        "isDeleted": {"$ne": True},
        "$or": [
            {"invoiceNumber": regex_pattern},
            {"businessName": regex_pattern},
            {"clientName": regex_pattern},
        ]
    }).limit(10).to_list(10)

    # 6. Quotations
    quotations = await db.quotations.find({
        "isDeleted": {"$ne": True},
        "$or": [
            {"quotationNumber": regex_pattern},
            {"businessName": regex_pattern},
            {"clientName": regex_pattern},
        ]
    }).limit(10).to_list(10)

    # 7. Payments
    payments = await db.payments.find({
        "$or": [
            {"paymentNumber": regex_pattern},
            {"referenceNumber": regex_pattern},
            {"businessName": regex_pattern},
            {"clientName": regex_pattern},
        ]
    }).limit(10).to_list(10)

    def format_item(item, entity_type, title, subtitle):
        return {
            "id": item.get("id"),
            "entityType": entity_type,
            "title": title,
            "subtitle": subtitle,
            "status": item.get("status"),
        }

    return {
        "clients": [format_item(c, "CLIENT", c.get("businessName"), f"{c.get('clientName')} • {c.get('phone')}") for c in clients],
        "leads": [format_item(l, "LEAD", l.get("name"), f"{l.get('businessName') or 'Lead'} • {l.get('status')}") for l in leads],
        "projects": [format_item(p, "PROJECT", p.get("projectName"), f"{p.get('businessName')} • {p.get('status')}") for p in projects],
        "tasks": [format_item(t, "TASK", t.get("title"), f"{t.get('projectName')} • {t.get('status')}") for t in tasks],
        "invoices": [format_item(i, "INVOICE", i.get("invoiceNumber"), f"{i.get('businessName')} • ₹{i.get('total')}") for i in invoices],
        "quotations": [format_item(q, "QUOTATION", q.get("quotationNumber"), f"{q.get('businessName')} • ₹{q.get('total')}") for q in quotations],
        "payments": [format_item(pay, "PAYMENT", f"₹{pay.get('amount')}", f"{pay.get('paymentMethod')} • {pay.get('businessName')}") for pay in payments],
    }
