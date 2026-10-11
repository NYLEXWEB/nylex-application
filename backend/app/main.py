import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

from app.core.config import settings
from app.core.database import connect_to_mongo, close_mongo_connection
from app.routes import (
    auth,
    users,
    clients,
    leads,
    followups,
    projects,
    tasks,
    updates,
    quotations,
    invoices,
    payments,
    revenue,
    chat,
    notifications,
    search,
    audit,
    dashboard,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("nylex.main")

import asyncio
from datetime import datetime, timezone
from app.services.notification_service import create_notification

async def follow_up_checker():
    while True:
        try:
            await asyncio.sleep(60)
            from app.core.database import get_database
            db = get_database()
            if db is not None:
                now_utc = datetime.now(timezone.utc)
                today_str = now_utc.strftime("%Y-%m-%d")
                time_str = now_utc.strftime("%H:%M")

                due_followups = await db.followups.find({
                    "status": "Pending",
                    "scheduledDate": today_str,
                    "reminderSent": {"$ne": True}
                }).to_list(100)

                for f in due_followups:
                    f_time = f.get("scheduledTime", "00:00")
                    if time_str >= f_time:
                        target_user = f.get("assignedTo") or f.get("createdBy") or "USR-ADMIN"
                        target_name = f.get("leadName") or f.get("clientName") or "Contact"
                        await create_notification(
                            user_id=target_user,
                            title="Follow-up Reminder Due",
                            message=f"Reminder: {f.get('method', 'Call')} with {target_name} is scheduled for {f.get('scheduledTime')} today!",
                            notification_type="FOLLOWUP_DUE",
                            related_entity_type="FOLLOWUP",
                            related_entity_id=f.get("id"),
                        )
                        await db.followups.update_one(
                            {"id": f.get("id")},
                            {"$set": {"reminderSent": True}}
                        )
        except asyncio.CancelledError:
            break
        except Exception as e:
            logger.error(f"Error in follow-up checker: {e}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing NYLEX Management API Backend...")
    await connect_to_mongo()
    checker_task = asyncio.create_task(follow_up_checker())
    yield
    checker_task.cancel()
    logger.info("Shutting down NYLEX Management API Backend...")
    await close_mongo_connection()

app = FastAPI(
    title=settings.APP_NAME,
    description="NYLEX Internal Management Backend API for Leads, Clients, Projects, Tasks, Follow-ups, Quotations, Invoices, Payments, and Real-time Collaboration.",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS if isinstance(settings.CORS_ORIGINS, list) else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global validation error handler with clean output
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors():
        loc = " -> ".join([str(x) for x in err.get("loc", [])])
        errors.append(f"{loc}: {err.get('msg')}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": "Validation error", "errors": errors},
    )

# Root Health endpoints
@app.get("/", tags=["Health"])
async def root():
    return {
        "app": settings.APP_NAME,
        "environment": settings.APP_ENV,
        "status": "online",
        "documentation": "/docs"
    }

@app.get("/api/health", tags=["Health"])
async def health_check():
    return {"status": "healthy", "service": "nylex-api"}

# Register Modular Routers
app.include_router(auth.router, prefix=settings.API_PREFIX)
app.include_router(users.router, prefix=settings.API_PREFIX)
app.include_router(dashboard.router, prefix=settings.API_PREFIX)
app.include_router(clients.router, prefix=settings.API_PREFIX)
app.include_router(leads.router, prefix=settings.API_PREFIX)
app.include_router(followups.router, prefix=settings.API_PREFIX)
app.include_router(projects.router, prefix=settings.API_PREFIX)
app.include_router(tasks.router, prefix=settings.API_PREFIX)
app.include_router(updates.router, prefix=settings.API_PREFIX)
app.include_router(quotations.router, prefix=settings.API_PREFIX)
app.include_router(invoices.router, prefix=settings.API_PREFIX)
app.include_router(payments.router, prefix=settings.API_PREFIX)
app.include_router(revenue.router, prefix=settings.API_PREFIX)
app.include_router(chat.router, prefix=settings.API_PREFIX)
app.include_router(notifications.router, prefix=settings.API_PREFIX)
app.include_router(search.router, prefix=settings.API_PREFIX)
app.include_router(audit.router, prefix=settings.API_PREFIX)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
