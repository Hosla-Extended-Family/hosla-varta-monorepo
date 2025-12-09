/// API configuration constants
class ApiConstants {
  // Base URL for API endpoints
  // TODO: Replace with your actual API base URL
  static const String baseUrl = 'https://your-api-url.com/api';

  // API Endpoints
  static const String postsEndpoint = '/posts';
  static const String userEndpoint = '/user';
  static const String authEndpoint = '/auth';

  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);
}
