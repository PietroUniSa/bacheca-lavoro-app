class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.fields,
  });

  final String code;
  final String message;
  final Map<String, String>? fields;

  @override
  String toString() => 'ApiException($code): $message';
}
