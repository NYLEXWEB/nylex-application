import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 60);

  static Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (requiresAuth) {
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }
    return headers;
  }

  static Future<dynamic> get(String url, {bool requiresAuth = true}) async {
    try {
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client.get(Uri.parse(url), headers: headers).timeout(_timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException("Unable to connect to NYLEX server. Please check your network connection.");
    } on TimeoutException {
      throw ApiException("Request timed out. Please try again.");
    }
  }

  static Future<dynamic> post(String url, {dynamic body, bool requiresAuth = true}) async {
    try {
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException("Unable to connect to NYLEX server. Please check your network connection.");
    } on TimeoutException {
      throw ApiException("Request timed out. Please try again.");
    }
  }

  static Future<dynamic> put(String url, {dynamic body, bool requiresAuth = true}) async {
    try {
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException("Unable to connect to NYLEX server. Please check your network connection.");
    } on TimeoutException {
      throw ApiException("Request timed out. Please try again.");
    }
  }

  static Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    try {
      final headers = await _headers(requiresAuth: requiresAuth);
      final response = await _client.delete(Uri.parse(url), headers: headers).timeout(_timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException("Unable to connect to NYLEX server. Please check your network connection.");
    } on TimeoutException {
      throw ApiException("Request timed out. Please try again.");
    }
  }

  static dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } catch (_) {
      body = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else if (response.statusCode == 401) {
      AuthStorage.clearAuth();
      final msg = body is Map ? (body["detail"] ?? "Invalid email or password.") : "Invalid email or password.";
      throw ApiException(msg.toString(), statusCode: 401);
    } else if (response.statusCode == 403) {
      throw ApiException("Access denied: You do not have permission for this action.", statusCode: 403);
    } else if (response.statusCode == 404) {
      throw ApiException("Resource not found.", statusCode: 404);
    } else if (response.statusCode == 422) {
      if (body is Map && body.containsKey("errors")) {
        final errs = body["errors"];
        if (errs is List) {
          throw ApiException(errs.join("\n"), statusCode: 422);
        }
      }
      final msg = body is Map ? (body["detail"] ?? "Validation failed") : "Validation failed";
      throw ApiException(msg.toString(), statusCode: 422);
    } else {
      final msg = body is Map ? (body["detail"] ?? "Server error occurred.") : "Server error occurred.";
      throw ApiException(msg.toString(), statusCode: response.statusCode);
    }
  }
}
