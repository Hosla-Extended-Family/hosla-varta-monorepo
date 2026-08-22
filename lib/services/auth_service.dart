import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hosla/core/constants/api_constants.dart';

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  Map<String, dynamic>? _tryDecodeJsonObject(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  String _errorMessageFromBody(String responseBody) {
    final obj = _tryDecodeJsonObject(responseBody);
    if (obj == null) return responseBody;
    final error = obj['error'];
    if (error is Map<String, dynamic>) {
      final msg = error['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return responseBody;
  }

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
    final resolvedToken = (fcmToken != null && fcmToken.isNotEmpty)
        ? fcmToken
        : (kIsWeb ? 'web_token' : 'no_fcm_token');

    final body = jsonEncode({
      'phone': phone,
      'otp': otp,
      'device': {
        'fcmToken': resolvedToken,
        'platform': _getClientPlatform(),
        'model': deviceModel ?? 'unknown',
      },
    });

    final response = await http.post(uri, headers: headers, body: body);
    final responseBody = response.body;
    debugPrint(responseBody);

    if (response.statusCode == 200) {
      final data = _tryDecodeJsonObject(responseBody);
      if (data == null) {
        throw Exception('Verify OTP failed: Invalid JSON response');
      }
      await _storeAuthResponse(data);
      return data;
    } else {
      String errorMessage;
      try {
        final decoded = json.decode(responseBody);
        errorMessage = decoded['error']?['message'] ?? decoded['message'] ?? responseBody;
      } catch (_) {
        errorMessage = responseBody;
      }
      throw Exception(errorMessage);
    }

    // Expected error shapes:
    // 401: { success:false, error:{ code:"UNAUTHORIZED", message:"Invalid or expired OTP" } }
    // 429: { success:false, error:{ code:"RATE_LIMITED", message:"Too many verification attempts" } }
    final errorObj = _tryDecodeJsonObject(responseBody);
    final error = (errorObj?['error'] is Map<String, dynamic>)
        ? (errorObj!['error'] as Map<String, dynamic>)
        : null;

    final code = error?['code']?.toString() ?? 'UNKNOWN';
    final message =
        error?['message']?.toString() ?? _errorMessageFromBody(responseBody);

    throw AuthApiException(
      statusCode: response.statusCode,
      code: code,
      message: message,
      responseBody: responseBody,
    );
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
      final data = _tryDecodeJsonObject(responseBody);
      if (data == null) {
        throw Exception('Refresh tokens failed: Invalid JSON response');
      }
      await _storeTokensFromData(
        (data['data'] as Map?)?.cast<String, dynamic>() ?? data,
      );
      return data;
    } else {
      final message = _errorMessageFromBody(responseBody);
      throw Exception('Refresh tokens failed: $message');
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
      // Expected verify-otp shape:
      // { success:true, data:{ user:{id,name,role}, accessToken, expiresIn, refreshToken, refreshExpiresIn } }
      final data =
          (apiResponse['data'] as Map?)?.cast<String, dynamic>() ?? apiResponse;
      await _storeTokensFromData(data);

      final user =
          (data['user'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final userId =
          (user['id']?.toString() ??
          user['userId']?.toString() ??
          'current_user');
      final phone = (user['phone']?.toString());
      final name = user['name']?.toString();
      final role = user['role']?.toString();

      await prefs.setString('user_id', userId);
      if (phone != null && phone.isNotEmpty) {
        await prefs.setString('phone_number', phone);
      }
      if (name != null && name.isNotEmpty) {
        await prefs.setString('user_name', name);
      }
      if (role != null && role.isNotEmpty) {
        await prefs.setString('user_role', role);
      }
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('login_time', DateTime.now().toIso8601String());
    } catch (e) {
      // do not rethrow to avoid breaking UI on storage failure
    }
  }

  Future<void> _storeTokensFromData(Map<String, dynamic>? data) async {
    if (data == null) return;
    final prefs = await SharedPreferences.getInstance();

    // New shape: { accessToken, expiresIn, refreshToken, refreshExpiresIn }
    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    final expiresIn = data['expiresIn'];
    final refreshExpiresIn = data['refreshExpiresIn'];

    if (accessToken != null && accessToken.isNotEmpty) {
      await prefs.setString('access_token', accessToken);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString('refresh_token', refreshToken);
    }
    if (expiresIn is num) {
      final exp = DateTime.now().toUtc().add(
        Duration(seconds: expiresIn.toInt()),
      );
      await prefs.setString('access_token_expires', exp.toIso8601String());
    }
    if (refreshExpiresIn is num) {
      final exp = DateTime.now().toUtc().add(
        Duration(seconds: refreshExpiresIn.toInt()),
      );
      await prefs.setString('refresh_token_expires', exp.toIso8601String());
    }

    // Backward-compatible shape: { tokens: { access: {token,expires}, refresh:{token,expires} } }
    final tokens = data['tokens'];
    if (tokens is Map) {
      final tokensMap = tokens.cast<String, dynamic>();
      final access = (tokensMap['access'] as Map?)?.cast<String, dynamic>();
      final refresh = (tokensMap['refresh'] as Map?)?.cast<String, dynamic>();

      if (access != null) {
        final token = access['token']?.toString();
        final expires = access['expires']?.toString();
        if (token != null && token.isNotEmpty) {
          await prefs.setString('access_token', token);
        }
        if (expires != null && expires.isNotEmpty) {
          await prefs.setString('access_token_expires', expires);
        }
      }
      if (refresh != null) {
        final token = refresh['token']?.toString();
        final expires = refresh['expires']?.toString();
        if (token != null && token.isNotEmpty) {
          await prefs.setString('refresh_token', token);
        }
        if (expires != null && expires.isNotEmpty) {
          await prefs.setString('refresh_token_expires', expires);
        }
      }
    }
  }

  /// Clear all auth-related SharedPreferences.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class AuthApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final String? responseBody;

  AuthApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.responseBody,
  });

  @override
  String toString() => 'AuthApiException($statusCode, $code): $message';
}
