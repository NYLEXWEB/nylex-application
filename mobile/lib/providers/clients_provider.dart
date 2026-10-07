import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/client_model.dart';

class ClientsProvider extends ChangeNotifier {
  List<ClientModel> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = "All";
  String _searchQuery = "";

  List<ClientModel> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;

  Future<void> fetchClients({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    if (status != null) _selectedStatus = status;
    if (search != null) _searchQuery = search;
    notifyListeners();

    try {
      var url = "${ApiConstants.clients}?";
      if (_selectedStatus != "All") url += "status=$_selectedStatus&";
      if (_searchQuery.isNotEmpty) url += "search=$_searchQuery&";

      final res = await ApiClient.get(url);
      if (res is List) {
        _clients = res.map((item) => ClientModel.fromJson(item)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ClientModel?> createClient(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.clients, body: data);
      if (res is Map<String, dynamic>) {
        final client = ClientModel.fromJson(res);
        _clients.insert(0, client);
        notifyListeners();
        return client;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<ClientModel?> updateClient(String id, Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.put("${ApiConstants.clients}/$id", body: data);
      if (res is Map<String, dynamic>) {
        final updated = ClientModel.fromJson(res);
        final index = _clients.indexWhere((c) => c.id == id);
        if (index != -1) {
          _clients[index] = updated;
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

  Future<void> archiveClient(String id) async {
    try {
      await ApiClient.delete("${ApiConstants.clients}/$id");
      _clients.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<dynamic>> fetchClientTimeline(String clientId) async {
    try {
      final res = await ApiClient.get(ApiConstants.clientTimeline(clientId));
      return res is List ? res : [];
    } catch (_) {
      return [];
    }
  }
}
