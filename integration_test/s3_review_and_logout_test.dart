// S3 — Consultare le candidature e uscire (R7, R3). Passi: specs/02-scenarios.md.
import 'package:bacheca_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'support/env.dart';
import 'support/fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S3 l\'azienda legge una candidatura, apre il CV ed esce', (
    tester,
  ) async {
    // Punto di partenza: azienda autenticata con un annuncio e una candidatura.
    // La sessione è già salvata nel TokenStore: verifica anche AC-R2-04.
    final seed = TestEnv();
    final token = await seed.fixtures.companyWithSession(seed.companyEmail);
    final jobId = await seed.fixtures.job(token, seed.jobTitle);
    await seed.fixtures.application(jobId, tinyPdf('Mario Rossi'));
    final env = TestEnv(initialToken: token);

    await tester.pumpWidget(BachecaApp(deps: env.deps));
    await pumpUntilFound(tester, byKey('company_area_button'));

    // AC-R2-04: area riservata senza rifare login
    await tapAndWait(
      tester,
      byKey('company_area_button'),
      byKey('dashboard_title'),
    );

    // I miei annunci → annuncio → candidature (AC-R7-01, AC-R7-02)
    final myJob = find.descendant(
      of: byKey('my_jobs_list'),
      matching: find.text(seed.jobTitle),
    );
    await pumpUntilFound(tester, myJob);
    await tapAndWait(tester, myJob, byKey('applications_list'));

    // Dettaglio candidatura (AC-R7-03)
    await tapAndWait(
      tester,
      find.text('Mario Rossi'),
      byKey('application_email'),
    );
    expect(
      find.descendant(
        of: byKey('application_email'),
        matching: find.text('mario.rossi@example.com'),
      ),
      findsOneWidget,
    );
    expect(byKey('application_date'), findsOneWidget);

    // Apri curriculum: il PDF scaricato è identico all'originale (AC-R7-04, AC-R7-05)
    await tester.tap(byKey('open_cv_button'));
    final end = DateTime.now().add(const Duration(seconds: 15));
    while (env.opener.openedBytes == null && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(env.opener.openedBytes, tinyPdf('Mario Rossi'));
    expect(env.opener.openedName, 'cv_mario_rossi.pdf');

    // Torna indietro fino a I miei annunci ed esci (AC-R3-01, AC-R3-02)
    await tester.pageBack();
    await pumpUntilFound(tester, byKey('applications_list'));
    await tester.pageBack();
    await pumpUntilFound(tester, byKey('logout_button'));
    await tapAndWait(tester, byKey('logout_button'), byKey('board_list'));

    expect(byKey('dashboard_title'), findsNothing);
    expect(await env.tokenStore.read(), isNull);
    expect(await env.fixtures.meStatus(token), 401);

    // "Indietro" non riporta nell'area riservata: lo stack è stato azzerato
    final ctx = tester.element(byKey('board_list'));
    expect(GoRouter.of(ctx).canPop(), isFalse);
    expect(find.byType(BackButton), findsNothing);

    // Riaprire l'area aziende ora chiede il login
    await tapAndWait(
      tester,
      byKey('company_area_button'),
      byKey('login_submit'),
    );
    expect(byKey('dashboard_title'), findsNothing);
  });
}
