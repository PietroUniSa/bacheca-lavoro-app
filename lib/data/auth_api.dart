import '../core/api_client.dart';
import 'models.dart';

class LoginResult {
  const LoginResult({required this.token, required this.company});

  final String token;
  final Company company;
}

class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<Company> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Risposta registrazione non valida');
    }
    return Company.fromJson(response);
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/login',
      body: {'email': email.trim().toLowerCase(), 'password': password},
    );
    if (response is! Map<String, dynamic> ||
        response['token'] is! String ||
        response['company'] is! Map<String, dynamic>) {
      throw const FormatException('Risposta login non valida');
    }
    return LoginResult(
      token: response['token'] as String,
      company: Company.fromJson(response['company'] as Map<String, dynamic>),
    );
  }
}
