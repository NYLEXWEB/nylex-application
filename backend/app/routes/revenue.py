from typing import Dict, Any, Optional
from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.services.finance_service import get_revenue_summary

router = APIRouter(prefix="/revenue", tags=["Revenue"])

@router.get("")
async def get_revenue_analytics(
    period: Optional[str] = "all",  # today, week, month, year, all
    current_user: dict = Depends(get_current_active_user)
) -> Dict[str, Any]:
    """
    Section 25: Returns authoritative revenue analytics calculated strictly from MongoDB payment records.
    """
    db = get_database()
    now = datetime.now(timezone.utc)
    
    start_date_str = None
    if period == "today":
        start_date_str = now.strftime("%Y-%m-%d")
    elif period == "week":
        start_date_str = (now - timedelta(days=7)).strftime("%Y-%m-%d")
    elif period == "month":
        start_date_str = (now - timedelta(days=30)).strftime("%Y-%m-%d")
    elif period == "year":
        start_date_str = (now - timedelta(days=365)).strftime("%Y-%m-%d")

    pay_query = {}
    if start_date_str:
        pay_query["paymentDate"] = {"$gte": start_date_str}

    payments = await db.payments.find(pay_query).to_list(10000)
    collected_revenue = sum(float(p.get("amount", 0.0)) for p in payments)

    inv_query = {"isDeleted": {"$ne": True}}
    if start_date_str:
        inv_query["invoiceDate"] = {"$gte": start_date_str}
    
    invoices = await db.invoices.find(inv_query).to_list(10000)
    total_billed = sum(float(inv.get("total", 0.0)) for inv in invoices)
    pending_revenue = max(0.0, total_billed - collected_revenue)

    # Revenue by Client
    clients = await db.clients.find({"isDeleted": {"$ne": True}}).to_list(1000)
    client_name_map = {c["id"]: c.get("businessName") or c.get("clientName") for c in clients}
    revenue_by_client = {}
    for p in payments:
        cid = p.get("clientId", "Unknown")
        cname = client_name_map.get(cid, "Direct / Misc")
        revenue_by_client[cname] = round(revenue_by_client.get(cname, 0.0) + float(p.get("amount", 0.0)), 2)

    # Revenue by Project
    projects = await db.projects.find({"isDeleted": {"$ne": True}}).to_list(1000)
    project_name_map = {p["id"]: p.get("projectName") for p in projects}
    revenue_by_project = {}
    for p in payments:
        pid = p.get("projectId")
        if pid:
            pname = project_name_map.get(pid, pid)
            revenue_by_project[pname] = round(revenue_by_project.get(pname, 0.0) + float(p.get("amount", 0.0)), 2)

    # Monthly breakdown
    revenue_by_month = {}
    for p in payments:
        p_date = p.get("paymentDate", "")
        month_key = p_date[:7] if len(p_date) >= 7 else "Unknown"
        revenue_by_month[month_key] = round(revenue_by_month.get(month_key, 0.0) + float(p.get("amount", 0.0)), 2)

    return {
        "period": period,
        "totalRevenue": round(total_billed, 2),
        "collectedRevenue": round(collected_revenue, 2),
        "pendingRevenue": round(pending_revenue, 2),
        "revenueByClient": revenue_by_client,
        "revenueByProject": revenue_by_project,
        "revenueByMonth": revenue_by_month,
        "paymentCount": len(payments),
        "invoiceCount": len(invoices),
    }
