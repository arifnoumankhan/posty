import 'package:flutter_test/flutter_test.dart';
import 'package:posty/src/models/key_value_row.dart';
import 'package:posty/src/utils/url_builder.dart';

void main() {
  test('buildUrl joins base and path', () {
    final url = UrlBuilder.buildUrl(
      baseUrl: 'https://api.example.com',
      path: '/v1/users',
    );
    expect(url, 'https://api.example.com/v1/users');
  });

  test('buildUrl joins base path prefix and endpoint', () {
    final url = UrlBuilder.buildUrl(
      baseUrl: 'https://testapp.barionsystems.com/connector',
      path: '/api',
    );
    expect(url, 'https://testapp.barionsystems.com/connector/api');
  });

  test('buildUrl appends query params', () {
    final url = UrlBuilder.buildUrl(
      baseUrl: 'https://api.example.com',
      path: '/search',
      queryParams: [
        const KeyValueRow(key: 'q', value: 'hello world', enabled: true),
        const KeyValueRow(key: 'page', value: '2', enabled: true),
        const KeyValueRow(key: 'skip', value: '1', enabled: false),
      ],
    );
    expect(url, contains('q=hello+world'));
    expect(url, contains('page=2'));
    expect(url, isNot(contains('skip')));
  });

  test('parseQueryFromUrl extracts params', () {
    final rows = UrlBuilder.parseQueryFromUrl(
      'https://x.com/path?variation_id=135&location_id=1',
    );
    expect(rows.length, 2);
    expect(rows[0].key, 'variation_id');
    expect(rows[0].value, '135');
  });
}
