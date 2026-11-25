import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bacheca_app/services/cv_opener.dart';
import 'company_test_helpers.dart';

const testPdfBytes = [37, 80, 68, 70, 45, 49, 46, 55];

class FakeCvOpener implements CvOpener {
  FakeCvOpener({this.shouldFail = false});

  final bool shouldFail;
  List<int>? openedBytes;
  String? openedFileName;

  @override
  Future<void> open(List<int> bytes, String fileName) async {
    openedBytes = bytes;
    openedFileName = fileName;
    if (shouldFail) throw Exception('CV viewer unavailable');
  }
}

MockClient applicationFlowClient() => MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/jobs') return http.Response('{"items":[]}', 200);
      if (path == '/api/auth/login') {
        return http.Response(_loginResponse, 200);
      }
      if (path == '/api/companies/me/jobs') {
        _expectToken(request);
        return http.Response(
            jsonEncode({
              'items': [_myJob]
            }),
            200);
      }
      if (path == '/api/jobs/7/applications') {
        _expectToken(request);
        return http.Response(
            jsonEncode({
              'items': [_application]
            }),
            200);
      }
      if (path == '/api/applications/11') {
        _expectToken(request);
        return http.Response(jsonEncode(_application), 200);
      }
      if (path == '/api/applications/11/cv') {
        _expectToken(request);
        return http.Response.bytes(
          testPdfBytes,
          200,
          headers: {'content-type': 'application/pdf'},
        );
      }
      fail('Unexpected request: ${request.method} $path');
    });

Future<void> openApplicationDetail(WidgetTester tester) async {
  await loginToCompanyArea(tester);
  await tester.tap(find.text('Sviluppatore Flutter'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mario Rossi'));
  await tester.pumpAndSettle();
}

void _expectToken(http.Request request) {
  expect(request.headers['authorization'], 'Bearer session-token');
}

const _loginResponse = '{"token":"session-token","company":{"id":1,'
    '"name":"Acme Srl","email":"hr@acme.it",'
    '"createdAt":"2026-11-25T10:00:00.000Z"}}';

const _application = {
  'id': 11,
  'jobId': 7,
  'firstName': 'Mario',
  'lastName': 'Rossi',
  'email': 'mario.rossi@example.com',
  'cvOriginalName': 'cv_mario_rossi.pdf',
  'cvSize': 8,
  'createdAt': '2026-11-25T10:00:00.000Z',
};

const _myJob = {
  'id': 7,
  'title': 'Sviluppatore Flutter',
  'description': 'Descrizione test annuncio',
  'location': 'Napoli',
  'companyId': 1,
  'companyName': 'Acme Srl',
  'createdAt': '2026-11-25T10:00:00.000Z',
  'applicationCount': 1,
};
