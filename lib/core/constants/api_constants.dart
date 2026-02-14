class ApiConstants {
  static const String baseUrl =
      'https://retail-nylon-pmc-registrar.trycloudflare.com';

  static const String postsEndpoint = '/api/posts';
  static const String commentsEndpoint = '/api/comments';
  static const String reportsEndpoint = '/api/reports';
  static const String userEndpoint = '/api/user';
  static const String usersEndpoint = '/api/users';
  static const String friendsEndpoint = '/api/friends';
  static const String authEndpoint = '/api/auth';
  static const String tagsEndpoint = '/api/tags';

  static const Duration timeout = Duration(seconds: 30);
}
