import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/company_test_helpers.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('company dashboard lists jobs and application counts', (
    tester,
  ) async {
    // AC-R7-01
    await tester.pumpWidget(
      testApp(
        MockClient((request) async {
          if (request.url.path == '/api/jobs') {
            return http.Response('{"items":[]}', 200);
          }
          if (request.url.path == '/api/auth/login') {
            return http.Response(_loginResponse, 200);
          }
          expect(request.url.path, '/api/companies/me/jobs');
          return http.Response(
            '{"items":[${jsonEncode(_myJob)}]}',
            200,
          );
        }),
      ),
    );
    await loginToCompanyArea(tester);

    expect(find.byKey(const ValueKey('dashboard_title')), findsOneWidget);
    expect(find.byKey(const ValueKey('my_jobs_list')), findsOneWidget);
    expect(find.text('Flutter Dev'), findsOneWidget);
    expect(find.text('2 candidature'), findsOneWidget);
  });

  testWidgets('publishing refreshes my jobs and the public board', (
    tester,
  ) async {
    // AC-R4-04
    var published = false;
    await tester.pumpWidget(
      testApp(
        MockClient((request) async {
          if (request.url.path == '/api/jobs' && request.method == 'GET') {
            return http.Response(
              jsonEncode({
                'items': published ? [_job] : []
              }),
              200,
            );
          }
          if (request.url.path == '/api/auth/login') {
            return http.Response(_loginResponse, 200);
          }
          if (request.url.path == '/api/companies/me/jobs') {
            return http.Response(
              jsonEncode({
                'items': published ? [_myJob] : []
              }),
              200,
            );
          }
          expect(request.method, 'POST');
          expect(request.url.path, '/api/jobs');
          expect(request.headers['authorization'], 'Bearer session-token');
          expect(jsonDecode(request.body), {
            'title': 'Flutter Dev',
            'description': 'Cerchiamo sviluppatori Flutter',
            'location': 'Napoli',
          });
          published = true;
          return http.Response(jsonEncode(_job), 201);
        }),
      ),
    );
    await loginToCompanyArea(tester);

    await tester.tap(find.byKey(const ValueKey('new_job_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('job_title_field')),
      'Flutter Dev',
    );
    await tester.enterText(
      find.byKey(const ValueKey('job_description_field')),
      'Cerchiamo sviluppatori Flutter',
    );
    await tester.enterText(
      find.byKey(const ValueKey('job_location_field')),
      'Napoli',
    );
    await tester.tap(find.byKey(const ValueKey('job_publish')));
    await tester.pumpAndSettle();

    expect(find.text('Flutter Dev'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dashboard_board_button')));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Dev'), findsOneWidget);
  });
}

const _loginResponse = '{"token":"session-token","company":{"id":1,'
    '"name":"Acme Srl","email":"hr@acme.it",'
    '"createdAt":"2026-11-25T10:00:00.000Z"}}';

const _job = {
  'id': 7,
  'title': 'Flutter Dev',
  'description': 'Cerchiamo sviluppatori Flutter',
  'location': 'Napoli',
  'companyId': 1,
  'companyName': 'Acme Srl',
  'createdAt': '2026-11-25T10:00:00.000Z',
};

const _myJob = {
  ..._job,
  'applicationCount': 2,
};
