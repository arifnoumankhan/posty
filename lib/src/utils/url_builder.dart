import 'package:posty/src/models/key_value_row.dart';

class UrlBuilder {
  static String buildUrl({
    required String baseUrl,
    required String path,
    List<KeyValueRow> queryParams = const [],
  }) {
    final resolvedBase = _trimTrailingSlash(_substituteBaseUrl(baseUrl, path));
    final pathOnly = _extractPathAndQuery(path);
    final pathPart = pathOnly.path.isEmpty ? '' : pathOnly.path;
    final mergedQuery = <String, String>{};

    for (final entry in pathOnly.query.entries) {
      mergedQuery[entry.key] = entry.value;
    }
    for (final row in queryParams) {
      if (!row.enabled || row.key.trim().isEmpty) continue;
      mergedQuery[row.key.trim()] = row.value;
    }

    final buffer = StringBuffer();
    if (resolvedBase.isNotEmpty) {
      buffer.write(resolvedBase);
    }
    if (pathPart.isNotEmpty) {
      if (!pathPart.startsWith('/') && buffer.isNotEmpty) {
        buffer.write('/');
      }
      buffer.write(pathPart.startsWith('/') ? pathPart : '/$pathPart');
    }

    if (mergedQuery.isNotEmpty) {
      buffer.write('?');
      buffer.write(
        mergedQuery.entries
            .map((e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
            .join('&'),
      );
    }
    return buffer.toString();
  }

  static String _substituteBaseUrl(String baseUrl, String path) {
    var result = baseUrl.trim();
    if (result.contains('{{base_url}}')) {
      result = result.replaceAll('{{base_url}}', baseUrl.trim());
    }
    if (path.contains('{{base_url}}') && baseUrl.isNotEmpty) {
      return baseUrl.trim();
    }
    return result;
  }

  static _PathQuery _extractPathAndQuery(String raw) {
    var input = raw.trim();
    if (input.contains('{{base_url}}')) {
      input = input.replaceAll('{{base_url}}', '').trim();
    }
    final question = input.indexOf('?');
    if (question == -1) {
      return _PathQuery(input, {});
    }
    final pathPart = input.substring(0, question);
    final query = Uri.splitQueryString(input.substring(question + 1));
    return _PathQuery(pathPart, query);
  }

  static String _trimTrailingSlash(String value) {
    if (value.isEmpty) return value;
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  static List<KeyValueRow> parseQueryFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.queryParameters.isEmpty) {
      final q = url.indexOf('?');
      if (q == -1) return [];
      final query = Uri.splitQueryString(url.substring(q + 1));
      return query.entries
          .map((e) => KeyValueRow(key: e.key, value: e.value, enabled: true))
          .toList();
    }
    return uri.queryParameters.entries
        .map((e) => KeyValueRow(key: e.key, value: e.value, enabled: true))
        .toList();
  }

  static List<KeyValueRow> importQueryFromPathOrUrl(String path, String baseUrl) {
    final full = buildUrl(baseUrl: baseUrl, path: path, queryParams: const []);
    return parseQueryFromUrl(full);
  }
}

class _PathQuery {
  const _PathQuery(this.path, this.query);
  final String path;
  final Map<String, String> query;
}
