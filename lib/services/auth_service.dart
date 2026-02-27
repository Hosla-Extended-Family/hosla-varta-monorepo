import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hosla/core/constants/api_constants.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

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

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    String? fcmToken,
    String? deviceModel,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/verify-otp');
    final headers = {
      'Content-Type': 'application/json',
      'X-Client-Platform': _getClientPlatform(),
    };
    final body = jsonEncode({
      'phone': phone,
      'otp': otp,
      'device': {
        //if (fcmToken != null)
        'fcmToken': '123456',
        'platform': _getClientPlatform(),
        'model': deviceModel ?? 'unknown',
      },
    });

    final response = await http.post(uri, headers: headers, body: body);
    final responseBody = response.body;
    print(responseBody);

    if (response.statusCode == 200) {
      final data = json.decode(responseBody) as Map<String, dynamic>;
      await _storeAuthResponse(data);
      print(data);
      return data;
    } else {
      throw Exception('Verify OTP failed: $responseBody');
    }
  }

  Future<Map<String, dynamic>> refreshTokens({
    required String refreshToken,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/auth/refresh');
    final headers = {
      'Content-Type': 'application/json',
      'X-Client-Platform': _getClientPlatform(),
    };
    final body = jsonEncode({'refreshToken': refreshToken});

    final response = await http.post(uri, headers: headers, body: body);
    final responseBody = response.body;

    if (response.statusCode == 200) {
      final data = json.decode(responseBody) as Map<String, dynamic>;
      await _storeTokensFromData(data['data']);
      return data;
    } else {
      throw Exception('Refresh tokens failed: $responseBody');
    }
  }

  Future<Map<String, dynamic>?> refreshUsingStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final rt = prefs.getString('refresh_token');
    if (rt == null || rt.isEmpty) return null;
    return await refreshTokens(refreshToken: rt);
  }

  Future<void> refreshIfExpiringSoon({
    Duration threshold = const Duration(minutes: 5),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessExpStr = prefs.getString('access_token_expires');
    final refreshExpStr = prefs.getString('refresh_token_expires');
    if (accessExpStr == null || refreshExpStr == null) return;

    DateTime? accessExp;
    DateTime? refreshExp;
    try {
      accessExp = DateTime.parse(accessExpStr);
    } catch (_) {}
    try {
      refreshExp = DateTime.parse(refreshExpStr);
    } catch (_) {}

    if (accessExp == null || refreshExp == null) return;
    final now = DateTime.now().toUtc();
    final isAccessNearExpiry = accessExp.isBefore(now.add(threshold));
    final isRefreshValid = refreshExp.isAfter(now);

    if (isAccessNearExpiry && isRefreshValid) {
      try {
        await refreshUsingStoredToken();
      } catch (_) {
        // If refresh fails, mark logged out
        await prefs.setBool('is_logged_in', false);
      }
    }
  }

  Future<void> _storeAuthResponse(Map<String, dynamic> apiResponse) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Expected shape: { success: true, data: { user, tokens, isNewUser } }
      final data = apiResponse['data'] ?? apiResponse;
      await _storeTokensFromData(data);

      final user = data['user'] ?? {};
      final userId =
          (user['id']?.toString() ??
          user['userId']?.toString() ??
          'current_user');
      final phone = user['phone']?.toString();

      await prefs.setString('user_id', userId);
      if (phone != null) {
        await prefs.setString('phone_number', phone);
      }
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('login_time', DateTime.now().toIso8601String());
    } catch (e) {
      // do not rethrow to avoid breaking UI on storage failure
    }
  }

  Future<void> _storeTokensFromData(Map<String, dynamic>? data) async {
    if (data == null) return;
    final tokens = data['tokens'] as Map<String, dynamic>?;
    if (tokens == null) return;

    final access = tokens['access'] as Map<String, dynamic>?;
    final refresh = tokens['refresh'] as Map<String, dynamic>?;

    final prefs = await SharedPreferences.getInstance();
    if (access != null) {
      final token = access['token']?.toString();
      final expires = access['expires']?.toString();
      if (token != null) await prefs.setString('access_token', token);
      if (expires != null)
        await prefs.setString('access_token_expires', expires);
    }
    if (refresh != null) {
      final token = refresh['token']?.toString();
      final expires = refresh['expires']?.toString();
      if (token != null) await prefs.setString('refresh_token', token);
      if (expires != null)
        await prefs.setString('refresh_token_expires', expires);
    }
  }

  /// Clear all auth-related SharedPreferences.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
