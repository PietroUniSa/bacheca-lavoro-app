import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/application_test_helpers.dart';
import 'support/test_app.dart';

void main() {
  testWidgets('application detail downloads and opens the original CV', (
    tester,
  ) async {
    // AC-R7-05
    final opener = FakeCvOpener();
    await tester.pumpWidget(
      testApp(applicationFlowClient(), cvOpener: opener),
    );
    await openApplicationDetail(tester);

    expect(find.byKey(const ValueKey('application_name')), findsOneWidget);
    expect(find.byKey(const ValueKey('application_email')), findsOneWidget);
    expect(find.byKey(const ValueKey('application_date')), findsOneWidget);
    expect(find.text('cv_mario_rossi.pdf'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open_cv_button')));
    await tester.pumpAndSettle();

    expect(opener.openedBytes, testPdfBytes);
    expect(opener.openedFileName, 'cv_mario_rossi.pdf');
  });

  testWidgets('failed CV opening displays the specified message', (
    tester,
  ) async {
    // AC-R7-05
    final opener = FakeCvOpener(shouldFail: true);
    await tester.pumpWidget(
      testApp(applicationFlowClient(), cvOpener: opener),
    );
    await openApplicationDetail(tester);
    await tester.tap(find.byKey(const ValueKey('open_cv_button')));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna app per aprire il PDF'), findsOneWidget);
  });
}
