class ApiConstants {
  // Configurable base URL: can be switched between Localhost, LAN, or Production
  static const String defaultBaseUrl = "http://localhost:8000";
  static const String productionBaseUrl = "https://api.nylex.online";

  static String baseUrl = defaultBaseUrl;

  // Authentication
  static String get login => "$baseUrl/api/auth/login";
  static String get logout => "$baseUrl/api/auth/logout";
  static String get refresh => "$baseUrl/api/auth/refresh";
  static String get me => "$baseUrl/api/auth/me";

  // Dashboard
  static String get dashboard => "$baseUrl/api/dashboard";

  // Users
  static String get users => "$baseUrl/api/users";
  static String get userPresence => "$baseUrl/api/users/presence";

  // Clients
  static String get clients => "$baseUrl/api/clients";
  static String clientTimeline(String id) => "$baseUrl/api/clients/$id/timeline";

  // Leads
  static String get leads => "$baseUrl/api/leads";
  static String leadStatus(String id) => "$baseUrl/api/leads/$id/status";
  static String leadConvert(String id) => "$baseUrl/api/leads/$id/convert";

  // Follow-ups
  static String get followups => "$baseUrl/api/followups";
  static String followupComplete(String id) => "$baseUrl/api/followups/$id/complete";

  // Projects
  static String get projects => "$baseUrl/api/projects";
  static String projectDeliver(String id) => "$baseUrl/api/projects/$id/deliver";
  static String projectActivity(String id) => "$baseUrl/api/projects/$id/activity";

  // Tasks
  static String get tasks => "$baseUrl/api/tasks";
  static String taskComplete(String id) => "$baseUrl/api/tasks/$id/complete";
  static String taskReopen(String id) => "$baseUrl/api/tasks/$id/reopen";

  // Daily Updates
  static String get updates => "$baseUrl/api/updates";

  // Quotations
  static String get quotations => "$baseUrl/api/quotations";
  static String quotationPdf(String id) => "$baseUrl/api/quotations/$id/pdf";

  // Invoices
  static String get invoices => "$baseUrl/api/invoices";
  static String invoicePdf(String id) => "$baseUrl/api/invoices/$id/pdf";

  // Payments
  static String get payments => "$baseUrl/api/payments";

  // Revenue
  static String get revenue => "$baseUrl/api/revenue";

  // Notifications
  static String get notifications => "$baseUrl/api/notifications";
  static String get notificationsReadAll => "$baseUrl/api/notifications/read-all";
  static String notificationRead(String id) => "$baseUrl/api/notifications/$id/read";
  static String get notificationUnreadCount => "$baseUrl/api/notifications/unread-count";

  // Chat
  static String get chatMessages => "$baseUrl/api/chat/messages";
  static String get chatRead => "$baseUrl/api/chat/read";
  static String get chatUnreadCount => "$baseUrl/api/chat/unread-count";
  static String chatWs(String userId) {
    final wsBase = baseUrl.replaceFirst("http://", "ws://").replaceFirst("https://", "wss://");
    return "$wsBase/api/chat/ws/$userId";
  }

  // Search
  static String get search => "$baseUrl/api/search";

  // Audit Logs
  static String get auditLogs => "$baseUrl/api/audit-logs";
}
