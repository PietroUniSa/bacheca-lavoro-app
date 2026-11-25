# Bacheca Lavoro — app Flutter

App mobile per una bacheca di annunci di lavoro (progetto universitario).
- **Aziende**: registrazione, login, pubblicazione annunci, lettura candidature
  con apertura del curriculum PDF, logout.
- **Candidati**: consultano la bacheca senza account e si candidano con
  nome, cognome, email e CV.

Back-end: repository `bacheca-backend` (Dart + shelf + SQLite), da avviare sul PC.

## Avvio
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<IP-del-PC>:8080
```
Telefono e PC devono essere sulla stessa rete Wi-Fi.

## Test
```bash
flutter test                                   # unit e widget
flutter test integration_test \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080   # scenari S1–S3 (server acceso)
```

## Scenari dimostrati
| Scenario | Requisiti | Test |
|---|---|---|
| S1 Pubblicare un annuncio | R1, R2, R4 | `integration_test/s1_publish_job_test.dart` |
| S2 Candidarsi a un annuncio | R5, R6 | `integration_test/s2_apply_test.dart` |
| S3 Consultare le candidature e uscire | R7, R3 | `integration_test/s3_review_and_logout_test.dart` |

## Metodo di sviluppo
Spec-driven development: specifiche in `docs/specs/` (requisiti EARS con ID,
scenari Gherkin, contratto OpenAPI, contratto delle Key dei widget); test di
accettazione scritti prima del codice.
