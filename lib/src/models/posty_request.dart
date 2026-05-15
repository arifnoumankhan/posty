import 'package:posty/src/models/key_value_row.dart';
import 'package:posty/src/models/posty_enums.dart';

class PostyRequest {
  const PostyRequest({
    this.method = HttpMethod.get,
    this.baseUrl = '',
    this.path = '',
    this.queryParams = const [],
    this.headers = const [],
    this.bodyType = BodyType.none,
    this.jsonBody = '',
    this.formBody = const [],
    this.authType = AuthType.none,
    this.bearerToken = '',
    this.basicUsername = '',
    this.basicPassword = '',
    this.apiKeyHeader = 'X-API-Key',
    this.apiKeyValue = '',
  });

  final HttpMethod method;
  final String baseUrl;
  final String path;
  final List<KeyValueRow> queryParams;
  final List<KeyValueRow> headers;
  final BodyType bodyType;
  final String jsonBody;
  final List<KeyValueRow> formBody;
  final AuthType authType;
  final String bearerToken;
  final String basicUsername;
  final String basicPassword;
  final String apiKeyHeader;
  final String apiKeyValue;

  PostyRequest copyWith({
    HttpMethod? method,
    String? baseUrl,
    String? path,
    List<KeyValueRow>? queryParams,
    List<KeyValueRow>? headers,
    BodyType? bodyType,
    String? jsonBody,
    List<KeyValueRow>? formBody,
    AuthType? authType,
    String? bearerToken,
    String? basicUsername,
    String? basicPassword,
    String? apiKeyHeader,
    String? apiKeyValue,
  }) {
    return PostyRequest(
      method: method ?? this.method,
      baseUrl: baseUrl ?? this.baseUrl,
      path: path ?? this.path,
      queryParams: queryParams ?? this.queryParams,
      headers: headers ?? this.headers,
      bodyType: bodyType ?? this.bodyType,
      jsonBody: jsonBody ?? this.jsonBody,
      formBody: formBody ?? this.formBody,
      authType: authType ?? this.authType,
      bearerToken: bearerToken ?? this.bearerToken,
      basicUsername: basicUsername ?? this.basicUsername,
      basicPassword: basicPassword ?? this.basicPassword,
      apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
      apiKeyValue: apiKeyValue ?? this.apiKeyValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method.name,
        'baseUrl': baseUrl,
        'path': path,
        'queryParams': queryParams.map((e) => e.toJson()).toList(),
        'headers': headers.map((e) => e.toJson()).toList(),
        'bodyType': bodyType.name,
        'jsonBody': jsonBody,
        'formBody': formBody.map((e) => e.toJson()).toList(),
        'authType': authType.name,
        'bearerToken': bearerToken,
        'basicUsername': basicUsername,
        'basicPassword': basicPassword,
        'apiKeyHeader': apiKeyHeader,
        'apiKeyValue': apiKeyValue,
      };

  factory PostyRequest.fromJson(Map<String, dynamic> json) {
    return PostyRequest(
      method: HttpMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => HttpMethod.get,
      ),
      baseUrl: json['baseUrl'] as String? ?? '',
      path: json['path'] as String? ?? '',
      queryParams: (json['queryParams'] as List<dynamic>? ?? [])
          .map((e) => KeyValueRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      headers: (json['headers'] as List<dynamic>? ?? [])
          .map((e) => KeyValueRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      bodyType: BodyType.values.firstWhere(
        (e) => e.name == json['bodyType'],
        orElse: () => BodyType.none,
      ),
      jsonBody: json['jsonBody'] as String? ?? '',
      formBody: (json['formBody'] as List<dynamic>? ?? [])
          .map((e) => KeyValueRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      authType: AuthType.values.firstWhere(
        (e) => e.name == json['authType'],
        orElse: () => AuthType.none,
      ),
      bearerToken: json['bearerToken'] as String? ?? '',
      basicUsername: json['basicUsername'] as String? ?? '',
      basicPassword: json['basicPassword'] as String? ?? '',
      apiKeyHeader: json['apiKeyHeader'] as String? ?? 'X-API-Key',
      apiKeyValue: json['apiKeyValue'] as String? ?? '',
    );
  }
}
