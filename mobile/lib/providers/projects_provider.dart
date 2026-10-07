import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/project_model.dart';
import '../models/daily_update_model.dart';

class ProjectsProvider extends ChangeNotifier {
  List<ProjectModel> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = "All";

  List<ProjectModel> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;

  Future<void> fetchProjects({String? clientId, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    if (status != null) _selectedStatus = status;
    notifyListeners();

    try {
      var url = "${ApiConstants.projects}?";
      if (clientId != null) url += "client_id=$clientId&";
      if (_selectedStatus != "All") url += "status=$_selectedStatus&";

      final res = await ApiClient.get(url);
      if (res is List) {
        _projects = res.map((item) => ProjectModel.fromJson(item)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ProjectModel?> createProject(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.projects, body: data);
      if (res is Map<String, dynamic>) {
        final proj = ProjectModel.fromJson(res);
        _projects.insert(0, proj);
        notifyListeners();
        return proj;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<ProjectModel?> updateProject(String id, Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.put("${ApiConstants.projects}/$id", body: data);
      if (res is Map<String, dynamic>) {
        final updated = ProjectModel.fromJson(res);
        final index = _projects.indexWhere((p) => p.id == id);
        if (index != -1) {
          _projects[index] = updated;
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

  Future<ProjectModel?> deliverProject(String id, Map<String, dynamic> deliveryData) async {
    try {
      final res = await ApiClient.put(ApiConstants.projectDeliver(id), body: deliveryData);
      if (res is Map<String, dynamic>) {
        final updated = ProjectModel.fromJson(res);
        final index = _projects.indexWhere((p) => p.id == id);
        if (index != -1) {
          _projects[index] = updated;
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

  Future<List<dynamic>> fetchActivityFeed(String projectId) async {
    try {
      final res = await ApiClient.get(ApiConstants.projectActivity(projectId));
      return res is List ? res : [];
    } catch (_) {
      return [];
    }
  }

  Future<List<DailyUpdateModel>> fetchDailyUpdates(String projectId) async {
    try {
      final res = await ApiClient.get("${ApiConstants.updates}?project_id=$projectId");
      if (res is List) {
        return res.map((u) => DailyUpdateModel.fromJson(u)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<DailyUpdateModel?> postDailyUpdate(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.updates, body: data);
      if (res is Map<String, dynamic>) {
        return DailyUpdateModel.fromJson(res);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }
}
