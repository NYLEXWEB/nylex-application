import 'quotation_model.dart';

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String clientId;
  final String? clientName;
  final String? businessName;
  final String? projectId;
  final String? projectName;
  final String invoiceDate;
  final String dueDate;
  final List<LineItemModel> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double taxRate;
  final double total;
  final double paidAmount;
  final double balanceAmount;
  final String status; // Draft, Sent, Partially Paid, Paid, Overdue, Cancelled
  final String? notes;
  final String? pdfUrl;
  final String createdAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    this.clientName,
    this.businessName,
    this.projectId,
    this.projectName,
    required this.invoiceDate,
    required this.dueDate,
    this.items = const [],
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.taxRate = 0.0,
    this.total = 0.0,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    required this.status,
    this.notes,
    this.pdfUrl,
    required this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'],
      businessName: json['businessName'],
      projectId: json['projectId'],
      projectName: json['projectName'],
      invoiceDate: json['invoiceDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => LineItemModel.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json['balanceAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Draft',
      notes: json['notes'],
      pdfUrl: json['pdfUrl'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'projectId': projectId,
      'invoiceDate': invoiceDate,
      'dueDate': dueDate,
      'items': items.map((e) => e.toJson()).toList(),
      'discount': discount,
      'taxRate': taxRate,
      'notes': notes,
      'status': status,
    };
  }
}
