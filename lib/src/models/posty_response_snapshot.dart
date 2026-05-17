/// Serializable response snapshot for local history.
class PostyResponseSnapshot {
  const PostyResponseSnapshot({
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

  Map<String, dynamic> toJson() => {
        'body': body,
        'statusCode': statusCode,
        'statusMessage': statusMessage,
        'headers': headers.map((k, v) => MapEntry(k, v)),
        'durationMs': durationMs,
        'isSuccess': isSuccess,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  factory PostyResponseSnapshot.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'] as Map<String, dynamic>? ?? {};
    final headers = <String, List<String>>{};
    for (final entry in rawHeaders.entries) {
      final value = entry.value;
      if (value is List) {
        headers[entry.key] = value.map((e) => e.toString()).toList();
      } else if (value != null) {
        headers[entry.key] = [value.toString()];
      }
    }
    return PostyResponseSnapshot(
      body: json['body'] as String? ?? '',
      statusCode: json['statusCode'] as int?,
      statusMessage: json['statusMessage'] as String? ?? '',
      headers: headers,
      durationMs: json['durationMs'] as int? ?? 0,
      isSuccess: json['isSuccess'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
