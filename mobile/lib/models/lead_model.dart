class LeadModel {
  final String id;
  final String name;
  final String? businessName;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String? location;
  final String? serviceRequired;
  final double expectedBudget;
  final String leadSource;
  final String? assignedTo;
  final String? assignedToName;
  final String priority;
  final String status;
  final String? notes;
  final String? nextFollowUp;
  final String? convertedClientId;
  final String? convertedProjectId;
  final String createdAt;

  LeadModel({
    required this.id,
    required this.name,
    this.businessName,
    required this.phone,
    this.whatsapp,
    this.email,
    this.location,
    this.serviceRequired,
    this.expectedBudget = 0.0,
    required this.leadSource,
    this.assignedTo,
    this.assignedToName,
    required this.priority,
    required this.status,
    this.notes,
    this.nextFollowUp,
    this.convertedClientId,
    this.convertedProjectId,
    required this.createdAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      businessName: json['businessName'],
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'],
      email: json['email'],
      location: json['location'],
      serviceRequired: json['serviceRequired'],
      expectedBudget: (json['expectedBudget'] as num?)?.toDouble() ?? 0.0,
      leadSource: json['leadSource'] ?? 'Direct',
      assignedTo: json['assignedTo'],
      assignedToName: json['assignedToName'],
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'New',
      notes: json['notes'],
      nextFollowUp: json['nextFollowUp'],
      convertedClientId: json['convertedClientId'],
      convertedProjectId: json['convertedProjectId'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'businessName': businessName,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'location': location,
      'serviceRequired': serviceRequired,
      'expectedBudget': expectedBudget,
      'leadSource': leadSource,
      'assignedTo': assignedTo,
      'priority': priority,
      'status': status,
      'notes': notes,
      'nextFollowUp': nextFollowUp,
    };
  }
}
