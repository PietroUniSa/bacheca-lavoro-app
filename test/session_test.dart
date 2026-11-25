import 'package:bacheca_app/app.dart';
import 'package:bacheca_app/core/api_client.dart';
import 'package:bacheca_app/core/token_store.dart';
import 'package:bacheca_app/deps.dart';
import 'package:bacheca_app/data/applications_api.dart';
import 'package:bacheca_app/data/auth_api.dart';
import 'package:bacheca_app/data/jobs_api.dart';
import 'package:bacheca_app/router.dart';
import 'package:bacheca_app/services/cv_opener.dart';
import 'package:bacheca_app/services/cv_picker.dart';
import 'package:bacheca_app/state/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restore loads the company from E4 when a token exists', () async {
    // AC-R2-04
    final tokenStore = InMemoryTokenStore('saved-token');
    final session = _session(
      tokenStore,
      (request) async {
        expect(request.url.path, '/api/me');
        expect(request.headers['authorization'], 'Bearer saved-token');
        return http.Response(_companyJson, 200);
      },
    );

    await session.restore();

    expect(session.token, 'saved-token');
    expect(session.company?.email, 'hr@acme.it');
    expect(session.isAuthenticated, isTrue);
    expect(session.isInitialized, isTrue);
  });

  test('restore clears the token when E4 returns 401', () async {
    // AC-R2-04
    final tokenStore = InMemoryTokenStore('expired-token');
    final session = _session(
      tokenStore,
      (_) async => http.Response(
        '{"error":{"code":"UNAUTHORIZED","message":"Unauthorized"}}',
        401,
      ),
    );

    await session.restore();

    expect(await tokenStore.read(), isNull);
    expect(session.token, isNull);
    expect(session.isAuthenticated, isFalse);
    expect(session.isInitialized, isTrue);
  });

  test('restore keeps the token when E4 cannot be reached', () async {
    // AC-R2-04
    final tokenStore = InMemoryTokenStore('saved-token');
    final session = _session(
      tokenStore,
      (_) async => throw http.ClientException('offline'),
    );

    await session.restore();

    expect(await tokenStore.read(), 'saved-token');
    expect(session.token, 'saved-token');
    expect(session.isAuthenticated, isTrue);
    expect(session.restoreError?.code, 'NETWORK_ERROR');
    expect(session.isInitialized, isTrue);
  });

  test('shared preferences keep the token across store instances', () async {
    // AC-R2-04
    SharedPreferences.setMockInitialValues({});
    final firstStore = SharedPreferencesTokenStore();
    await firstStore.write('saved-token');

    expect(await SharedPreferencesTokenStore().read(), 'saved-token');
  });

  testWidgets('BachecaApp opens the public board while restoring', (
    tester,
  ) async {
    // AC-R2-04
    final tokenStore = InMemoryTokenStore('saved-token');
    final deps = AppDeps(
      apiBaseUrl: 'http://api.example.test',
      tokenStore: tokenStore,
      cvPicker: _FakeCvPicker(),
      cvOpener: _FakeCvOpener(),
      httpClient: MockClient(
        (request) async => request.url.path == '/api/me'
            ? http.Response(_companyJson, 200)
            : http.Response('{"items":[]}', 200),
      ),
    );

    await tester.pumpWidget(BachecaApp(deps: deps));
    await tester.pumpAndSettle();

    expect(find.text('Bacheca Lavoro'), findsOneWidget);
    expect(await tokenStore.read(), 'saved-token');
  });

  testWidgets('logout clears session and protected routes require a token', (
    tester,
  ) async {
    // AC-R3-02
    final tokenStore = InMemoryTokenStore('saved-token');
    final session = _session(
      tokenStore,
      (request) async {
        if (request.url.path == '/api/me') {
          return http.Response(_companyJson, 200);
        }
        expect(request.url.path, '/api/auth/logout');
        expect(request.headers['authorization'], 'Bearer saved-token');
        return http.Response('', 204);
      },
    );
    final apiClient = ApiClient(
      baseUrl: 'http://api.example.test',
      tokenStore: tokenStore,
      client: MockClient((_) async => http.Response('{"items":[]}', 200)),
    );
    final router = createAppRouter(
      session,
      JobsApi(apiClient),
      AuthApi(apiClient),
      ApplicationsApi(apiClient),
      _FakeCvPicker(),
      _FakeCvOpener(),
    );
    addTearDown(router.dispose);

    await session.restore();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/company');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/company');

    await session.logout();
    await tester.pumpAndSettle();

    expect(await tokenStore.read(), isNull);
    expect(session.isAuthenticated, isFalse);
    expect(router.routeInformationProvider.value.uri.path, '/company/login');
    expect(find.byKey(const ValueKey('login_email')), findsOneWidget);

    router.go('/company');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/company/login');
    expect(router.canPop(), isFalse);
  });
}

Session _session(
  TokenStore tokenStore,
  Future<http.Response> Function(http.Request) handler,
) {
  return Session(
    apiClient: ApiClient(
      baseUrl: 'http://api.example.test',
      tokenStore: tokenStore,
      client: MockClient(handler),
    ),
    tokenStore: tokenStore,
  );
}

const _companyJson = '{"id":1,"name":"Acme Srl","email":"hr@acme.it",'
    '"createdAt":"2026-11-25T00:00:00.000Z"}';

class _FakeCvPicker implements CvPicker {
  @override
  Future<PickedCv?> pick() async => null;
}

class _FakeCvOpener implements CvOpener {
  @override
  Future<void> open(List<int> bytes, String fileName) async {}
}
