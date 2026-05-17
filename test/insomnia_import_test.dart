import 'package:flutter_test/flutter_test.dart';
import 'package:posty/posty.dart';

const _sampleYaml = '''
type: collection.insomnia.rest/5.0
name: Test Workspace
collection:
  - name: Brands
    children:
      - url: "{{ _.base_url }}/connector/api/brand"
        name: /connector/api/brand
        method: GET
        authentication:
          type: bearer
          token: "{{ _.access_token }}"
        headers:
          - name: User-Agent
            value: insomnia/10.3.1
      - url: "{{ _.base_url }}/connector/api/brand"
        name: Create brand
        method: POST
        body:
          mimeType: multipart/form-data
          params:
            - name: name
              value: Test
              disabled: false
            - name: image
              value: ""
              type: file
        authentication:
          type: bearer
          token: "{{ _.access_token }}"
''';

void main() {
  test('parses Insomnia folder and requests', () {
    final result = InsomniaYamlImporter.parse(
      _sampleYaml,
      hostBaseUrl: 'https://api.example.com',
      hostAccessToken: 'test-token-123',
    );

    expect(result.workspaceName, 'Test Workspace');
    expect(result.roots, hasLength(1));
    expect(result.roots.first.name, 'Brands');
    expect(result.roots.first.children, hasLength(2));

    final getReq = result.roots.first.children.first.request!;
    expect(getReq.method, HttpMethod.get);
    expect(getReq.path, '/connector/api/brand');
    expect(getReq.baseUrl, 'https://api.example.com');
    expect(getReq.authType, AuthType.bearer);
    expect(getReq.bearerToken, 'test-token-123');

    final postReq = result.roots.first.children[1].request!;
    expect(postReq.method, HttpMethod.post);
    expect(postReq.bodyType, BodyType.form);
    expect(postReq.formBody.any((r) => r.key == 'name'), isTrue);
  });
}
