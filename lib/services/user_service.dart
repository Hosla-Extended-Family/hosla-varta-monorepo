import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hosla/core/constants/api_constants.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/services/api_client.dart';
import 'package:hosla/services/database_helper.dart';
import 'package:http/http.dart' as _httpClient;
import 'package:shared_preferences/shared_preferences.dart';

/// Service class for handling user-related API calls and settings management
/// Implements offline-first approach with local database and SharedPreferences caching
class UserService {
  // TODO: Add HTTP client dependency injection
  // final http.Client _httpClient;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiClient _api = ApiClient.instance;

  /// Dummy app settings for testing
  static AppSettings _dummySettings = const AppSettings(
    notificationsEnabled: true,
    soundEnabled: true,
    vibrationEnabled: false,
    locationEnabled: true,
    language: 'English',
    darkMode: false,
    privateProfile: false,
  );

  /// Get current user profile
  /// Implements offline-first: returns cached user, then syncs with API
  Future<User?> getCurrentUser() async {
    try {
      // Try to get cached user from local database
      final prefs = await SharedPreferences.getInstance();
      final cachedId = prefs.getString('user_id') ?? 'current_user';
      final cachedUser = await _dbHelper.getUserById(cachedId);
      try {
        final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/profile');
        final response = await _api.get(uri);
        if (response.statusCode == 200) {
          final body = json.decode(response.body) as Map<String, dynamic>;
          final userMap = _extractUserMap(body);
          if (userMap != null) {
            final user = _mapBackendUser(userMap);
            await _dbHelper.upsertUser(user);
            await _cacheUserPrefs(user);
            await _cacheProfileMeta(userMap);
            return user;
          }
        }
        if (response.statusCode == 401) {
          return null;
        }
      } catch (e) {
        print('Network error, using cached user: $e');
      }

      return cachedUser;
    } catch (e) {
      print('Error loading current user: $e');
      return null;
    }
  }

  /// Update user profile
  /// Updates local database first, then syncs with API
  Future<User> updateUserProfile(
    User user, {
    DateTime? dateOfBirth,
    String? gender,
    String? profileImagePath,
  }) async {
    try {
      // Update local database immediately
      await _dbHelper.upsertUser(user);

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token') ?? '';

        final resolvedGender = gender ?? prefs.getString('user_gender');
        DateTime? resolvedDob = dateOfBirth;
        if (resolvedDob == null) {
          final dobStr = prefs.getString('user_dob');
          if (dobStr != null && dobStr.isNotEmpty) {
            try {
              resolvedDob = DateTime.parse(dobStr);
            } catch (_) {}
          }
        }

        if (resolvedGender == null || resolvedGender.isEmpty) {
          throw Exception('Missing required field: gender');
        }
        if (resolvedDob == null) {
          throw Exception('Missing required field: dateOfBirth');
        }

        final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/profile');
        final request = _httpClient.MultipartRequest('PUT', uri);
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['X-Client-Platform'] = _getClientPlatform();

        request.fields['name'] = user.name;
        request.fields['gender'] = resolvedGender.toUpperCase();
        request.fields['dateOfBirth'] = _formatDobForServer(resolvedDob);
        if (user.email != null && user.email!.isNotEmpty) {
          request.fields['email'] = user.email!;
        }
        if (user.bio != null && user.bio!.isNotEmpty) {
          request.fields['bio'] = user.bio!;
        }

        final imagePath = profileImagePath;
        if (imagePath != null && imagePath.isNotEmpty) {
          final isRemote =
              imagePath.startsWith('http://') ||
              imagePath.startsWith('https://');
          if (!isRemote) {
            final file = await _httpClient.MultipartFile.fromPath(
              'profilePicture',
              imagePath,
            );
            request.files.add(file);
          }
        }

        final streamed = await request.send();
        final response = await _httpClient.Response.fromStream(streamed);
        if (response.statusCode == 200) {
          final body = json.decode(response.body) as Map<String, dynamic>;
          final userMap = _extractUserMap(body);
          if (userMap != null) {
            final serverUser = _mapBackendUser(userMap);
            await _dbHelper.upsertUser(serverUser);
            await _cacheUserPrefs(serverUser);
            await _cacheProfileMeta(userMap);
            return serverUser;
          }
        }
      } catch (e) {
        //Network error - already updated locally
        print('Network error updating profile, saved locally: $e');
      }
      return user;
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Update user avatar
  /// TODO: Implement actual API call with file upload
  /// Example: POST /api/user/avatar (multipart/form-data)
  Future<String> updateUserAvatar(String avatarUrl) async {
    // TODO: Replace with actual HTTP request
    // final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/user/avatar'));
    // request.files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
    // final response = await request.send();
    // if (response.statusCode == 200) {
    //   final responseBody = await response.stream.bytesToString();
    //   final json = json.decode(responseBody);
    //   return json['avatarUrl'];
    // }
    // throw Exception('Failed to update avatar');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return avatarUrl;
  }

  /// Change user password
  /// TODO: Implement actual API call
  /// Example: PUT /api/user/password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.put(
    //   Uri.parse('$baseUrl/user/password'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({
    //     'currentPassword': currentPassword,
    //     'newPassword': newPassword,
    //   }),
    // );
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to change password');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Get app settings
  /// Implements offline-first: returns cached settings from SharedPreferences
  Future<AppSettings> getAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('app_settings');

      if (settingsJson != null) {
        final settings = AppSettings.fromJson(jsonDecode(settingsJson));
        return settings;
      }

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.get(Uri.parse('$baseUrl/user/settings'));
      //   if (response.statusCode == 200) {
      //     final settings = AppSettings.fromJson(json.decode(response.body));
      //     // Cache the fetched settings
      //     await prefs.setString('app_settings', jsonEncode(settings.toJson()));
      //     return settings;
      //   }
      // } catch (e) {
      //   print('Network error, using default settings: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Save default settings
      await prefs.setString(
        'app_settings',
        jsonEncode(_dummySettings.toJson()),
      );
      return _dummySettings;
    } catch (e) {
      print('Error loading app settings: $e');
      return _dummySettings;
    }
  }

  /// Update app settings
  /// Updates SharedPreferences first, then syncs with API
  Future<AppSettings> updateAppSettings(AppSettings settings) async {
    try {
      // Update SharedPreferences immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', jsonEncode(settings.toJson()));

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.put(
      //     Uri.parse('$baseUrl/user/settings'),
      //     headers: {'Content-Type': 'application/json'},
      //     body: json.encode(settings.toJson()),
      //   );
      //   if (response.statusCode == 200) {
      //     return AppSettings.fromJson(json.decode(response.body));
      //   }
      // } catch (e) {
      //   // Network error - already updated locally
      //   print('Network error updating settings, saved locally: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 200));
      _dummySettings = settings;
      return settings;
    } catch (e) {
      print('Error updating app settings: $e');
      rethrow;
    }
  }

  /// Logout user
  /// Clears local database and SharedPreferences
  ///
  /// POST /auth/logout
  /// Header: X-Client-Platform: <platform>
  /// Header: Authorization: Bearer <access_token>
  /// Body: { "refreshToken": "..." }
  Future<void> logout() async {
    try {
      // Call logout API
      try {
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('refresh_token');
        final uri = Uri.parse('${ApiConstants.baseUrl}/auth/logout');
        final body = json.encode({'refreshToken': refreshToken ?? ''});

        // API call with proper headers (handled by ApiClient automatically)
        await _api.post(uri, body: body);
      } catch (e) {
        print('Logout API failed, continuing local cleanup: $e');
      }

      // Clear local database
      await _dbHelper.clearAllData();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
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

  String _formatDobForServer(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd-$mm-$yyyy';
  }

  Map<String, dynamic>? _extractUserMap(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        return data['user'] as Map<String, dynamic>;
      }
      return data;
    }
    if (body['user'] is Map<String, dynamic>) {
      return body['user'] as Map<String, dynamic>;
    }
    return null;
  }

  User _mapBackendUser(Map<String, dynamic> json) {
    final avatarUrl =
        json['profilePic'] ??
        json['profilePicture'] ??
        json['profilePicUrl'] ??
        json['profilePictureUrl'] ??
        json['avatarUrl'];
    final lastSeenRaw = json['lastSeen']?.toString();
    DateTime? lastSeen;
    if (lastSeenRaw != null && lastSeenRaw.isNotEmpty) {
      try {
        lastSeen = DateTime.parse(lastSeenRaw);
      } catch (_) {}
    }

    return User(
      id:
          json['id']?.toString() ??
          json['userId']?.toString() ??
          'current_user',
      name: json['name']?.toString() ?? 'User',
      avatarUrl: avatarUrl?.toString(),
      bio: json['bio']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString(),
      isOnline: json['isOnline'] == true,
      lastSeen: lastSeen,
    );
  }

  Future<void> _cacheUserPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    if (user.email != null) await prefs.setString('user_email', user.email!);
    if (user.bio != null) await prefs.setString('user_bio', user.bio!);
    if (user.avatarUrl != null) {
      await prefs.setString('user_avatar', user.avatarUrl!);
    }
    if (user.phone != null) await prefs.setString('phone_number', user.phone!);
  }

  Future<void> _cacheProfileMeta(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    final gender = userMap['gender']?.toString();
    if (gender != null && gender.isNotEmpty) {
      await prefs.setString('user_gender', gender);
    }
    final dobRaw =
        userMap['dateOfBirth']?.toString() ?? userMap['dob']?.toString();
    if (dobRaw != null && dobRaw.isNotEmpty) {
      final dob = _parseDob(dobRaw);
      if (dob != null) {
        await prefs.setString('user_dob', dob.toIso8601String());
      }
    }
  }

  DateTime? _parseDob(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {}

    final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(raw);
    if (match != null) {
      final d = int.tryParse(match.group(1)!) ?? 1;
      final m = int.tryParse(match.group(2)!) ?? 1;
      final y = int.tryParse(match.group(3)!) ?? 1970;
      return DateTime(y, m, d);
    }
    return null;
  }

  /// Delete user account
  /// TODO: Implement actual API call
  /// Example: DELETE /api/user/account
  Future<void> deleteAccount(String password) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.delete(
    //   Uri.parse('$baseUrl/user/account'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({'password': password}),
    // );
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to delete account');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Get user's privacy settings
  /// TODO: Implement actual API call
  /// Example: GET /api/user/privacy
  Future<Map<String, bool>> getPrivacySettings() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/user/privacy'));
    // if (response.statusCode == 200) {
    //   return Map<String, bool>.from(json.decode(response.body));
    // }
    // throw Exception('Failed to load privacy settings');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 250));
    return {
      'showOnlineStatus': true,
      'allowMessageFromStrangers': false,
      'showLastSeen': true,
      'showReadReceipts': true,
      'allowLocationTracking': false,
    };
  }

  /// Update privacy settings
  /// TODO: Implement actual API call
  /// Example: PUT /api/user/privacy
  Future<void> updatePrivacySettings(Map<String, bool> settings) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.put(
    //   Uri.parse('$baseUrl/user/privacy'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(settings),
    // );
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to update privacy settings');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Get notification settings
  /// TODO: Implement actual API call
  /// Example: GET /api/user/notifications
  Future<Map<String, bool>> getNotificationSettings() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/user/notifications'));
    // if (response.statusCode == 200) {
    //   return Map<String, bool>.from(json.decode(response.body));
    // }
    // throw Exception('Failed to load notification settings');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'newMessages': true,
      'eventReminders': true,
      'eventUpdates': false,
      'newFollowers': true,
      'groupInvitations': true,
      'marketingEmails': false,
    };
  }

  /// Update notification settings
  /// TODO: Implement actual API call
  /// Example: PUT /api/user/notifications
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.put(
    //   Uri.parse('$baseUrl/user/notifications'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode(settings),
    // );
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to update notification settings');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 250));
  }

  /// Export user data
  /// TODO: Implement actual API call
  /// Example: GET /api/user/export
  Future<String> exportUserData() async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.get(Uri.parse('$baseUrl/user/export'));
    // if (response.statusCode == 200) {
    //   return response.body; // JSON string of user data
    // }
    // throw Exception('Failed to export user data');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    return '{"message": "User data export would be available here"}';
  }

  /// Report a bug or issue
  /// TODO: Implement actual API call
  /// Example: POST /api/support/bug-report
  Future<void> reportBug(String description, String category) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(
    //   Uri.parse('$baseUrl/support/bug-report'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({
    //     'description': description,
    //     'category': category,
    //     'timestamp': DateTime.now().toIso8601String(),
    //   }),
    // );
    // if (response.statusCode != 201) {
    //   throw Exception('Failed to report bug');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Send feedback
  /// TODO: Implement actual API call
  /// Example: POST /api/support/feedback
  Future<void> sendFeedback(String feedback, int rating) async {
    // TODO: Replace with actual HTTP request
    // final response = await _httpClient.post(
    //   Uri.parse('$baseUrl/support/feedback'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({
    //     'feedback': feedback,
    //     'rating': rating,
    //     'timestamp': DateTime.now().toIso8601String(),
    //   }),
    // );
    // if (response.statusCode != 201) {
    //   throw Exception('Failed to send feedback');
    // }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 350));
  }

  /// Block a user
  ///
  /// POST /api/users/:userId/block
  Future<Map<String, dynamic>> blockUser(String userId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/$userId/block');
      final response = await _api.post(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'User blocked successfully',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorData['error']?['message'] ??
              errorData['message'] ??
              'Failed to block user',
          'errorCode': errorData['error']?['code'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Unblock a user
  ///
  /// DELETE /api/users/:userId/unblock
  Future<Map<String, dynamic>> unblockUser(String userId) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/users/$userId/unblock',
      );
      final response = await _api.delete(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'User unblocked successfully',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorData['error']?['message'] ??
              errorData['message'] ??
              'Failed to unblock user',
          'errorCode': errorData['error']?['code'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get blocked users list
  ///
  /// GET /api/users/blocked
  Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/users/blocked');
      final response = await _api.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch blocked users',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': [],
      };
    }
  }
}
