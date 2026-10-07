# NYLEX Backend API

FastAPI-powered REST & WebSocket API for NYLEX internal business management.

## Features
- **Strict Server-Side Calculations**: Invoice balance, tax, discount, revenue metrics, payment tracking.
- **Async Motor/MongoDB**: Connection pooling, automatic indexing, soft-deletes.
- **JWT & Role-Based Security**: Access tokens, refresh tokens, role checks (OWNER, PARTNER).
- **Real-Time WebSocket Chat**: Persistent messaging between internal users with unread tracking.
- **Audit Logging**: Immutable tracking of all entity changes, assignments, status transitions.
- **PDF Generation**: Built-in ReportLab generation for Quotations and Invoices.
- **Background Reminders**: Scheduled checks for follow-up reminders and due tasks.

## Setup Instructions

1. **Python Environment**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Environment Variables**:
   Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
   Provide your MongoDB Atlas URI:
   ```env
   MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/nylex_db
   ```

3. **Run the API**:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
   Open Swagger documentation at `http://localhost:8000/docs`.

4. **Initial User Seeding**:
   The database automatically seeds the two NYLEX owners on startup if no users exist:
   - User 1: `admin@nylex.online` / `NylexAdmin@2026` (Owner 1)
   - User 2: `partner@nylex.online` / `NylexPartner@2026` (Owner 2)
