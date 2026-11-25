import 'dart:convert';

import 'package:bacheca_app/app.dart';
import 'package:bacheca_app/core/token_store.dart';
import 'package:bacheca_app/deps.dart';
import 'package:bacheca_app/services/cv_opener.dart';
import 'package:bacheca_app/services/cv_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('anonymous board opens a job detail and its apply route', (
    tester,
  ) async {
    // AC-R5-03
    // AC-R5-02
    final app = _app((request) async {
      if (request.url.path == '/api/jobs') {
        return http.Response(
            jsonEncode({
              'items': [_job]
            }),
            200);
      }
      return http.Response(jsonEncode(_job), 200);
    });

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('board_list')), findsOneWidget);
    expect(find.text('Sviluppatore Flutter'), findsOneWidget);
    expect(find.text('Acme Srl'), findsOneWidget);

    await tester.tap(find.text('Sviluppatore Flutter'));
    await tester.pumpAndSettle();

    expect(find.text('Sviluppatore Flutter'), findsOneWidget);
    expect(find.byKey(const ValueKey('job_detail_title')), findsOneWidget);
    expect(find.byKey(const ValueKey('job_detail_company')), findsOneWidget);
    expect(find.byKey(const ValueKey('job_detail_date')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('job_detail_description')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('apply_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('apply_first_name')), findsOneWidget);
  });

  testWidgets('empty board displays the specified message', (tester) async {
    // AC-R5-03
    await tester.pumpWidget(
      _app((_) async => http.Response('{"items":[]}', 200)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('board_empty')), findsOneWidget);
    expect(find.text('Nessun annuncio pubblicato'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the board', (tester) async {
    // AC-R5-03
    var requests = 0;
    await tester.pumpWidget(
      _app((_) async {
        requests++;
        final job =
            requests == 1 ? _job : {..._job, 'title': 'Annuncio aggiornato'};
        return http.Response(
            jsonEncode({
              'items': [job]
            }),
            200);
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('board_refresh')), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('board_list')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('Annuncio aggiornato'), findsOneWidget);
  });

  testWidgets('board error can be retried', (tester) async {
    // AC-R5-03
    var requests = 0;
    await tester.pumpWidget(
      _app((_) async {
        requests++;
        if (requests == 1) {
          return http.Response(
            '{"error":{"code":"INTERNAL_ERROR","message":"Errore"}}',
            500,
          );
        }
        return http.Response(
            jsonEncode({
              'items': [_job]
            }),
            200);
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('board_error')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('retry_button')));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('Sviluppatore Flutter'), findsOneWidget);
  });

  testWidgets('missing job shows its API error and can be retried', (
    tester,
  ) async {
    // AC-R5-02
    // AC-R5-03
    var detailRequests = 0;
    await tester.pumpWidget(
      _app((request) async {
        if (request.url.path == '/api/jobs') {
          return http.Response(
              jsonEncode({
                'items': [_job]
              }),
              200);
        }
        detailRequests++;
        if (detailRequests == 1) {
          return http.Response(
            '{"error":{"code":"NOT_FOUND","message":"Not found"}}',
            404,
          );
        }
        return http.Response(jsonEncode(_job), 200);
      }),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sviluppatore Flutter'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job_detail_error')), findsOneWidget);
    expect(find.text('Annuncio non trovato'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('retry_button')));
    await tester.pumpAndSettle();

    expect(detailRequests, 2);
    expect(find.byKey(const ValueKey('job_detail_title')), findsOneWidget);
  });
}

const _job = {
  'id': 42,
  'title': 'Sviluppatore Flutter',
  'description': 'Descrizione completa del lavoro.',
  'location': 'Napoli',
  'companyId': 1,
  'companyName': 'Acme Srl',
  'createdAt': '2026-11-25T10:00:00.000Z',
};

BachecaApp _app(Future<http.Response> Function(http.Request) handler) =>
    BachecaApp(
      deps: AppDeps(
        apiBaseUrl: 'http://api.example.test',
        tokenStore: InMemoryTokenStore(),
        cvPicker: _FakeCvPicker(),
        cvOpener: _FakeCvOpener(),
        httpClient: MockClient(handler),
      ),
    );

class _FakeCvPicker implements CvPicker {
  @override
  Future<PickedCv?> pick() async => null;
}

class _FakeCvOpener implements CvOpener {
  @override
  Future<void> open(List<int> bytes, String fileName) async {}
}
