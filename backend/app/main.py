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

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing NYLEX Management API Backend...")
    await connect_to_mongo()
    yield
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
