# NYLEX Management System (V1)

Production-ready internal business management application for **NYLEX**, built specifically for two internal owners/partners to manage the complete end-to-end agency lifecycle:

```
LEAD → FOLLOW-UP → NEGOTIATION → QUOTATION → WON → CLIENT → PROJECT → TASKS + DAILY UPDATES → INVOICE → PAYMENT → DELIVERY
```

---

## Architecture Overview

- **Mobile Client (`mobile/`)**: Flutter (Dart 3.x, Material 3, Riverpod/Provider state, GoRouter navigation, Dio/HTTP API client, Secure Storage, Real-time WebSockets, PDF viewer).
- **Backend API (`backend/`)**: FastAPI, Python 3.13, Pydantic, Motor (Async MongoDB), JWT authentication, bcrypt password hashing, WebSocket real-time internal messaging, ReportLab PDF generation for Quotations & Invoices, Audit Logging, and Background Reminder Engine.
- **Database**: MongoDB Atlas (Strict server-side authoritative calculations, indexing, soft-deletes).

---

## Directory Structure

```
Nylex Application/
├── mobile/                  # Flutter mobile application
│   ├── lib/
│   │   ├── core/           # Constants, networking, theme, utilities
│   │   ├── models/         # Strongly-typed data models
│   │   ├── services/       # API, WebSocket & local storage services
│   │   ├── providers/      # State management providers
│   │   └── ui/             # Screens, dialogs, widgets, theme
│   ├── pubspec.yaml
│   └── README.md
│
├── backend/                 # FastAPI backend server
│   ├── app/
│   │   ├── core/           # Config, Security, Database
│   │   ├── models/         # Domain models
│   │   ├── schemas/        # Pydantic request/response schemas
│   │   ├── routes/         # Modular REST & WebSocket endpoints
│   │   ├── services/       # Business logic (Finances, PDFs, Leads, Audit)
│   │   ├── websocket/      # Real-time chat connection manager
│   │   └── utils/          # Helpers & code generators
│   ├── requirements.txt
│   ├── .env.example
│   ├── Dockerfile
│   └── README.md
│
├── .gitignore
└── README.md
```

---

## Getting Started

### 1. Backend Setup
See [backend/README.md](backend/README.md) for full instructions:
```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your MongoDB Atlas URI & JWT secrets
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Mobile Setup
See [mobile/README.md](mobile/README.md) for full instructions:
```bash
cd mobile
flutter pub get
flutter run
```
