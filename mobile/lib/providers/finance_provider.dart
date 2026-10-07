import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/quotation_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';

class FinanceProvider extends ChangeNotifier {
  List<QuotationModel> _quotations = [];
  List<InvoiceModel> _invoices = [];
  List<PaymentModel> _payments = [];
  Map<String, dynamic> _revenueData = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<QuotationModel> get quotations => _quotations;
  List<InvoiceModel> get invoices => _invoices;
  List<PaymentModel> get payments => _payments;
  Map<String, dynamic> get revenueData => _revenueData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchQuotations({String? clientId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var url = ApiConstants.quotations;
      if (clientId != null) url += "?client_id=$clientId";
      final res = await ApiClient.get(url);
      if (res is List) {
        _quotations = res.map((q) => QuotationModel.fromJson(q)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<QuotationModel?> createQuotation(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.quotations, body: data);
      if (res is Map<String, dynamic>) {
        final q = QuotationModel.fromJson(res);
        _quotations.insert(0, q);
        notifyListeners();
        return q;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<void> fetchInvoices({String? clientId, String? projectId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var url = "${ApiConstants.invoices}?";
      if (clientId != null) url += "client_id=$clientId&";
      if (projectId != null) url += "project_id=$projectId&";

      final res = await ApiClient.get(url);
      if (res is List) {
        _invoices = res.map((inv) => InvoiceModel.fromJson(inv)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<InvoiceModel?> createInvoice(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.invoices, body: data);
      if (res is Map<String, dynamic>) {
        final inv = InvoiceModel.fromJson(res);
        _invoices.insert(0, inv);
        notifyListeners();
        return inv;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<void> fetchPayments({String? clientId, String? invoiceId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var url = "${ApiConstants.payments}?";
      if (clientId != null) url += "client_id=$clientId&";
      if (invoiceId != null) url += "invoice_id=$invoiceId&";

      final res = await ApiClient.get(url);
      if (res is List) {
        _payments = res.map((p) => PaymentModel.fromJson(p)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PaymentModel?> recordPayment(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.payments, body: data);
      if (res is Map<String, dynamic>) {
        final pay = PaymentModel.fromJson(res);
        _payments.insert(0, pay);
        // Refresh invoices and revenue if updated
        await fetchInvoices();
        await fetchRevenue();
        notifyListeners();
        return pay;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<void> fetchRevenue({String period = "all"}) async {
    try {
      final res = await ApiClient.get("${ApiConstants.revenue}?period=$period");
      if (res is Map<String, dynamic>) {
        _revenueData = res;
        notifyListeners();
      }
    } catch (_) {}
  }
}
