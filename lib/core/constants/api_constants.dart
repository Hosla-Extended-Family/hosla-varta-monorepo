class ApiConstants {
  static const String baseUrl =
      'https://transformation-ash-brake-hdtv.trycloudflare.com';

  static const String postsEndpoint = '/api/posts';
  static const String commentsEndpoint = '/api/comments';
  static const String reportsEndpoint = '/api/reports';
  static const String userEndpoint = '/user';
  static const String authEndpoint = '/auth';

  static const Duration timeout = Duration(seconds: 30);
}
