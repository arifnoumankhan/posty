class PostyResponse {
  const PostyResponse({
    required this.body,
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.durationMs,
    required this.isSuccess,
    this.errorMessage,
  });

  final String body;
  final int? statusCode;
  final String statusMessage;
  final Map<String, List<String>> headers;
  final int durationMs;
  final bool isSuccess;
  final String? errorMessage;

  int get bodyBytes => body.codeUnits.length;

  String get statusLabel {
    if (statusCode == null) return errorMessage ?? 'Error';
    return '$statusCode $statusMessage'.trim();
  }
}
