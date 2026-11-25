import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStore tokenStore,
    http.Client? client,
  })  : _baseUri = Uri.parse(baseUrl),
        _tokenStore = tokenStore,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final TokenStore _tokenStore;
  final http.Client _client;

  Future<Object?> get(String path) => _send('GET', path);

  Future<List<int>> getBytes(String path) async {
    final request = http.Request('GET', _baseUri.resolve(path));
    final token = await _tokenStore.read();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final response = await _performRequest(request);
    if (response.statusCode >= 400) {
      _throwApiError(jsonDecode(response.body), path);
    }
    return response.bodyBytes;
  }

  Future<Object?> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Object?> postMultipart(
    String path, {
    required Map<String, String> fields,
    required http.MultipartFile file,
  }) async {
    final request = http.MultipartRequest('POST', _baseUri.resolve(path))
      ..fields.addAll(fields)
      ..files.add(file);
    final token = await _tokenStore.read();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    return _sendRequest(request, path);
  }

  Future<Object?> _send(String method, String path, {Object? body}) async {
    final request = http.Request(method, _baseUri.resolve(path));
    final token = await _tokenStore.read();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return _sendRequest(request, path);
  }

  Future<Object?> _sendRequest(http.BaseRequest request, String path) async {
    final response = await _performRequest(request);
    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) _throwApiError(decoded, path);
    return decoded;
  }

  Future<http.Response> _performRequest(http.BaseRequest request) async {
    late final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on http.ClientException {
      throw const ApiException(
        code: 'NETWORK_ERROR',
        message: 'Server non raggiungibile. Controlla la connessione.',
      );
    }
    return response;
  }

  Never _throwApiError(Object? body, String path) {
    if (body is! Map<String, dynamic> ||
        body['error'] is! Map<String, dynamic>) {
      throw const FormatException('Risposta di errore API non valida');
    }

    final error = body['error'] as Map<String, dynamic>;
    final code = error['code'];
    final message = error['message'];
    final rawFields = error['fields'];
    if (code is! String || message is! String) {
      throw const FormatException('Risposta di errore API non valida');
    }

    Map<String, String>? fields;
    if (rawFields != null) {
      if (rawFields is! Map<String, dynamic>) {
        throw const FormatException('Campi di errore API non validi');
      }
      fields = rawFields.map((key, value) {
        if (value is! String) {
          throw const FormatException('Campo di errore API non valido');
        }
        return MapEntry(key, value);
      });
    }
    throw ApiException(
      code: code,
      message: _messageFor(code, message, path),
      fields: fields,
    );
  }

  String _messageFor(String code, String serverMessage, String path) {
    switch (code) {
      case 'EMAIL_TAKEN':
        return 'Email già registrata';
      case 'INVALID_CREDENTIALS':
        return 'Credenziali non valide';
      case 'UNAUTHORIZED':
        return 'Sessione non valida, accedi di nuovo';
      case 'FORBIDDEN':
        return 'Non hai accesso a questa risorsa';
      case 'NOT_FOUND':
        final jobPath = RegExp(r'^/api/jobs/\d+(?:/applications)?$');
        return jobPath.hasMatch(path)
            ? 'Annuncio non trovato'
            : 'Risorsa non trovata';
      case 'INVALID_FILE':
        return 'Il curriculum deve essere un PDF (max 5 MB)';
      default:
        return serverMessage;
    }
  }
}
