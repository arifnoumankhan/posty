/// Shared defaults for Posty tooling (quicktype embedding, etc.).
abstract final class PostyDefaults {
  /// Default converter UI (JSON samples → Dart and other languages).
  static const String quicktypeConverterUrl = 'https://app.quicktype.io/';

  /// Accepts full URL or `host/path`; empty → default quicktype).
  static String normalizeQuicktypeConverterUrl(String input) {
    var s = input.trim();
    if (s.isEmpty) return quicktypeConverterUrl;
    if (!s.contains('://')) {
      s = 'https://$s';
    }
    final uri = Uri.tryParse(s);
    if (uri == null || uri.host.isEmpty) {
      return quicktypeConverterUrl;
    }
    return uri.toString();
  }
}
