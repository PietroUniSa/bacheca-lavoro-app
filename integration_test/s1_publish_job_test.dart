// S1 — Pubblicare un annuncio (R1, R2, R4). Passi: specs/02-scenarios.md.
import 'package:bacheca_app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/env.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('S1 un\'azienda senza account pubblica il primo annuncio', (
    tester,
  ) async {
    final env = TestEnv();
    await tester.pumpWidget(BachecaApp(deps: env.deps));
    await pumpUntilFound(tester, byKey('company_area_button'));

    // Bacheca → Area aziende → Registrati
    await tapAndWait(
      tester,
      byKey('company_area_button'),
      byKey('login_go_register'),
    );
    await tapAndWait(
      tester,
      byKey('login_go_register'),
      byKey('register_submit'),
    );

    // Registrazione
    await tester.enterText(byKey('register_name'), 'Acme Srl');
    await tester.enterText(byKey('register_email'), env.companyEmail);
    await tester.enterText(byKey('register_password'), 'Password123');
    await tapAndWait(tester, byKey('register_submit'), byKey('login_submit'));

    // AC-R1-01, AC-R1-05: conferma + login con email precompilata
    expect(find.text('Account creato'), findsOneWidget);
    expect(
      find.descendant(
        of: byKey('login_email'),
        matching: find.text(env.companyEmail),
      ),
      findsOneWidget,
    );

    // Login → area riservata (AC-R2-01, AC-R2-03)
    await tester.enterText(byKey('login_password'), 'Password123');
    await tapAndWait(tester, byKey('login_submit'), byKey('dashboard_title'));
    expect(find.text('I miei annunci'), findsWidgets);

    // Nuovo annuncio (AC-R4-01)
    await tapAndWait(tester, byKey('new_job_button'), byKey('job_publish'));
    await tester.enterText(byKey('job_title_field'), env.jobTitle);
    await tester.enterText(
      byKey('job_description_field'),
      'Cerchiamo uno sviluppatore Flutter junior per app mobile in un team agile.',
    );
    await tester.enterText(byKey('job_location_field'), 'Napoli');
    // Il finder punta alla lista: il campo titolo contiene già lo stesso testo.
    await tapAndWait(
      tester,
      byKey('job_publish'),
      find.descendant(
        of: byKey('my_jobs_list'),
        matching: find.text(env.jobTitle),
      ),
    );

    // AC-R4-04: l'annuncio è tra i miei annunci…
    expect(byKey('dashboard_title'), findsOneWidget);
    expect(
      find.descendant(
        of: byKey('my_jobs_list'),
        matching: find.text(env.jobTitle),
      ),
      findsOneWidget,
    );

    // …e nella bacheca pubblica (AC-R5-01 lato UI)
    await tapAndWait(
      tester,
      byKey('dashboard_board_button'),
      byKey('board_list'),
    );
    await pumpUntilFound(
      tester,
      find.descendant(
        of: byKey('board_list'),
        matching: find.text(env.jobTitle),
      ),
    );

    // controprova sul server
    final board = await env.fixtures.board();
    expect(board.first['title'], env.jobTitle);
  });
}
