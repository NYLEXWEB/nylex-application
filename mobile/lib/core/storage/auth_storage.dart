import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _keyToken = "nylex_access_token";
  static const String _keyRefreshToken = "nylex_refresh_token";
  static const String _keyUser = "nylex_user_profile";
  static const String _keyBaseUrl = "nylex_base_url";

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      await _storage.write(key: _keyToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _keyToken);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    try {
      await _storage.write(key: _keyUser, value: jsonEncode(userMap));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final str = await _storage.read(key: _keyUser);
      if (str != null) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveCustomBaseUrl(String url) async {
    try {
      await _storage.write(key: _keyBaseUrl, value: url);
    } catch (_) {}
  }

  static Future<String?> getCustomBaseUrl() async {
    try {
      return await _storage.read(key: _keyBaseUrl);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAuth() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUser);
    } catch (_) {}
  }
}
