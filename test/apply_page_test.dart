import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bacheca_app/services/cv_picker.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('application uploads multipart and confirms after success', (
    tester,
  ) async {
    // AC-R6-05
    final requestStarted = Completer<void>();
    final response = Completer<http.Response>();
    const picker = _FakeCvPicker(
      PickedCv(
        name: 'cv_mario_rossi.pdf',
        bytes: [37, 80, 68, 70, 45, 49, 46, 55],
      ),
    );
    await tester.pumpWidget(
      testApp(
        MockClient((request) async {
          if (request.url.path == '/api/jobs' && request.method == 'GET') {
            return http.Response(
                jsonEncode({
                  'items': [_job]
                }),
                200);
          }
          if (request.url.path == '/api/jobs/7') {
            return http.Response(jsonEncode(_job), 200);
          }
          expect(request.url.path, '/api/jobs/7/applications');
          expect(request.method, 'POST');
          expect(request.headers['content-type'],
              startsWith('multipart/form-data;'));
          final body = request.body;
          expect(body, contains('name="firstName"'));
          expect(body, contains('Mario'));
          expect(body, contains('name="lastName"'));
          expect(body, contains('Rossi'));
          expect(body, contains('name="email"'));
          expect(body, contains('mario.rossi@example.com'));
          expect(body, contains('name="cv"'));
          expect(body, contains('filename="cv_mario_rossi.pdf"'));
          expect(body, contains('%PDF-1.7'));
          requestStarted.complete();
          return response.future;
        }),
        cvPicker: picker,
      ),
    );
    await _openApplyPage(tester);
    await _fillApplicant(tester);
    await tester.tap(find.byKey(const ValueKey('apply_pick_cv')));
    await tester.pumpAndSettle();
    expect(find.text('cv_mario_rossi.pdf'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('apply_submit')));
    await tester.pump();
    await requestStarted.future;
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('apply_submit')))
          .onPressed,
      isNull,
    );

    response.complete(http.Response(jsonEncode(_application), 201));
    await tester.pumpAndSettle();
    expect(find.text('Candidatura inviata!'), findsOneWidget);
    expect(find.byKey(const ValueKey('apply_success')), findsOneWidget);
  });

  testWidgets('rejects a selected file without PDF magic bytes', (
    tester,
  ) async {
    // AC-R6-05
    var applicationRequests = 0;
    await tester.pumpWidget(
      testApp(
        MockClient((request) async {
          if (request.url.path == '/api/jobs' && request.method == 'GET') {
            return http.Response(
                jsonEncode({
                  'items': [_job]
                }),
                200);
          }
          if (request.url.path == '/api/jobs/7') {
            return http.Response(jsonEncode(_job), 200);
          }
          applicationRequests++;
          return http.Response(jsonEncode(_application), 201);
        }),
        cvPicker: const _FakeCvPicker(
          PickedCv(
              name: 'wrong.pdf', bytes: [110, 111, 116, 32, 112, 100, 102]),
        ),
      ),
    );
    await _openApplyPage(tester);
    await _fillApplicant(tester);
    await tester.tap(find.byKey(const ValueKey('apply_pick_cv')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('apply_submit')));
    await tester.pumpAndSettle();

    expect(applicationRequests, 0);
    expect(
      find.text('Il curriculum deve essere un PDF (max 5 MB)'),
      findsOneWidget,
    );
  });
}

Future<void> _openApplyPage(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Flutter Dev'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('apply_button')));
  await tester.pumpAndSettle();
}

Future<void> _fillApplicant(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('apply_first_name')),
    'Mario',
  );
  await tester.enterText(
    find.byKey(const ValueKey('apply_last_name')),
    'Rossi',
  );
  await tester.enterText(
    find.byKey(const ValueKey('apply_email')),
    'mario.rossi@example.com',
  );
}

class _FakeCvPicker implements CvPicker {
  const _FakeCvPicker(this.cv);

  final PickedCv cv;

  @override
  Future<PickedCv?> pick() async => cv;
}

const _job = {
  'id': 7,
  'title': 'Flutter Dev',
  'description': 'Cerchiamo sviluppatori Flutter',
  'location': 'Napoli',
  'companyId': 1,
  'companyName': 'Acme Srl',
  'createdAt': '2026-11-25T10:00:00.000Z',
};

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
