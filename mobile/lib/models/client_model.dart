class DomainInfoModel {
  final String? domainName;
  final String? domainExtension;
  final String? registrar;
  final String? purchaseEmail;
  final String? purchaseDate;
  final String? expiryDate;

  DomainInfoModel({
    this.domainName,
    this.domainExtension,
    this.registrar,
    this.purchaseEmail,
    this.purchaseDate,
    this.expiryDate,
  });

  factory DomainInfoModel.fromJson(Map<String, dynamic> json) {
    return DomainInfoModel(
      domainName: json['domainName'],
      domainExtension: json['domainExtension'],
      registrar: json['registrar'],
      purchaseEmail: json['purchaseEmail'],
      purchaseDate: json['purchaseDate'],
      expiryDate: json['expiryDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domainName': domainName,
      'domainExtension': domainExtension,
      'registrar': registrar,
      'purchaseEmail': purchaseEmail,
      'purchaseDate': purchaseDate,
      'expiryDate': expiryDate,
    };
  }
}

class ClientModel {
  final String id;
  final String clientName;
  final String businessName;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String? location;
  final String? address;
  final String? website;
  final String? instagram;
  final String? leadSource;
  final String? assignedTo;
  final String? assignedToName;
  final String? notes;
  final String status; // Active, Completed, Inactive
  final DomainInfoModel? domainInfo;
  final String? createdBy;
  final String? createdByName;
  final String createdAt;

  ClientModel({
    required this.id,
    required this.clientName,
    required this.businessName,
    required this.phone,
    this.whatsapp,
    this.email,
    this.location,
    this.address,
    this.website,
    this.instagram,
    this.leadSource,
    this.assignedTo,
    this.assignedToName,
    this.notes,
    required this.status,
    this.domainInfo,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] ?? '',
      clientName: json['clientName'] ?? '',
      businessName: json['businessName'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'],
      email: json['email'],
      location: json['location'],
      address: json['address'],
      website: json['website'],
      instagram: json['instagram'],
      leadSource: json['leadSource'],
      assignedTo: json['assignedTo'],
      assignedToName: json['assignedToName'],
      notes: json['notes'],
      status: json['status'] ?? 'Active',
      domainInfo: json['domainInfo'] != null ? DomainInfoModel.fromJson(json['domainInfo']) : null,
      createdBy: json['createdBy'],
      createdByName: json['createdByName'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      'businessName': businessName,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'location': location,
      'address': address,
      'website': website,
      'instagram': instagram,
      'leadSource': leadSource,
      'assignedTo': assignedTo,
      'notes': notes,
      'status': status,
      if (domainInfo != null) 'domainInfo': domainInfo!.toJson(),
    };
  }
}
