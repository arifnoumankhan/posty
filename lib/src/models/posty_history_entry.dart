import 'package:posty/src/models/posty_request.dart';
import 'package:posty/src/models/posty_response_snapshot.dart';

class PostyHistoryEntry {
  const PostyHistoryEntry({
    required this.id,
    required this.sentAt,
    required this.request,
    this.response,
  });

  final String id;
  final DateTime sentAt;
  final PostyRequest request;
  final PostyResponseSnapshot? response;

  String get label {
    final path = request.path.isEmpty ? '/' : request.path;
    return '${request.method.label} $path';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sentAt': sentAt.toIso8601String(),
        'request': request.toJson(),
        if (response != null) 'response': response!.toJson(),
      };

  factory PostyHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PostyHistoryEntry(
      id: json['id'] as String? ?? '',
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      request: PostyRequest.fromJson(
        json['request'] as Map<String, dynamic>? ?? {},
      ),
      response: json['response'] == null
          ? null
          : PostyResponseSnapshot.fromJson(
              json['response'] as Map<String, dynamic>,
            ),
    );
  }
}
