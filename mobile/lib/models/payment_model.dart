class PaymentModel {
  final String id;
  final String paymentNumber;
  final String clientId;
  final String? clientName;
  final String? businessName;
  final String? projectId;
  final String? projectName;
  final String? invoiceId;
  final String? invoiceNumber;
  final double amount;
  final String paymentDate;
  final String paymentMethod;
  final String paymentType;
  final String? referenceNumber;
  final String? notes;
  final String? receivedBy;
  final String? receivedByName;
  final String createdAt;

  PaymentModel({
    required this.id,
    required this.paymentNumber,
    required this.clientId,
    this.clientName,
    this.businessName,
    this.projectId,
    this.projectName,
    this.invoiceId,
    this.invoiceNumber,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.paymentType = "Advance",
    this.referenceNumber,
    this.notes,
    this.receivedBy,
    this.receivedByName,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      paymentNumber: json['paymentNumber'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'],
      businessName: json['businessName'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      invoiceId: json['invoiceId'],
      invoiceNumber: json['invoiceNumber'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentDate: json['paymentDate'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'UPI',
      paymentType: json['paymentType'] ?? 'Advance',
      referenceNumber: json['referenceNumber'],
      notes: json['notes'],
      receivedBy: json['receivedBy'],
      receivedByName: json['receivedByName'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'projectId': projectId,
      'invoiceId': invoiceId,
      'amount': amount,
      'paymentDate': paymentDate,
      'paymentMethod': paymentMethod,
      'paymentType': paymentType,
      'referenceNumber': referenceNumber,
      'notes': notes,
    };
  }
}
