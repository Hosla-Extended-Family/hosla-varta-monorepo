import 'package:hosla/models/user_model.dart';
import 'package:hosla/providers/user_provider.dart';
import 'package:hosla/services/database_helper.dart';
import 'package:http/http.dart' as _httpClient;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './../core/constants/api_constants.dart'; 

/// Service class for handling user-related API calls and settings management
/// Implements offline-first approach with local database and SharedPreferences caching
class UserService {
  // TODO: Add HTTP client dependency injection
  // final http.Client _httpClient;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Dummy current user data for testing
  static final User _dummyCurrentUser = User(
    id: 'current_user',
    name: 'John Doe',
    avatarUrl:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
    bio: 'Software developer passionate about mobile apps and user experience.',
    email: 'john.doe@example.com',
    phone: '+919876543210',
    isOnline: true,
  );

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
      final cachedUser = await _dbHelper.getUserById('current_user');

      // TODO: Replace with actual HTTP request
      // try {
      //   final response = await _httpClient.get(Uri.parse('$baseUrl/user/profile'));
      //   if (response.statusCode == 200) {
      //     final user = User.fromJson(json.decode(response.body));
      //     // Cache the fetched user
      //     await _dbHelper.upsertUser(user);
      //     return user;
      //   } else if (response.statusCode == 401) {
      //     return null; // User not authenticated
      //   }
      // } catch (e) {
      //   // Network error - return cached data if available
      //   print('Network error, using cached user: $e');
      // }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Cache dummy user
      await _dbHelper.upsertUser(_dummyCurrentUser);

      return cachedUser ?? _dummyCurrentUser;
    } catch (e) {
      print('Error loading current user: $e');
      return _dummyCurrentUser;
    }
  }

  /// Update user profile
  /// Updates local database first, then syncs with API
  Future<User> updateUserProfile(User user) async {
    try {
      // Update local database immediately
      await _dbHelper.upsertUser(user);

      // TODO: Replace with actual HTTP request
      try {
        final response = await _httpClient.put(
          Uri.parse('${ApiConstants.baseUrl}/auth/create-profile'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(user.toJson()),
        );
        if (response.statusCode == 200) {
          final serverUser = User.fromJson(json.decode(response.body));
          //Update local database with server response
          await _dbHelper.upsertUser(serverUser);
          return serverUser;
        }
      } catch (e) {
        //Network error - already updated locally
        print('Network error updating profile, saved locally: $e');
      }
      await Future.delayed(const Duration(milliseconds: 400));
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
  Future<void> logout() async {
    try {
      // TODO: Replace with actual HTTP request
      // final response = await _httpClient.post(Uri.parse('$baseUrl/auth/logout'));
      // if (response.statusCode != 200) {
      //   throw Exception('Failed to logout');
      // }

      // Clear local database
      await _dbHelper.clearAllData();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
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
}
