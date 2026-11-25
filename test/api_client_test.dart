import 'package:bacheca_app/core/api_client.dart';
import 'package:bacheca_app/core/api_exception.dart';
import 'package:bacheca_app/core/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends JSON requests with the stored bearer token', () async {
    // AC-NF-05
    final client = ApiClient(
      baseUrl: 'http://api.example.test',
      tokenStore: _MemoryTokenStore('session-token'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/jobs');
        expect(request.headers['authorization'], 'Bearer session-token');
        expect(request.headers['content-type'], contains('application/json'));
        expect(request.body, '{"title":"Developer"}');
        return http.Response('{"id":7}', 201);
      }),
    );

    expect(await client.post('/api/jobs', body: {'title': 'Developer'}), {
      'id': 7,
    });
  });

  test('omits the authorization header when no token is stored', () async {
    // AC-NF-05
    final client = ApiClient(
      baseUrl: 'http://api.example.test',
      tokenStore: _MemoryTokenStore(),
      client: MockClient((request) async {
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response('{"status":"ok"}', 200);
      }),
    );

    await client.get('/health');
  });

  test('maps API errors to ApiException', () async {
    // AC-NF-04
    final client = ApiClient(
      baseUrl: 'http://api.example.test',
      tokenStore: _MemoryTokenStore(),
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"code":"INVALID_CREDENTIALS",'
          '"message":"server message"}}',
          401,
        ),
      ),
    );

    await expectLater(
      client.post('/api/auth/login', body: {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'INVALID_CREDENTIALS')
            .having(
                (error) => error.message, 'message', 'Credenziali non valide'),
      ),
    );
  });

  test('preserves validation field errors', () async {
    // AC-NF-04
    final client = ApiClient(
      baseUrl: 'http://api.example.test',
      tokenStore: _MemoryTokenStore(),
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"code":"VALIDATION_ERROR","message":"Dati non validi",'
          '"fields":{"email":"Email non valida"}}}',
          400,
        ),
      ),
    );

    await expectLater(
      client.post('/api/auth/login', body: {}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.fields,
          'fields',
          {'email': 'Email non valida'},
        ),
      ),
    );
  });

  test('maps domain error codes to Italian messages', () async {
    // AC-NF-04
    final messages = {
      'EMAIL_TAKEN': 'Email già registrata',
      'INVALID_CREDENTIALS': 'Credenziali non valide',
      'UNAUTHORIZED': 'Sessione non valida, accedi di nuovo',
      'FORBIDDEN': 'Non hai accesso a questa risorsa',
      'INVALID_FILE': 'Il curriculum deve essere un PDF (max 5 MB)',
    };

    for (final entry in messages.entries) {
      final client = _errorClient(entry.key);
      await expectLater(
        client.get('/api/test'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            entry.value,
          ),
        ),
      );
    }
  });

  test('maps network failures to the Italian connection message', () async {
    // AC-NF-04
    final client = ApiClient(
      baseUrl: 'http://api.example.test',
      tokenStore: _MemoryTokenStore(),
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      client.get('/api/jobs'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Server non raggiungibile. Controlla la connessione.',
        ),
      ),
    );
  });

  test('maps NOT_FOUND according to the endpoint', () async {
    // AC-NF-04
    for (final entry in {
      '/api/jobs/7': 'Annuncio non trovato',
      '/api/jobs/7/applications': 'Annuncio non trovato',
      '/api/applications/7': 'Risorsa non trovata',
    }.entries) {
      await expectLater(
        _errorClient('NOT_FOUND').get(entry.key),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            entry.value,
          ),
        ),
      );
    }
  });
}

ApiClient _errorClient(String code) => ApiClient(
      baseUrl: 'http://api.example.test',
      tokenStore: _MemoryTokenStore(),
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"code":"$code","message":"messaggio server"}}',
          400,
        ),
      ),
    );

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore([this.token]);

  final String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {}
}
