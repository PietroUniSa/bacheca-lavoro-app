import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('successful registration opens login with email prefilled', (
    tester,
  ) async {
    // AC-R1-05
    await tester.pumpWidget(
      testApp(
        MockClient((request) async {
          if (request.url.path == '/api/jobs') {
            return http.Response('{"items":[]}', 200);
          }
          expect(request.url.path, '/api/auth/register');
          expect(jsonDecode(request.body), {
            'name': 'Acme Srl',
            'email': 'hr@acme.it',
            'password': 'Password123',
          });
          return http.Response(
            '{"id":1,"name":"Acme Srl","email":"hr@acme.it",'
            '"createdAt":"2026-11-25T10:00:00.000Z"}',
            201,
          );
        }),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('company_area_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('login_go_register')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('register_name')),
      'Acme Srl',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_email')),
      'hr@acme.it',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register_password')),
      'Password123',
    );
    await tester.tap(find.byKey(const ValueKey('register_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Account creato'), findsOneWidget);
    expect(find.byKey(const ValueKey('login_email')), findsOneWidget);
    expect(
      GoRouter.of(tester.element(find.byKey(const ValueKey('login_email'))))
          .routeInformationProvider
          .value
          .uri
          .queryParameters['email'],
      'hr@acme.it',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('login_email')))
          .controller
          ?.text,
      'hr@acme.it',
    );
  });
}
