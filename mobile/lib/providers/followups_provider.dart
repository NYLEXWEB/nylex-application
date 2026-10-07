import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../models/followup_model.dart';

class FollowupsProvider extends ChangeNotifier {
  List<FollowupModel> _followups = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _filterToday = false;

  List<FollowupModel> get followups => _followups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get filterToday => _filterToday;

  Future<void> fetchFollowups({bool? todayOnly, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    if (todayOnly != null) _filterToday = todayOnly;
    notifyListeners();

    try {
      var url = "${ApiConstants.followups}?";
      if (_filterToday) url += "is_today=true&";
      if (status != null && status != "All") url += "status=$status&";

      final res = await ApiClient.get(url);
      if (res is List) {
        _followups = res.map((f) => FollowupModel.fromJson(f)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FollowupModel?> createFollowup(Map<String, dynamic> data) async {
    try {
      final res = await ApiClient.post(ApiConstants.followups, body: data);
      if (res is Map<String, dynamic>) {
        final flp = FollowupModel.fromJson(res);
        _followups.insert(0, flp);
        notifyListeners();
        return flp;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
    return null;
  }

  Future<void> completeFollowup(String id) async {
    try {
      await ApiClient.put(ApiConstants.followupComplete(id));
      final index = _followups.indexWhere((f) => f.id == id);
      if (index != -1) {
        final current = _followups[index];
        _followups[index] = FollowupModel(
          id: current.id,
          leadId: current.leadId,
          leadName: current.leadName,
          leadBusiness: current.leadBusiness,
          clientId: current.clientId,
          clientName: current.clientName,
          scheduledDate: current.scheduledDate,
          scheduledTime: current.scheduledTime,
          method: current.method,
          notes: current.notes,
          assignedTo: current.assignedTo,
          assignedToName: current.assignedToName,
          reminderMinutesBefore: current.reminderMinutesBefore,
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
}
