/// Insomnia-style environment variables applied across all collection requests.
class PostyEnvironment {
  const PostyEnvironment({
    this.baseUrl = '',
    this.accessToken = '',
  });

  final String baseUrl;
  final String accessToken;

  PostyEnvironment copyWith({
    String? baseUrl,
    String? accessToken,
  }) {
    return PostyEnvironment(
      baseUrl: baseUrl ?? this.baseUrl,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'accessToken': accessToken,
      };

  factory PostyEnvironment.fromJson(Map<String, dynamic> json) {
    return PostyEnvironment(
      baseUrl: json['baseUrl'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
    );
  }

  /// Reads `Authorization: Bearer …` from host-provided headers.
  static String? bearerFromHeaders(Map<String, String>? headers) {
    if (headers == null) return null;
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        final v = entry.value.trim();
        if (v.toLowerCase().startsWith('bearer ')) {
          return v.substring(7).trim();
        }
      }
    }
    return null;
  }
}
