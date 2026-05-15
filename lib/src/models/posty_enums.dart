enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE'),
  head('HEAD');

  const HttpMethod(this.label);
  final String label;
}

enum BodyType {
  none,
  json,
  form,
}

enum AuthType {
  none,
  bearer,
  basic,
  apiKey,
}
