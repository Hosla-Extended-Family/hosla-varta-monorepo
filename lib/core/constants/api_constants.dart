/// API configuration constants
class ApiConstants {
  // Base URL for API endpoints
  // TODO: Replace with your actual API base URL
  static const String baseUrl =
      'https://coleman-jonathan-military-color.trycloudflare.com';

  // API Endpoints
  static const String postsEndpoint = '/posts';
  static const String userEndpoint = '/user';
  static const String authEndpoint = '/auth';

  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
}
