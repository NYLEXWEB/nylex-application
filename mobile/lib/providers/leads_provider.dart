import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/lead_model.dart';

class LeadsProvider extends ChangeNotifier {
  List<LeadModel> _leads = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = "All";
  String _searchQuery = "";

  List<LeadModel> get leads => _leads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;

  Future<void> fetchLeads({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    if (status != null) _selectedStatus = status;
    if (search != null) _searchQuery = search;
    notifyListeners();

    try {
      var url = "${ApiConstants.leads}?";
      if (_selectedStatus != "All") url += "status=$_selectedStatus&";
      if (_searchQuery.isNotEmpty) url += "search=$_searchQuery&";

      final res = await ApiClient.get(url);
      if (res is List) {
        _leads = res.map((item) => LeadModel.fromJson(item)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LeadModel?> createLead(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.leads, body: data);
      if (res is Map<String, dynamic>) {
        final lead = LeadModel.fromJson(res);
        _leads.insert(0, lead);
        notifyListeners();
        return lead;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<LeadModel?> updateLead(String id, Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.put("${ApiConstants.leads}/$id", body: data);
      if (res is Map<String, dynamic>) {
        final updated = LeadModel.fromJson(res);
        final index = _leads.indexWhere((l) => l.id == id);
        if (index != -1) {
          _leads[index] = updated;
          notifyListeners();
        }
        return updated;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<void> changeLeadStatus(String id, String newStatus, {String? notes}) async {
    try {
      final res = await ApiClient.put(
        ApiConstants.leadStatus(id),
        body: {'status': newStatus, 'notes': notes},
      );
      if (res is Map<String, dynamic>) {
        final updated = LeadModel.fromJson(res);
        final index = _leads.indexWhere((l) => l.id == id);
        if (index != -1) {
          _leads[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> convertLeadToClient(String id, Map<String, dynamic> convertData) async {
    try {
      final res = await ApiClient.post(ApiConstants.leadConvert(id), body: convertData);
      if (res is Map<String, dynamic>) {
        // Refresh leads list
        await fetchLeads();
        return res;
      }
      return {};
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> archiveLead(String id) async {
    try {
      await ApiClient.delete("${ApiConstants.leads}/$id");
      _leads.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
