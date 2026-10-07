import 'client_model.dart';

class DeliveryInfoModel {
  final String? deliveryDate;
  final String? finalPaymentStatus;
  final String? supportStartDate;
  final DomainInfoModel? domainInfo;
  final String? notes;

  DeliveryInfoModel({
    this.deliveryDate,
    this.finalPaymentStatus,
    this.supportStartDate,
    this.domainInfo,
    this.notes,
  });

  factory DeliveryInfoModel.fromJson(Map<String, dynamic> json) {
    return DeliveryInfoModel(
      deliveryDate: json['deliveryDate'],
      finalPaymentStatus: json['finalPaymentStatus'],
      supportStartDate: json['supportStartDate'],
      domainInfo: json['domainInfo'] != null ? DomainInfoModel.fromJson(json['domainInfo']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deliveryDate': deliveryDate,
      'finalPaymentStatus': finalPaymentStatus,
      'supportStartDate': supportStartDate,
      if (domainInfo != null) 'domainInfo': domainInfo!.toJson(),
      'notes': notes,
    };
  }
}

class ProjectModel {
  final String id;
  final String projectName;
  final String clientId;
  final String? clientName;
  final String? businessName;
  final String projectType;
  final String? description;
  final double quotedAmount;
  final double finalAmount;
  final double totalPaid;
  final double balanceDue;
  final String? startDate;
  final String? deadline;
  final String status; // Planning, In Progress, Review, Completed, Delivered, On Hold, Cancelled
  final String priority;
  final List<String> assignedUsers;
  final List<String> assignedUserNames;
  final DomainInfoModel? domainInfo;
  final DeliveryInfoModel? deliveryInfo;
  final String createdAt;

  ProjectModel({
    required this.id,
    required this.projectName,
    required this.clientId,
    this.clientName,
    this.businessName,
    required this.projectType,
    this.description,
    this.quotedAmount = 0.0,
    this.finalAmount = 0.0,
    this.totalPaid = 0.0,
    this.balanceDue = 0.0,
    this.startDate,
    this.deadline,
    required this.status,
    required this.priority,
    this.assignedUsers = const [],
    this.assignedUserNames = const [],
    this.domainInfo,
    this.deliveryInfo,
    required this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      projectName: json['projectName'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'],
      businessName: json['businessName'],
      projectType: json['projectType'] ?? 'Website',
      description: json['description'],
      quotedAmount: (json['quotedAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate'],
      deadline: json['deadline'],
      status: json['status'] ?? 'Planning',
      priority: json['priority'] ?? 'Medium',
      assignedUsers: List<String>.from(json['assignedUsers'] ?? []),
      assignedUserNames: List<String>.from(json['assignedUserNames'] ?? []),
      domainInfo: json['domainInfo'] != null ? DomainInfoModel.fromJson(json['domainInfo']) : null,
      deliveryInfo: json['deliveryInfo'] != null ? DeliveryInfoModel.fromJson(json['deliveryInfo']) : null,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectName': projectName,
      'clientId': clientId,
      'projectType': projectType,
      'description': description,
      'quotedAmount': quotedAmount,
      'finalAmount': finalAmount,
      'startDate': startDate,
      'deadline': deadline,
      'status': status,
      'priority': priority,
      'assignedUsers': assignedUsers,
      if (domainInfo != null) 'domainInfo': domainInfo!.toJson(),
    };
  }
}
