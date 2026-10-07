class LineItemModel {
  final String description;
  final double quantity;
  final double rate;
  final double amount;

  LineItemModel({
    required this.description,
    this.quantity = 1.0,
    this.rate = 0.0,
    this.amount = 0.0,
  });

  factory LineItemModel.fromJson(Map<String, dynamic> json) {
    return LineItemModel(
      description: json['description'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
    };
  }
}

class QuotationModel {
  final String id;
  final String quotationNumber;
  final String clientId;
  final String? clientName;
  final String? businessName;
  final String? projectId;
  final String? projectName;
  final String quotationDate;
  final String? validUntil;
  final List<LineItemModel> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double taxRate;
  final double total;
  final String? notes;
  final String status; // Draft, Sent, Accepted, Rejected, Expired
  final String? pdfUrl;
  final String createdAt;

  QuotationModel({
    required this.id,
    required this.quotationNumber,
    required this.clientId,
    this.clientName,
    this.businessName,
    this.projectId,
    this.projectName,
    required this.quotationDate,
    this.validUntil,
    this.items = const [],
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.taxRate = 0.0,
    this.total = 0.0,
    this.notes,
    required this.status,
    this.pdfUrl,
    required this.createdAt,
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'],
      businessName: json['businessName'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      quotationDate: json['quotationDate'] ?? '',
      validUntil: json['validUntil'],
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => LineItemModel.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'],
      status: json['status'] ?? 'Draft',
      pdfUrl: json['pdfUrl'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'projectId': projectId,
      'quotationDate': quotationDate,
      'validUntil': validUntil,
      'items': items.map((e) => e.toJson()).toList(),
      'discount': discount,
      'taxRate': taxRate,
      'notes': notes,
      'status': status,
    };
  }
}
