import 'package:posty/src/models/key_value_row.dart';
import 'package:posty/src/models/posty_collection_node.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/models/posty_request.dart';
import 'package:posty/src/utils/url_builder.dart';
import 'package:yaml/yaml.dart';

/// Parses Insomnia export YAML (`collection.insomnia.rest/5.x`) into Posty trees.
class InsomniaYamlImporter {
  const InsomniaYamlImporter._();

  static InsomniaImportResult parse(
    String yamlSource, {
    String hostBaseUrl = '',
    String hostAccessToken = '',
  }) {
    final doc = loadYaml(yamlSource);
    if (doc is! YamlMap) {
      throw FormatException('Expected YAML map at root');
    }
    final collectionName = doc['name']?.toString() ?? 'Imported';
    final items = doc['collection'];
    if (items is! YamlList) {
      throw FormatException('Missing collection array');
    }

    final rootMaps = <YamlMap>[];
    for (final item in items) {
      if (item is YamlMap) rootMaps.add(item);
    }
    rootMaps.sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));

    final roots = <PostyCollectionNode>[];
    for (final item in rootMaps) {
      final node = _parseNode(
        item,
        hostBaseUrl: hostBaseUrl,
        hostAccessToken: hostAccessToken,
      );
      if (node != null) roots.add(node);
    }

    return InsomniaImportResult(
      workspaceName: collectionName,
      roots: roots,
    );
  }

  static int _sortKey(YamlMap map) {
    final meta = map['meta'];
    if (meta is YamlMap) {
      final sk = meta['sortKey'];
      if (sk is int) return sk;
      if (sk is num) return sk.toInt();
    }
    return 0;
  }

  static PostyCollectionNode? _parseNode(
    YamlMap map, {
    required String hostBaseUrl,
    required String hostAccessToken,
  }) {
    final name = map['name']?.toString() ?? 'Untitled';
    final childrenRaw = map['children'];

    if (childrenRaw is YamlList) {
      final childMaps = <YamlMap>[];
      for (final child in childrenRaw) {
        if (child is YamlMap) childMaps.add(child);
      }
      childMaps.sort((a, b) => _sortKey(a).compareTo(_sortKey(b)));

      final children = <PostyCollectionNode>[];
      for (final child in childMaps) {
        final node = _parseNode(
          child,
          hostBaseUrl: hostBaseUrl,
          hostAccessToken: hostAccessToken,
        );
        if (node != null) children.add(node);
      }
      return PostyCollectionNode(
        id: PostyCollectionIds.newId(),
        name: name,
        kind: PostyCollectionNodeKind.folder,
        children: children,
        expanded: true,
      );
    }

    final url = map['url']?.toString();
    if (url == null || url.isEmpty) return null;

    final request = _parseRequest(
      map,
      url,
      hostBaseUrl: hostBaseUrl,
      hostAccessToken: hostAccessToken,
    );
    return PostyCollectionNode(
      id: PostyCollectionIds.newId(),
      name: name,
      kind: PostyCollectionNodeKind.request,
      request: request,
    );
  }

  static PostyRequest _parseRequest(
    YamlMap map,
    String rawUrl, {
    required String hostBaseUrl,
    required String hostAccessToken,
  }) {
    final method = _parseMethod(map['method']?.toString());
    final (baseUrl, path) = _splitInsomniaUrl(rawUrl, hostBaseUrl);

    // ── Query params ──────────────────────────────────────────────────────────
    // Insomnia stores query params in a `parameters` list (separate from the
    // URL string). Fall back to extracting them from the URL's `?` portion if
    // the field is absent.
    var queryParams = <KeyValueRow>[];
    var pathOnly = path;

    final parametersRaw = map['parameters'];
    if (parametersRaw is YamlList) {
      queryParams = _parseQueryParams(parametersRaw);
      // Strip any inline query string so we don't double-up
      final q = pathOnly.indexOf('?');
      if (q != -1) pathOnly = pathOnly.substring(0, q);
    } else {
      final q = path.indexOf('?');
      if (q != -1) {
        pathOnly = path.substring(0, q);
        queryParams = UrlBuilder.importQueryFromPathOrUrl(path, baseUrl);
      }
    }

    var headers = _parseHeaders(map['headers']);
    var authType = AuthType.none;
    var bearerToken = '';
    var basicUsername = '';
    var basicPassword = '';
    var apiKeyHeader = 'X-API-Key';
    var apiKeyValue = '';

    final auth = map['authentication'];
    if (auth is YamlMap) {
      final type = auth['type']?.toString();
      switch (type) {
        case 'bearer':
          authType = AuthType.bearer;
          bearerToken = _resolveBearerToken(
            auth['token']?.toString(),
            hostAccessToken,
          );
        case 'basic':
          authType = AuthType.basic;
          basicUsername = _cleanTemplate(auth['username']?.toString() ?? '');
          basicPassword = _cleanTemplate(auth['password']?.toString() ?? '');
        case 'apikey':
          authType = AuthType.apiKey;
          apiKeyHeader = auth['key']?.toString() ?? 'X-API-Key';
          apiKeyValue = _cleanTemplate(auth['value']?.toString() ?? '');
      }
    }

    var bodyType = BodyType.none;
    var jsonBody = '';
    var formBody = <KeyValueRow>[];

    final body = map['body'];
    if (body is YamlMap) {
      final mime = body['mimeType']?.toString() ?? '';
      if (mime.contains('json')) {
        bodyType = BodyType.json;
        jsonBody = body['text']?.toString() ?? '';
      } else if (mime.contains('multipart') || mime.contains('urlencoded')) {
        bodyType = BodyType.form;
        formBody = _parseBodyParams(body['params']);
        if (formBody.isEmpty) {
          formBody = [const KeyValueRow()];
        }
      }
    }

    if (queryParams.isEmpty) {
      queryParams = [const KeyValueRow()];
    }
    if (headers.isEmpty) {
      headers = [const KeyValueRow()];
    }

    return PostyRequest(
      method: method,
      baseUrl: baseUrl.isNotEmpty ? baseUrl : hostBaseUrl,
      path: pathOnly,
      queryParams: queryParams,
      headers: headers,
      bodyType: bodyType,
      jsonBody: jsonBody,
      formBody: formBody,
      authType: authType,
      bearerToken: bearerToken,
      basicUsername: basicUsername,
      basicPassword: basicPassword,
      apiKeyHeader: apiKeyHeader,
      apiKeyValue: apiKeyValue,
    );
  }

  static List<KeyValueRow> _parseHeaders(dynamic raw) {
    if (raw is! YamlList) return [];
    final rows = <KeyValueRow>[];
    for (final item in raw) {
      if (item is! YamlMap) continue;
      final key = item['name']?.toString() ?? '';
      if (key.isEmpty || key.toLowerCase() == 'user-agent') continue;
      if (key.toLowerCase() == 'content-type') continue;
      rows.add(KeyValueRow(
        key: key,
        value: item['value']?.toString() ?? '',
        enabled: !(item['disabled'] == true),
      ));
    }
    return rows;
  }

  static List<KeyValueRow> _parseQueryParams(dynamic raw) {
    if (raw is! YamlList) return [];
    final rows = <KeyValueRow>[];
    for (final item in raw) {
      if (item is! YamlMap) continue;
      final key = item['name']?.toString() ?? '';
      if (key.isEmpty) continue;
      rows.add(KeyValueRow(
        key: key,
        value: item['value']?.toString() ?? '',
        description: item['description']?.toString() ?? '',
        enabled: !(item['disabled'] == true),
      ));
    }
    return rows;
  }

  static List<KeyValueRow> _parseBodyParams(dynamic raw) {
    if (raw is! YamlList) return [];
    final rows = <KeyValueRow>[];
    for (final item in raw) {
      if (item is! YamlMap) continue;
      final key = item['name']?.toString() ?? '';
      if (key.isEmpty) continue;
      final isFile = item['type']?.toString() == 'file';
      rows.add(KeyValueRow(
        key: key,
        value: item['value']?.toString() ?? '',
        description: item['description']?.toString() ?? '',
        enabled: !(item['disabled'] == true),
        formValueType: isFile ? FormValueType.file : FormValueType.text,
        fileName: isFile ? item['fileName']?.toString() : null,
      ));
    }
    return rows;
  }

  static HttpMethod _parseMethod(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'PATCH':
        return HttpMethod.patch;
      case 'DELETE':
        return HttpMethod.delete;
      case 'HEAD':
        return HttpMethod.head;
      default:
        return HttpMethod.get;
    }
  }

  static (String baseUrl, String path) _splitInsomniaUrl(
    String raw,
    String hostBaseUrl,
  ) {
    var url = raw.replaceAll('\n', '').trim();
    url = url.replaceAll(RegExp(r'\{\{\s*_\.\s*base_url\s*\}\}'), '').trim();
    url = url.replaceAll('{{ _.base_url }}', '').trim();
    url = url.replaceAll(RegExp(r'\s+'), '');

    if (url.startsWith('http://') || url.startsWith('https://')) {
      final cleaned = url.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');
      final uri = Uri.tryParse(cleaned);
      if (uri != null) {
        final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
        final path = uri.hasQuery
            ? '${uri.path}?${uri.query}'
            : (uri.path.isEmpty ? '/' : uri.path);
        return (origin, path);
      }
    }

    if (!url.startsWith('/')) {
      url = '/$url';
    }
    return (hostBaseUrl, url);
  }

  static String _cleanTemplate(String value) {
    return value.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '').trim();
  }

  static String _resolveBearerToken(String? raw, String hostAccessToken) {
    final token = raw?.trim() ?? '';
    final isTemplate = token.contains('{{') && token.contains('}}');
    if (isTemplate || token.isEmpty) {
      return hostAccessToken;
    }
    return _cleanTemplate(token);
  }
}

class InsomniaImportResult {
  const InsomniaImportResult({
    required this.workspaceName,
    required this.roots,
  });

  final String workspaceName;
  final List<PostyCollectionNode> roots;
}
