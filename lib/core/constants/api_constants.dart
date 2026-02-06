class ApiConstants {
  static const String baseUrl =
      'https://admit-strengths-roland-were.trycloudflare.com';

  static const String postsEndpoint = '/api/posts';
  static const String commentsEndpoint = '/api/comments';
  static const String reportsEndpoint = '/api/reports';
  static const String userEndpoint = '/api/user';
  static const String authEndpoint = '/api/auth';

  static const Duration timeout = Duration(seconds: 30);
}
