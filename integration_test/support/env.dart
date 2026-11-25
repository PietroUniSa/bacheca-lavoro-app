// Ambiente degli integration test S1–S3: backend VERO + seams finti per i
// dialog nativi (file picker, viewer PDF) che un test non può pilotare.
//
// Avvio (server già acceso, vedi app/CLAUDE.md):
//   flutter test integration_test --dart-define=API_BASE_URL=http://10.0.2.2:8080
// L'indirizzo del server arriva solo da --dart-define (AC-NF-02, verificato da
// tool/check_no_hardcoded_url.dart).
import 'package:bacheca_app/deps.dart';
import 'package:bacheca_app/services/cv_opener.dart';
import 'package:bacheca_app/services/cv_picker.dart';
import 'package:bacheca_app/core/token_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

class FakeCvPicker implements CvPicker {
  FakeCvPicker(this.cv);
  final PickedCv cv;
  @override
  Future<PickedCv?> pick() async => cv;
}

class RecordingCvOpener implements CvOpener {
  List<int>? openedBytes;
  String? openedName;
  @override
  Future<void> open(List<int> bytes, String fileName) async {
    openedBytes = bytes;
    openedName = fileName;
  }
}

class TestEnv {
  TestEnv({String? initialToken})
      : tokenStore = InMemoryTokenStore(initialToken) {
    if (apiBaseUrl.isEmpty) {
      throw StateError('Manca --dart-define=API_BASE_URL=http://<host>:8080');
    }
  }

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final InMemoryTokenStore tokenStore;
  final opener = RecordingCvOpener();
  final cvBytes = tinyPdf('Mario Rossi');
  late final picker = FakeCvPicker(
    PickedCv(name: 'cv_mario_rossi.pdf', bytes: cvBytes),
  );
  late final fixtures = Fixtures(Uri.parse(apiBaseUrl));

  String get companyEmail => 'hr$stamp@acme.it';
  String get jobTitle => 'Sviluppatore Flutter Junior #$stamp';

  AppDeps get deps => AppDeps(
        apiBaseUrl: apiBaseUrl,
        tokenStore: tokenStore,
        cvPicker: picker,
        cvOpener: opener,
      );
}

/// Le chiamate HTTP reali non generano frame: pumpAndSettle può tornare prima
/// della risposta. Questo helper pompa finché il widget compare (o timeout).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timeout: non trovato $finder');
}

Future<void> tapAndWait(
  WidgetTester tester,
  Finder target,
  Finder expected,
) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await pumpUntilFound(tester, expected);
}

Finder byKey(String key) => find.byKey(ValueKey<String>(key));
