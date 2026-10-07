class DashboardSummaryModel {
  final int totalLeads;
  final int activeClients;
  final int activeProjects;
  final int pendingFollowUps;
  final double totalRevenue;
  final double collectedRevenue;
  final double pendingPayments;

  DashboardSummaryModel({
    this.totalLeads = 0,
    this.activeClients = 0,
    this.activeProjects = 0,
    this.pendingFollowUps = 0,
    this.totalRevenue = 0.0,
    this.collectedRevenue = 0.0,
    this.pendingPayments = 0.0,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalLeads: json['totalLeads'] ?? 0,
      activeClients: json['activeClients'] ?? 0,
      activeProjects: json['activeProjects'] ?? 0,
      pendingFollowUps: json['pendingFollowUps'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      collectedRevenue: (json['collectedRevenue'] as num?)?.toDouble() ?? 0.0,
      pendingPayments: (json['pendingPayments'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardModel {
  final DashboardSummaryModel summary;
  final List<dynamic> todayFollowUps;
  final List<dynamic> tasksDueToday;
  final List<dynamic> recentProjectUpdates;
  final List<dynamic> recentPayments;
  final List<dynamic> recentMessages;

  DashboardModel({
    required this.summary,
    this.todayFollowUps = const [],
    this.tasksDueToday = const [],
    this.recentProjectUpdates = const [],
    this.recentPayments = const [],
    this.recentMessages = const [],
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      summary: DashboardSummaryModel.fromJson(json['summary'] ?? {}),
      todayFollowUps: json['todayFollowUps'] ?? [],
      tasksDueToday: json['tasksDueToday'] ?? [],
      recentProjectUpdates: json['recentProjectUpdates'] ?? [],
      recentPayments: json['recentPayments'] ?? [],
      recentMessages: json['recentMessages'] ?? [],
    );
  }
}
