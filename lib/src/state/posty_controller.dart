import 'package:flutter/foundation.dart';
import 'package:posty/src/models/key_value_row.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/models/posty_request.dart';
import 'package:posty/src/models/posty_response.dart';
import 'package:posty/src/posty_defaults.dart';
import 'package:posty/src/services/posty_http_service.dart';
import 'package:posty/src/utils/json_pretty.dart';
import 'package:posty/src/utils/url_builder.dart';

class PostyController extends ChangeNotifier {
  PostyController({
    String initialBaseUrl = '',
    Map<String, String>? initialHeaders,
    String initialQuicktypeConverterUrl = '',
    PostyHttpService? httpService,
  }) : _http = httpService ?? PostyHttpService() {
    quicktypeConverterUrl =
        PostyDefaults.normalizeQuicktypeConverterUrl(initialQuicktypeConverterUrl);
    baseUrl = initialBaseUrl;
    if (initialHeaders != null && initialHeaders.isNotEmpty) {
      headers = initialHeaders.entries
          .map((e) => KeyValueRow(key: e.key, value: e.value, enabled: true))
          .toList();
    }
    _ensureDefaultRows();
  }

  final PostyHttpService _http;

  HttpMethod method = HttpMethod.get;
  String baseUrl = '';
  String path = '';
  List<KeyValueRow> queryParams = [];
  List<KeyValueRow> headers = [];
  BodyType bodyType = BodyType.none;
  String jsonBody = '';
  List<KeyValueRow> formBody = [];
  AuthType authType = AuthType.none;
  String bearerToken = '';
  String basicUsername = '';
  String basicPassword = '';
  String apiKeyHeader = 'X-API-Key';
  String apiKeyValue = '';

  PostyResponse? lastResponse;
  bool isLoading = false;
  int responseTabIndex = 0;
  int requestTabIndex = 0;
  DateTime? lastSentAt;

  /// Embedded JSON→model converter URL (default quicktype). Commit via [setQuicktypeConverterUrl].
  String quicktypeConverterUrl = PostyDefaults.quicktypeConverterUrl;

  /// Registered by [RequestBar] to flush text fields before tab changes / preview refresh.
  void Function()? urlCommitHandler;

  String get previewUrl => UrlBuilder.buildUrl(
        baseUrl: baseUrl,
        path: path,
        queryParams: queryParams,
      );

  String get formattedResponseBody {
    if (lastResponse == null) return '';
    return JsonPretty.formatResponseBody(lastResponse!.body);
  }

  int get enabledQueryCount =>
      queryParams.where((r) => r.enabled && r.key.trim().isNotEmpty).length;

  int get enabledHeaderCount =>
      headers.where((r) => r.enabled && r.key.trim().isNotEmpty).length;

  int get enabledFormBodyCount => formBody
      .where((r) => r.enabled && r.key.trim().isNotEmpty)
      .length;

  int get bodyTabBadgeCount {
    switch (bodyType) {
      case BodyType.none:
        return 0;
      case BodyType.json:
        return jsonBody.trim().isEmpty ? 0 : 1;
      case BodyType.form:
        return enabledFormBodyCount;
    }
  }

  void _ensureDefaultRows() {
    if (queryParams.isEmpty) {
      queryParams = [const KeyValueRow()];
    }
    if (headers.isEmpty) {
      headers = [const KeyValueRow()];
    }
    if (formBody.isEmpty) {
      formBody = [const KeyValueRow()];
    }
  }

  void setMethod(HttpMethod value) {
    method = value;
    notifyListeners();
  }

  /// Updates base URL and refreshes [previewUrl] in the UI (every keystroke).
  void setBaseUrl(String value) {
    baseUrl = value;
    notifyListeners();
  }

  /// Updates endpoint path and refreshes [previewUrl] in the UI (every keystroke).
  void setPath(String value) {
    path = value;
    notifyListeners();
  }

  /// Trims URL fields (call when a URL text field loses focus).
  void commitBaseUrl() {
    final trimmed = baseUrl.trim();
    if (baseUrl != trimmed) {
      baseUrl = trimmed;
      notifyListeners();
    }
  }

  void commitPath() {
    final trimmed = path.trim();
    if (path != trimmed) {
      path = trimmed;
      notifyListeners();
    }
  }

  /// Trims both fields (before send or when leaving URL inputs).
  void commitRequestUrl() {
    final trimmedBase = baseUrl.trim();
    final trimmedPath = path.trim();
    if (baseUrl != trimmedBase || path != trimmedPath) {
      baseUrl = trimmedBase;
      path = trimmedPath;
      notifyListeners();
    }
  }

  void setRequestTab(int index) {
    urlCommitHandler?.call();
    requestTabIndex = index;
    notifyListeners();
  }

  void setResponseTab(int index) {
    responseTabIndex = index;
    notifyListeners();
  }

  void setQuicktypeConverterUrl(String url) {
    quicktypeConverterUrl = PostyDefaults.normalizeQuicktypeConverterUrl(url);
    notifyListeners();
  }

  void setBodyType(BodyType type) {
    bodyType = type;
    notifyListeners();
  }

  void setJsonBody(String value) {
    jsonBody = value;
  }

  void formatJsonBody() {
    jsonBody = JsonPretty.format(jsonBody);
    notifyListeners();
  }

  void setAuthType(AuthType type) {
    authType = type;
    notifyListeners();
  }

  void setBearerToken(String value) {
    bearerToken = value;
  }

  void setBasicUsername(String value) {
    basicUsername = value;
  }

  void setBasicPassword(String value) {
    basicPassword = value;
  }

  void setApiKeyHeader(String value) {
    apiKeyHeader = value;
  }

  void setApiKeyValue(String value) {
    apiKeyValue = value;
  }

  void updateQueryParam(int index, {String? key, String? value, bool? enabled}) {
    if (index < 0 || index >= queryParams.length) return;
    queryParams[index] = queryParams[index].copyWith(
      key: key,
      value: value,
      enabled: enabled,
    );
    notifyListeners();
  }

  void addQueryParam() {
    queryParams = [...queryParams, const KeyValueRow()];
    notifyListeners();
  }

  void removeQueryParam(int index) {
    if (queryParams.length <= 1) {
      queryParams = [const KeyValueRow()];
    } else {
      queryParams = [...queryParams]..removeAt(index);
    }
    notifyListeners();
  }

  void clearQueryParams() {
    queryParams = [const KeyValueRow()];
    notifyListeners();
  }

  void importQueryFromUrl() {
    final imported = UrlBuilder.importQueryFromPathOrUrl(path, baseUrl);
    if (imported.isEmpty) return;
    queryParams = imported;
    final q = path.indexOf('?');
    if (q != -1) {
      path = path.substring(0, q);
    }
    notifyListeners();
  }

  void updateHeader(int index, {String? key, String? value, bool? enabled}) {
    if (index < 0 || index >= headers.length) return;
    headers[index] = headers[index].copyWith(
      key: key,
      value: value,
      enabled: enabled,
    );
    notifyListeners();
  }

  void addHeader() {
    headers = [...headers, const KeyValueRow()];
    notifyListeners();
  }

  void removeHeader(int index) {
    if (headers.length <= 1) {
      headers = [const KeyValueRow()];
    } else {
      headers = [...headers]..removeAt(index);
    }
    notifyListeners();
  }

  void addPresetHeaderAcceptJson() {
    headers = [
      ...headers,
      const KeyValueRow(
        key: 'Accept',
        value: 'application/json',
        enabled: true,
      ),
    ];
    notifyListeners();
  }

  void updateFormBody(
    int index, {
    String? key,
    String? value,
    bool? enabled,
    FormValueType? formValueType,
    String? filePath,
    String? fileName,
    List<int>? fileBytes,
    bool clearFile = false,
  }) {
    if (index < 0 || index >= formBody.length) return;
    formBody[index] = formBody[index].copyWith(
      key: key,
      value: value,
      enabled: enabled,
      formValueType: formValueType,
      filePath: filePath,
      fileName: fileName,
      fileBytes: fileBytes != null ? Uint8List.fromList(fileBytes) : null,
      clearFile: clearFile,
    );
    notifyListeners();
  }

  void clearFormBody() {
    formBody = [const KeyValueRow()];
    notifyListeners();
  }

  void addFormBodyRow() {
    formBody = [...formBody, const KeyValueRow()];
    notifyListeners();
  }

  void removeFormBodyRow(int index) {
    if (formBody.length <= 1) {
      formBody = [const KeyValueRow()];
    } else {
      formBody = [...formBody]..removeAt(index);
    }
    notifyListeners();
  }

  PostyRequest toRequest() => PostyRequest(
        method: method,
        baseUrl: baseUrl,
        path: path,
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

  void loadRequest(PostyRequest request) {
    method = request.method;
    baseUrl = request.baseUrl;
    path = request.path;
    queryParams = request.queryParams.isEmpty
        ? [const KeyValueRow()]
        : List.from(request.queryParams);
    headers =
        request.headers.isEmpty ? [const KeyValueRow()] : List.from(request.headers);
    bodyType = request.bodyType;
    jsonBody = request.jsonBody;
    formBody =
        request.formBody.isEmpty ? [const KeyValueRow()] : List.from(request.formBody);
    authType = request.authType;
    bearerToken = request.bearerToken;
    basicUsername = request.basicUsername;
    basicPassword = request.basicPassword;
    apiKeyHeader = request.apiKeyHeader;
    apiKeyValue = request.apiKeyValue;
    notifyListeners();
  }

  Future<void> send() async {
    if (bodyType == BodyType.json &&
        jsonBody.trim().isNotEmpty &&
        !JsonPretty.isValidJson(jsonBody)) {
      lastResponse = PostyResponse(
        body: '',
        statusCode: null,
        statusMessage: '',
        headers: const {},
        durationMs: 0,
        isSuccess: false,
        errorMessage: 'Invalid JSON in request body',
      );
      notifyListeners();
      return;
    }

    isLoading = true;
    lastResponse = null;
    notifyListeners();

    final response = await _http.send(toRequest());
    lastResponse = response;
    lastSentAt = DateTime.now();
    isLoading = false;
    notifyListeners();
  }

  void cancel() {
    _http.cancel();
    isLoading = false;
    notifyListeners();
  }
}
