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

/// Form body field value kind (multipart).
enum FormValueType {
  text,
  file,
}

enum AuthType {
  none,
  bearer,
  basic,
  apiKey,
}
