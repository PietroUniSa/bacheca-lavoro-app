import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/company_test_helpers.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('logout returns to public board and clears navigation stack', (
    tester,
  ) async {
    // AC-R3-02
    await tester.pumpWidget(
      testApp(
        MockClient((request) async {
          if (request.url.path == '/api/jobs') {
            return http.Response('{"items":[]}', 200);
          }
          if (request.url.path == '/api/auth/login') {
            return http.Response(_loginResponse, 200);
          }
          if (request.url.path == '/api/companies/me/jobs') {
            return http.Response('{"items":[]}', 200);
          }
          expect(request.url.path, '/api/auth/logout');
          expect(request.headers['authorization'], 'Bearer session-token');
          return http.Response('', 204);
        }),
      ),
    );
    await loginToCompanyArea(tester);
    await tester.tap(find.byKey(const ValueKey('logout_button')));
    await tester.pumpAndSettle();

    expect(find.text('Bacheca Lavoro'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard_title')), findsNothing);
    final router = GoRouter.of(tester.element(find.byKey(
      const ValueKey('board_list'),
    )));
    expect(router.canPop(), isFalse);

    router.go('/company');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login_email')), findsOneWidget);
  });
}

const _loginResponse = '{"token":"session-token","company":{"id":1,'
    '"name":"Acme Srl","email":"hr@acme.it",'
    '"createdAt":"2026-11-25T10:00:00.000Z"}}';
