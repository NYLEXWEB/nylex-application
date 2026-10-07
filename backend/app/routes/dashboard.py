from typing import Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.dashboard import DashboardStatsResponse, DashboardSummaryCards

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

@router.get("", response_model=DashboardStatsResponse)
async def get_dashboard_data(current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    # 1. Counts
    total_leads = await db.leads.count_documents({"isDeleted": {"$ne": True}})
    active_clients = await db.clients.count_documents({"isDeleted": {"$ne": True}, "status": "Active"})
    active_projects = await db.projects.count_documents({
        "isDeleted": {"$ne": True},
        "status": {"$in": ["Planning", "In Progress", "Review"]}
    })
    pending_followups = await db.followups.count_documents({"status": "Pending"})

    # 2. Financial totals
    invoices = await db.invoices.find({"isDeleted": {"$ne": True}}).to_list(10000)
    total_revenue = sum(float(inv.get("total", 0.0)) for inv in invoices)
    
    payments = await db.payments.find({}).to_list(10000)
    collected_revenue = sum(float(p.get("amount", 0.0)) for p in payments)
    pending_payments = max(0.0, total_revenue - collected_revenue)

    # 3. Today's follow-ups
    today_followups = await db.followups.find({
        "scheduledDate": today_str,
        "status": "Pending"
    }).sort("scheduledTime", 1).limit(10).to_list(10)

    # 4. Tasks due today
    tasks_due_today = await db.tasks.find({
        "dueDate": today_str,
        "status": {"$ne": "Completed"}
    }).limit(10).to_list(10)

    # 5. Recent project updates
    recent_updates = await db.daily_updates.find({}).sort("createdAt", -1).limit(5).to_list(5)

    # 6. Recent payments
    recent_payments = await db.payments.find({}).sort("createdAt", -1).limit(5).to_list(5)

    # 7. Recent messages
    recent_messages = await db.messages.find({}).sort("createdAt", -1).limit(5).to_list(5)

    def clean_mongo_doc(doc):
        doc = dict(doc)
        if "_id" in doc:
            del doc["_id"]
        return doc

    return DashboardStatsResponse(
        summary=DashboardSummaryCards(
            totalLeads=total_leads,
            activeClients=active_clients,
            activeProjects=active_projects,
            pendingFollowUps=pending_followups,
            totalRevenue=round(total_revenue, 2),
            collectedRevenue=round(collected_revenue, 2),
            pendingPayments=round(pending_payments, 2),
        ),
        todayFollowUps=[clean_mongo_doc(f) for f in today_followups],
        tasksDueToday=[clean_mongo_doc(t) for t in tasks_due_today],
        recentProjectUpdates=[clean_mongo_doc(u) for u in recent_updates],
        recentPayments=[clean_mongo_doc(p) for p in recent_payments],
        recentMessages=[clean_mongo_doc(m) for m in recent_messages],
    )
