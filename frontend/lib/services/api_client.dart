import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hosla/services/auth_service.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();
  final http.Client _client = http.Client();

  String _getClientPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Future<Map<String, String>> _baseHeaders({
    Map<String, String>? headers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'X-Client-Platform': _getClientPlatform(),
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
      ...?headers,
    };
  }

  Future<http.Response> _sendWithAutoRefresh(
    Future<http.Response> Function(Map<String, String>) sender, {
    Map<String, String>? headers,
  }) async {
    // First attempt
    var finalHeaders = await _baseHeaders(headers: headers);
    var response = await sender(finalHeaders);

    if (response.statusCode == 401) {
      // Try to refresh tokens and retry once
      try {
        await AuthService.instance.refreshUsingStoredToken();
        finalHeaders = await _baseHeaders(headers: headers);
        response = await sender(finalHeaders);
      } catch (_) {
        // Refresh failed; clear tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        await prefs.remove('access_token_expires');
        await prefs.remove('refresh_token');
        await prefs.remove('refresh_token_expires');
        await prefs.setBool('is_logged_in', false);
      }
    }

    return response;
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return _sendWithAutoRefresh(
      (h) => _client.get(uri, headers: h),
      headers: headers,
    );
  }

  Future<http.Response> post(
    Uri uri, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _sendWithAutoRefresh(
      (h) => _client.post(uri, headers: h, body: body),
      headers: headers,
    );
  }

  Future<http.Response> put(
    Uri uri, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _sendWithAutoRefresh(
      (h) => _client.put(uri, headers: h, body: body),
      headers: headers,
    );
  }

  Future<http.Response> delete(
    Uri uri, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _sendWithAutoRefresh(
      (h) => _client.delete(uri, headers: h, body: body),
      headers: headers,
    );
  }
}
