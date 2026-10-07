# NYLEX Mobile Application

Flutter mobile client for **NYLEX** internal agency business operations.

## Technologies
- **Flutter & Dart**: Clean Architecture, Material 3
- **State Management**: Provider with reactive ChangeNotifiers
- **HTTP Client**: Centralized `ApiClient` with Bearer JWT tokens, automatic session expiry handling & clean user-facing error dialogs
- **Secure Storage**: `flutter_secure_storage` for credentials and tokens
- **Real-time Engine**: WebSockets for text chat, typing indicators, and instant notification dispatch
- **PDF Integration**: Backend-generated PDF endpoints for Quotations and Invoices

---

## Getting Started

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure API URL**:
   By default, the app communicates with `http://localhost:8000` (or Android emulator IP `10.0.2.2:8000`).
   You can easily switch to your local network IP or production `https://api.nylex.online` right inside the login screen by tapping the **Settings icon** on the top right of the login screen.

3. **Run Mobile App**:
   ```bash
   flutter run
   ```

4. **Default Credentials**:
   - **Owner 1 (Druva)**: `druva@nylex.online` / `NylexDruva@2026`
   - **Owner 2 (Partner)**: `partner@nylex.online` / `NylexPartner@2026`
   (Quick login buttons are available right on the login screen for testing convenience).
