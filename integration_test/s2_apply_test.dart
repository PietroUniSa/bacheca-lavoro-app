// S2 — Candidarsi a un annuncio (R5, R6). Passi: specs/02-scenarios.md.
import 'package:bacheca_app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/env.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S2 un candidato anonimo invia la candidatura con CV', (
    tester,
  ) async {
    // Punto di partenza: esiste almeno un annuncio pubblicato
    final env = TestEnv();
    final companyToken = await env.fixtures.companyWithSession(
      env.companyEmail,
    );
    final jobId = await env.fixtures.job(companyToken, env.jobTitle);

    // Il candidato apre l'app senza autenticarsi → bacheca (AC-R5-03)
    await tester.pumpWidget(BachecaApp(deps: env.deps));
    await pumpUntilFound(
      tester,
      find.descendant(
        of: byKey('board_list'),
        matching: find.text(env.jobTitle),
      ),
    );
    expect(byKey('dashboard_title'), findsNothing);

    // Dettaglio annuncio (AC-R5-02, AC-R5-03)
    await tapAndWait(
      tester,
      find.text(env.jobTitle),
      byKey('job_detail_title'),
    );
    expect(
      find.descendant(
        of: byKey('job_detail_title'),
        matching: find.text(env.jobTitle),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: byKey('job_detail_company'),
        matching: find.text('Acme Srl'),
      ),
      findsOneWidget,
    );
    expect(byKey('job_detail_date'), findsOneWidget);
    expect(byKey('job_detail_description'), findsOneWidget);

    // Form di candidatura
    await tapAndWait(tester, byKey('apply_button'), byKey('apply_submit'));
    await tester.enterText(byKey('apply_first_name'), 'Mario');
    await tester.enterText(byKey('apply_last_name'), 'Rossi');
    await tester.enterText(byKey('apply_email'), 'mario.rossi@example.com');
    await tapAndWait(tester, byKey('apply_pick_cv'), byKey('apply_cv_name'));
    expect(
      find.descendant(
        of: byKey('apply_cv_name'),
        matching: find.textContaining('cv_mario_rossi.pdf'),
      ),
      findsOneWidget,
    );

    // Invio e conferma (AC-R6-01, AC-R6-05)
    await tapAndWait(tester, byKey('apply_submit'), byKey('apply_success'));
    expect(find.text('Candidatura inviata!'), findsOneWidget);

    // controprova sul server: la candidatura e il CV sono registrati
    final apps = await env.fixtures.applicationsOf(companyToken, jobId);
    expect(apps, hasLength(1));
    expect(apps.single['lastName'], 'Rossi');
    expect(apps.single['cvSize'], env.cvBytes.length);
  });
}
