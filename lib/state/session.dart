import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_store.dart';
import '../data/models.dart';

class Session extends ChangeNotifier {
  Session({required ApiClient apiClient, required TokenStore tokenStore})
      : _apiClient = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;
  String? _token;
  Company? _company;
  ApiException? _restoreError;
  bool _isInitialized = false;

  String? get token => _token;
  Company? get company => _company;
  ApiException? get restoreError => _restoreError;
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;

  Future<void> restore() async {
    if (_isInitialized) return;

    try {
      _token = await _tokenStore.read();
      if (_token == null) return;

      final response = await _apiClient.get('/api/me');
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Risposta azienda non valida');
      }
      _company = Company.fromJson(response);
    } on ApiException catch (error) {
      _restoreError = error;
      if (error.code == 'UNAUTHORIZED') {
        await _tokenStore.clear();
        _token = null;
        _company = null;
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> login({
    required String token,
    required Company company,
  }) async {
    await _tokenStore.write(token);
    _token = token;
    _company = company;
    _restoreError = null;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _apiClient.post('/api/auth/logout');
    await _tokenStore.clear();
    _token = null;
    _company = null;
    _restoreError = null;
    _isInitialized = true;
    notifyListeners();
  }
}
