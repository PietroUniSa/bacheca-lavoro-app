import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loginToCompanyArea(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('company_area_button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('login_email')),
    'hr@acme.it',
  );
  await tester.enterText(
    find.byKey(const ValueKey('login_password')),
    'Password123',
  );
  await tester.tap(find.byKey(const ValueKey('login_submit')));
  await tester.pumpAndSettle();
}
