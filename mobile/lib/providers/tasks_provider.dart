import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/task_model.dart';

class TasksProvider extends ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = "All";

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;

  Future<void> fetchTasks({String? projectId, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    if (status != null) _selectedStatus = status;
    notifyListeners();

    try {
      var url = "${ApiConstants.tasks}?";
      if (projectId != null) url += "project_id=$projectId&";
      if (_selectedStatus != "All") url += "status=$_selectedStatus&";

      final res = await ApiClient.get(url);
      if (res is List) {
        _tasks = res.map((t) => TaskModel.fromJson(t)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TaskModel?> createTask(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.tasks, body: data);
      if (res is Map<String, dynamic>) {
        final task = TaskModel.fromJson(res);
        _tasks.insert(0, task);
        notifyListeners();
        return task;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<void> completeTask(String id) async {
    try {
      await ApiClient.put(ApiConstants.taskComplete(id));
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final current = _tasks[index];
        _tasks[index] = TaskModel(
          id: current.id,
          projectId: current.projectId,
          projectName: current.projectName,
          title: current.title,
          description: current.description,
          assignedTo: current.assignedTo,
          assignedToName: current.assignedToName,
          priority: current.priority,
          dueDate: current.dueDate,
          status: "Completed",
          createdAt: current.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reopenTask(String id) async {
    try {
      await ApiClient.put(ApiConstants.taskReopen(id));
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        final current = _tasks[index];
        _tasks[index] = TaskModel(
          id: current.id,
          projectId: current.projectId,
          projectName: current.projectName,
          title: current.title,
          description: current.description,
          assignedTo: current.assignedTo,
          assignedToName: current.assignedToName,
          priority: current.priority,
          dueDate: current.dueDate,
          status: "In Progress",
          createdAt: current.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await ApiClient.delete("${ApiConstants.tasks}/$id");
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
