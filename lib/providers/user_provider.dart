import 'package:riverpod/riverpod.dart';
import 'package:hosla/models/user_model.dart';
import 'package:hosla/services/user_service.dart';

/// Provider for UserService instance
final userServiceProvider = Provider<UserService>((ref) => UserService());

/// Provider for current user profile
final currentUserProfileProvider = StateNotifierProvider<UserProfileNotifier, User?>((ref) {
  return UserProfileNotifier(ref.read(userServiceProvider));
});

/// Provider for app settings
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.read(userServiceProvider));
});

/// App settings model
class AppSettings {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool locationEnabled;
  final String language;
  final bool darkMode;
  final bool privateProfile;

  const AppSettings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.locationEnabled = false,
    this.language = 'English',
    this.darkMode = false,
    this.privateProfile = false,
  });

  /// Factory constructor for creating AppSettings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      locationEnabled: json['locationEnabled'] ?? false,
      language: json['language'] ?? 'English',
      darkMode: json['darkMode'] ?? false,
      privateProfile: json['privateProfile'] ?? false,
    );
  }

  /// Convert AppSettings to JSON
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'locationEnabled': locationEnabled,
      'language': language,
      'darkMode': darkMode,
      'privateProfile': privateProfile,
    };
  }

  /// Create a copy of AppSettings with updated fields
  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? locationEnabled,
    String? language,
    bool? darkMode,
    bool? privateProfile,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      privateProfile: privateProfile ?? this.privateProfile,
    );
  }
}

/// Notifier for managing user profile
class UserProfileNotifier extends StateNotifier<User?> {
  final UserService _userService;

  UserProfileNotifier(this._userService) : super(null) {
    loadCurrentUser();
  }

  /// Load current user profile
  Future<void> loadCurrentUser() async {
    try {
      // TODO: Implement API call
      final user = await _userService.getCurrentUser();
      state = user;
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? email,
    String? avatarUrl,
  }) async {
    if (state == null) return;

    try {
      final updatedUser = state!.copyWith(
        name: name,
        bio: bio,
        email: email,
        avatarUrl: avatarUrl,
      );

      // TODO: Implement API call
      await _userService.updateUserProfile(updatedUser);
      state = updatedUser;
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  /// Update avatar
  Future<void> updateAvatar(String avatarUrl) async {
    if (state == null) return;

    try {
      // TODO: Implement API call
      await _userService.updateUserAvatar(avatarUrl);
      state = state!.copyWith(avatarUrl: avatarUrl);
    } catch (e) {
      print('Error updating avatar: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // TODO: Implement API call
      await _userService.logout();
      state = null;
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}

/// Notifier for managing app settings
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final UserService _userService;

  AppSettingsNotifier(this._userService) : super(const AppSettings()) {
    loadSettings();
  }

  /// Load app settings
  Future<void> loadSettings() async {
    try {
      // TODO: Implement API call
      final settings = await _userService.getAppSettings();
      state = settings;
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  /// Update notifications setting
  Future<void> updateNotifications(bool enabled) async {
    try {
      final updatedSettings = state.copyWith(notificationsEnabled: enabled);
      // TODO: Implement API call
      await _userService.updateAppSettings(updatedSettings);
      state = updatedSettings;
    } catch (e) {
      print('Error updating notifications: $e');
    }
  }

  /// Update sound setting
  Future<void> updateSound(bool enabled) async {
    try {
      final updatedSettings = state.copyWith(soundEnabled: enabled);
      // TODO: Implement API call
      await _userService.updateAppSettings(updatedSettings);
      state = updatedSettings;
    } catch (e) {
      print('Error updating sound: $e');
    }
  }

  /// Update vibration setting
  Future<void> updateVibration(bool enabled) async {
    try {
      final updatedSettings = state.copyWith(vibrationEnabled: enabled);
      // TODO: Implement API call
      await _userService.updateAppSettings(updatedSettings);
      state = updatedSettings;
    } catch (e) {
      print('Error updating vibration: $e');
    }
  }

  /// Update location setting
  Future<void> updateLocation(bool enabled) async {
    try {
      final updatedSettings = state.copyWith(locationEnabled: enabled);
      // TODO: Implement API call
      await _userService.updateAppSettings(updatedSettings);
      state = updatedSettings;
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Update language setting
  Future<void> updateLanguage(String language) async {
    try {
      final updatedSettings = state.copyWith(language: language);
      // TODO: Implement API call
      await _userService.updateAppSettings(updatedSettings);
      state = updatedSettings;
    } catch (e) {
      print('Error updating language: $e');
    }
  }

  /// Update dark mode setting
  Future<void> updateDarkMode(bool enabled) async {
    try {
      final updatedSettings = state.copyWith(darkMode: enabled);
      // TODO: Implement API call
      await _userService.updateAppSettings(updatedSettings);
      state = updatedSettings;
    } catch (e) {
      print('Error updating dark mode: $e');
    }
  }

  /// Update privacy setting
  Future<void> updatePrivateProfile(bool enabled) async {
    try {
      final updatedSettings = state.copyWith(privateProfile: enabled);
      // TODO: Implement API call
      await _userService.updateAppSettings(updatedSettings);
      state = updatedSettings;
    } catch (e) {
      print('Error updating privacy: $e');
    }
  }
}
