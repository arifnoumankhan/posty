import 'package:flutter_test/flutter_test.dart';
import 'package:posty/posty.dart';

void main() {
  test('PostyRequest serializes to json', () {
    const request = PostyRequest(
      baseUrl: 'https://api.test',
      path: '/items',
    );
    final restored = PostyRequest.fromJson(request.toJson());
    expect(restored.baseUrl, request.baseUrl);
    expect(restored.path, request.path);
  });

  test('JsonPretty formats object', () {
    expect(
      JsonPretty.format('{"a":1}'),
      '{\n  "a": 1\n}',
    );
  });
}
