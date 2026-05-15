import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:posty/src/models/key_value_row.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/models/posty_request.dart';
import 'package:posty/src/models/posty_response.dart';
import 'package:posty/src/utils/url_builder.dart';

class PostyHttpService {
  PostyHttpService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  CancelToken? _cancelToken;

  void cancel() => _cancelToken?.cancel('Cancelled by user');

  Future<PostyResponse> send(PostyRequest request) async {
    _cancelToken = CancelToken();
    final stopwatch = Stopwatch()..start();
    final url = UrlBuilder.buildUrl(
      baseUrl: request.baseUrl,
      path: request.path,
      queryParams: request.queryParams,
    );

    final headers = _buildHeaders(request);

    try {
      final options = Options(
        method: request.method.label,
        headers: headers,
        responseType: ResponseType.plain,
        validateStatus: (_) => true,
      );

      dynamic data;
      if (request.bodyType == BodyType.json && request.jsonBody.trim().isNotEmpty) {
        data = request.jsonBody;
        headers.putIfAbsent('Content-Type', () => 'application/json');
      } else if (request.bodyType == BodyType.form) {
        data = _formMap(request.formBody);
        headers.putIfAbsent('Content-Type', () => 'application/x-www-form-urlencoded');
      }

      final response = await _dio.request<String>(
        url,
        data: data,
        options: options,
        cancelToken: _cancelToken,
      );

      stopwatch.stop();
      final responseHeaders = <String, List<String>>{};
      response.headers.map.forEach((key, values) {
        responseHeaders[key] = values;
      });

      final body = response.data ?? '';
      final code = response.statusCode ?? 0;

      return PostyResponse(
        body: body,
        statusCode: code,
        statusMessage: response.statusMessage ?? '',
        headers: responseHeaders,
        durationMs: stopwatch.elapsedMilliseconds,
        isSuccess: code >= 200 && code < 300,
      );
    } on DioException catch (e) {
      stopwatch.stop();
      final response = e.response;
      if (response != null) {
        final responseHeaders = <String, List<String>>{};
        response.headers.map.forEach((key, values) {
          responseHeaders[key] = values;
        });
        return PostyResponse(
          body: response.data?.toString() ?? '',
          statusCode: response.statusCode,
          statusMessage: response.statusMessage ?? '',
          headers: responseHeaders,
          durationMs: stopwatch.elapsedMilliseconds,
          isSuccess: false,
          errorMessage: e.message,
        );
      }
      return PostyResponse(
        body: '',
        statusCode: null,
        statusMessage: '',
        headers: const {},
        durationMs: stopwatch.elapsedMilliseconds,
        isSuccess: false,
        errorMessage: e.message ?? e.toString(),
      );
    }
  }

  Map<String, String> _buildHeaders(PostyRequest request) {
    final map = <String, String>{};
    for (final row in request.headers) {
      if (!row.enabled || row.key.trim().isEmpty) continue;
      map[row.key.trim()] = row.value;
    }

    switch (request.authType) {
      case AuthType.bearer:
        if (request.bearerToken.isNotEmpty) {
          map['Authorization'] = 'Bearer ${request.bearerToken}';
        }
      case AuthType.basic:
        if (request.basicUsername.isNotEmpty) {
          final creds = base64Encode(
            utf8.encode('${request.basicUsername}:${request.basicPassword}'),
          );
          map['Authorization'] = 'Basic $creds';
        }
      case AuthType.apiKey:
        if (request.apiKeyHeader.isNotEmpty && request.apiKeyValue.isNotEmpty) {
          map[request.apiKeyHeader] = request.apiKeyValue;
        }
      case AuthType.none:
        break;
    }
    return map;
  }

  Map<String, String> _formMap(List<KeyValueRow> rows) {
    final map = <String, String>{};
    for (final row in rows) {
      if (!row.enabled || row.key.trim().isEmpty) continue;
      map[row.key.trim()] = row.value;
    }
    return map;
  }
}
