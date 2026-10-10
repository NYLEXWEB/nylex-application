import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/auth_storage.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user = UserModel(
    id: "USR-ADMIN",
    name: "Admin",
    email: "admin",
    role: "OWNER",
    isActive: true,
  );
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => true;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check custom baseUrl if configured
      final customUrl = await AuthStorage.getCustomBaseUrl();
      if (customUrl != null && customUrl.isNotEmpty) {
        ApiConstants.baseUrl = customUrl;
      }

      final userData = await AuthStorage.getUser();
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      } else {
        _user = UserModel(
          id: "USR-ADMIN",
          name: "Admin",
          email: "admin",
          role: "OWNER",
          isActive: true,
        );
      }
    } catch (_) {
      _user = UserModel(
        id: "USR-ADMIN",
        name: "Admin",
        email: "admin",
        role: "OWNER",
        isActive: true,
      );
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        ApiConstants.login,
        body: {'email': email.trim(), 'password': password},
        requiresAuth: false,
      );

      if (res is Map<String, dynamic>) {
        final access = res['accessToken'] as String;
        final refresh = res['refreshToken'] as String;
        final userMap = res['user'] as Map<String, dynamic>;

        await AuthStorage.saveTokens(accessToken: access, refreshToken: refresh);
        await AuthStorage.saveUser(userMap);

        _user = UserModel.fromJson(userMap);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException("Invalid response format from server.");
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.post(ApiConstants.logout);
    } catch (_) {}
    await AuthStorage.clearAuth();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
