import logging
from typing import Dict, Any, List
from app.core.database import get_database

logger = logging.getLogger("nylex.finance")

def calculate_invoice_totals(items: List[Dict[str, Any]], discount: float = 0.0, tax_rate: float = 0.0) -> Dict[str, float]:
    """
    Authoritative backend calculation of line item subtotals, tax, discount, and grand total.
    """
    subtotal = sum(float(item.get("quantity", 1)) * float(item.get("rate", 0)) for item in items)
    discount = max(0.0, float(discount))
    after_discount = max(0.0, subtotal - discount)
    tax = round(after_discount * (max(0.0, float(tax_rate)) / 100.0), 2)
    total = round(after_discount + tax, 2)
    return {
        "subtotal": round(subtotal, 2),
        "discount": round(discount, 2),
        "tax": tax,
        "taxRate": round(float(tax_rate), 2),
        "total": total,
    }

async def recalculate_invoice_payments(invoice_id: str) -> Dict[str, Any]:
    """
    Recalculates paidAmount, balanceAmount, and status for an invoice from actual payment records.
    """
    db = get_database()
    invoice = await db.invoices.find_one({"id": invoice_id})
    if not invoice:
        return {}

    payments = await db.payments.find({"invoiceId": invoice_id}).to_list(1000)
    total_paid = sum(float(p.get("amount", 0.0)) for p in payments)
    invoice_total = float(invoice.get("total", 0.0))
    balance_amount = max(0.0, invoice_total - total_paid)

    new_status = invoice.get("status", "Draft")
    if invoice_total > 0:
        if total_paid >= invoice_total:
            new_status = "Paid"
        elif total_paid > 0:
            new_status = "Partially Paid"
        elif new_status == "Paid":
            new_status = "Sent"

    update_doc = {
        "paidAmount": round(total_paid, 2),
        "balanceAmount": round(balance_amount, 2),
        "status": new_status,
    }
    await db.invoices.update_one({"id": invoice_id}, {"$set": update_doc})

    # Also update project stats if this invoice is tied to a project
    project_id = invoice.get("projectId")
    if project_id:
        await recalculate_project_finances(project_id)

    return update_doc

async def recalculate_project_finances(project_id: str):
    """
    Recalculates total paid and balance due for a project based on its invoices and payments.
    """
    db = get_database()
    project = await db.projects.find_one({"id": project_id})
    if not project:
        return

    payments = await db.payments.find({"projectId": project_id}).to_list(1000)
    total_paid = sum(float(p.get("amount", 0.0)) for p in payments)
    
    # Project final amount or quoted amount
    contract_value = float(project.get("finalAmount") or project.get("quotedAmount") or 0.0)
    balance_due = max(0.0, contract_value - total_paid)

    await db.projects.update_one(
        {"id": project_id},
        {"$set": {
            "totalPaid": round(total_paid, 2),
            "balanceDue": round(balance_due, 2),
        }}
    )

async def get_revenue_summary(period_filter: str = "all") -> Dict[str, Any]:
    """
    Returns verified revenue numbers calculated strictly from payment records and authoritative invoices.
    """
    db = get_database()
    
    # Authoritative collected revenue from payments collection
    payments = await db.payments.find({}).to_list(10000)
    collected_revenue = sum(float(p.get("amount", 0.0)) for p in payments)

    # Invoices for total billed & pending
    invoices = await db.invoices.find({"isDeleted": {"$ne": True}}).to_list(10000)
    total_billed = sum(float(inv.get("total", 0.0)) for inv in invoices)
    pending_revenue = max(0.0, total_billed - collected_revenue)

    # Breakdown by client
    clients = await db.clients.find({"isDeleted": {"$ne": True}}).to_list(1000)
    client_name_map = {c["id"]: c.get("businessName") or c.get("clientName") for c in clients}
    revenue_by_client = {}
    for p in payments:
        cid = p.get("clientId", "Unknown")
        cname = client_name_map.get(cid, "Direct / Misc")
        revenue_by_client[cname] = round(revenue_by_client.get(cname, 0.0) + float(p.get("amount", 0.0)), 2)

    # Monthly breakdown
    revenue_by_month = {}
    for p in payments:
        p_date = p.get("paymentDate", "")
        month_key = p_date[:7] if len(p_date) >= 7 else "Unknown"
        revenue_by_month[month_key] = round(revenue_by_month.get(month_key, 0.0) + float(p.get("amount", 0.0)), 2)

    return {
        "totalRevenue": round(total_billed, 2),
        "collectedRevenue": round(collected_revenue, 2),
        "pendingRevenue": round(pending_revenue, 2),
        "revenueByClient": revenue_by_client,
        "revenueByMonth": revenue_by_month,
    }
