class ApiConstants {
  static const String baseUrl =
      'https://array-physics-code-showing.trycloudflare.com';

  /// Resolves API-provided URLs that may be absolute or relative.
  ///
  /// Examples:
  /// - "https://.../img.png" -> unchanged
  /// - "/uploads/img.png" -> "baseUrl/uploads/img.png"
  /// - "uploads/img.png" -> "baseUrl/uploads/img.png"
  static String? resolveUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.toLowerCase() == 'null') return null;

    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return value;
    }

    final base = Uri.parse(baseUrl);
    return base.resolve(value).toString();
  }

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
