import logging
import asyncio
from typing import Optional
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from app.core.config import settings

logger = logging.getLogger("nylex.database")

class Database:
    client: Optional[AsyncIOMotorClient] = None
    db: Optional[AsyncIOMotorDatabase] = None

db_instance = Database()

async def connect_to_mongo():
    logger.info("Connecting to MongoDB...")
    try:
        db_instance.client = AsyncIOMotorClient(
            settings.MONGODB_URI,
            serverSelectionTimeoutMS=5000,
            connectTimeoutMS=5000,
        )
        db_instance.db = db_instance.client[settings.DATABASE_NAME]
        
        # Test connection ping
        await db_instance.client.admin.command('ping')
        logger.info("Successfully connected to MongoDB Atlas / Server.")
    except Exception as e:
        logger.warning(f"MongoDB connection ping failed or timed out: {e}. Running with database client configured.")
        # We still configure db_instance.db so routes have access
        if db_instance.client:
            db_instance.db = db_instance.client[settings.DATABASE_NAME]

    # Initialize indexes and default users
    try:
        await create_indexes()
        await seed_initial_users()
    except Exception as e:
        logger.warning(f"Database initialization step: {e}")

async def close_mongo_connection():
    if db_instance.client:
        logger.info("Closing MongoDB connection...")
        db_instance.client.close()
        logger.info("MongoDB connection closed.")

def get_database() -> AsyncIOMotorDatabase:
    if db_instance.db is None:
        if db_instance.client is None:
            db_instance.client = AsyncIOMotorClient(settings.MONGODB_URI)
        db_instance.db = db_instance.client[settings.DATABASE_NAME]
    return db_instance.db

async def create_indexes():
    db = get_database()
    try:
        # Users
        await db.users.create_index("id", unique=True)
        await db.users.create_index("email", unique=True)
        
        # Clients
        await db.clients.create_index("id", unique=True)
        await db.clients.create_index("phone")
        await db.clients.create_index("businessName")
        await db.clients.create_index("status")
        await db.clients.create_index([("isDeleted", 1), ("createdAt", -1)])
        
        # Leads
        await db.leads.create_index("id", unique=True)
        await db.leads.create_index("phone")
        await db.leads.create_index("status")
        await db.leads.create_index("priority")
        await db.leads.create_index("assignedTo")
        await db.leads.create_index("nextFollowUp")
        await db.leads.create_index([("isDeleted", 1), ("createdAt", -1)])
        
        # Follow-ups
        await db.followups.create_index("id", unique=True)
        await db.followups.create_index("leadId")
        await db.followups.create_index("assignedTo")
        await db.followups.create_index("status")
        await db.followups.create_index("scheduledDate")
        
        # Projects
        await db.projects.create_index("id", unique=True)
        await db.projects.create_index("clientId")
        await db.projects.create_index("status")
        await db.projects.create_index("assignedUsers")
        await db.projects.create_index([("isDeleted", 1), ("createdAt", -1)])
        
        # Tasks
        await db.tasks.create_index("id", unique=True)
        await db.tasks.create_index("projectId")
        await db.tasks.create_index("assignedTo")
        await db.tasks.create_index("status")
        await db.tasks.create_index("dueDate")
        
        # Daily updates
        await db.daily_updates.create_index("id", unique=True)
        await db.daily_updates.create_index("projectId")
        await db.daily_updates.create_index("userId")
        await db.daily_updates.create_index("createdAt")
        
        # Quotations
        await db.quotations.create_index("id", unique=True)
        await db.quotations.create_index("quotationNumber", unique=True)
        await db.quotations.create_index("clientId")
        await db.quotations.create_index("status")
        
        # Invoices
        await db.invoices.create_index("id", unique=True)
        await db.invoices.create_index("invoiceNumber", unique=True)
        await db.invoices.create_index("clientId")
        await db.invoices.create_index("projectId")
        await db.invoices.create_index("status")
        
        # Payments
        await db.payments.create_index("id", unique=True)
        await db.payments.create_index("invoiceId")
        await db.payments.create_index("clientId")
        await db.payments.create_index("projectId")
        await db.payments.create_index("paymentDate")
        
        # Notifications
        await db.notifications.create_index("id", unique=True)
        await db.notifications.create_index([("userId", 1), ("isRead", 1), ("createdAt", -1)])
        
        # Chat Messages
        await db.messages.create_index("id", unique=True)
        await db.messages.create_index([("createdAt", 1)])
        await db.messages.create_index([("senderId", 1), ("recipientId", 1)])
        
        # Audit Logs
        await db.audit_logs.create_index("id", unique=True)
        await db.audit_logs.create_index([("timestamp", -1)])
        await db.audit_logs.create_index([("entityType", 1), ("entityId", 1)])
        
        logger.info("MongoDB indexes verified.")
    except Exception as e:
        logger.warning(f"Error creating MongoDB indexes: {e}")

async def seed_initial_users():
    from app.core.security import get_password_hash
    from datetime import datetime, timezone
    db = get_database()
    try:
        user_count = await db.users.count_documents({})
        if user_count == 0:
            now = datetime.now(timezone.utc).isoformat()
            users = [
                {
                    "id": "USR-001",
                    "name": "Druva (Owner 1)",
                    "email": "druva@nylex.online",
                    "phone": "+91 98765 43210",
                    "hashedPassword": get_password_hash("NylexDruva@2026"),
                    "role": "OWNER",
                    "isActive": True,
                    "isDeleted": False,
                    "createdAt": now,
                    "updatedAt": now,
                    "lastLoginAt": None,
                },
                {
                    "id": "USR-002",
                    "name": "Partner (Owner 2)",
                    "email": "partner@nylex.online",
                    "phone": "+91 98765 43211",
                    "hashedPassword": get_password_hash("NylexPartner@2026"),
                    "role": "PARTNER",
                    "isActive": True,
                    "isDeleted": False,
                    "createdAt": now,
                    "updatedAt": now,
                    "lastLoginAt": None,
                }
            ]
            await db.users.insert_many(users)
            logger.info("Default NYLEX users seeded successfully.")
    except Exception as e:
        logger.warning(f"Failed to seed initial users: {e}")
