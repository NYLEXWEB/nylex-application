class FollowupModel {
  final String id;
  final String? leadId;
  final String? leadName;
  final String? leadBusiness;
  final String? clientId;
  final String? clientName;
  final String scheduledDate;
  final String scheduledTime;
  final String method; // Call, WhatsApp, Email, Meeting, Other
  final String? notes;
  final String? assignedTo;
  final String? assignedToName;
  final int reminderMinutesBefore;
  final String status; // Pending, Completed, Cancelled, Rescheduled
  final String createdAt;

  FollowupModel({
    required this.id,
    this.leadId,
    this.leadName,
    this.leadBusiness,
    this.clientId,
    this.clientName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.method,
    this.notes,
    this.assignedTo,
    this.assignedToName,
    this.reminderMinutesBefore = 15,
    required this.status,
    required this.createdAt,
  });

  factory FollowupModel.fromJson(Map<String, dynamic> json) {
    return FollowupModel(
      id: json['id'] ?? '',
      leadId: json['leadId'],
      leadName: json['leadName'],
      leadBusiness: json['leadBusiness'],
      clientId: json['clientId'],
      clientName: json['clientName'],
      scheduledDate: json['scheduledDate'] ?? '',
      scheduledTime: json['scheduledTime'] ?? '',
      method: json['method'] ?? 'Call',
      notes: json['notes'],
      assignedTo: json['assignedTo'],
      assignedToName: json['assignedToName'],
      reminderMinutesBefore: json['reminderMinutesBefore'] ?? 15,
      status: json['status'] ?? 'Pending',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leadId': leadId,
      'clientId': clientId,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'method': method,
      'notes': notes,
      'assignedTo': assignedTo,
      'reminderMinutesBefore': reminderMinutesBefore,
      'status': status,
    };
  }
}
