import 'dart:convert';

class JsonPretty {
  static String format(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    try {
      final decoded = jsonDecode(trimmed);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  static bool isValidJson(String raw) {
    if (raw.trim().isEmpty) return true;
    try {
      jsonDecode(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String formatResponseBody(String body) {
    return format(body);
  }
}
