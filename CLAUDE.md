# CLAUDE.md — app (repo `bacheca-app`)

App Flutter della bacheca. Regole generali: `../CLAUDE.md` e
`../specs/00-constitution.md` (nel repo pubblicato: `docs/specs/`).

## Contratti da rispettare
- Rotte, schermate e **Key dei widget**: `specs/06-ui-flows.md`. Le Key sono
  usate dagli integration test: aggiungine pure, non rinominarle.
- Firme obbligatorie (`AppDeps`, `BachecaApp`, `CvPicker`, `CvOpener`,
  `TokenStore`, `InMemoryTokenStore`, `PickedCv`): `specs/05-architecture.md`.
- Errori server → messaggi italiani della tabella in `specs/03-domain-model.md`.

## Architettura (minima, niente over-engineering)
- `ui/` solo widget; nessuna chiamata `http` diretta dalle pagine.
- `data/*_api.dart` incapsulano gli endpoint e restituiscono modelli tipizzati.
- `state/session.dart` è l'unica fonte dello stato di login; il router lo ascolta
  (`refreshListenable`) e reindirizza.
- Ogni pagina gestisce caricamento / dati / vuoto / errore (con "Riprova").
- Navigazione dopo login e logout con `context.go(...)` (sostituisce lo stack).

## Test
| Tipo | Dove | Comando |
|---|---|---|
| Unit / widget | `test/` | `flutter test` |
| Scenari S1–S3 | `integration_test/` | vedi sotto |

Widget test: usa `AppDeps` con `InMemoryTokenStore`, picker/opener finti e un
`ApiClient` basato su `MockClient` di `package:http/testing.dart`.

Integration test (richiedono server acceso e un device/emulatore):
```bash
# terminale 1 (cartella backend/)
dart run bin/server.dart --port 8080 --data-dir ./data-it
# terminale 2 (cartella app/) — emulatore Android: l'host è 10.0.2.2
flutter test integration_test --dart-define=API_BASE_URL=http://10.0.2.2:8080
# telefono fisico: usa l'IP del PC, es. http://192.168.1.50:8080
```
Fino a T15 la cartella `integration_test/` è esclusa dall'analyzer (vedi
`analysis_options.yaml`): è normale che non compili prima di T14.

## Avvio sul telefono
```bash
flutter run --dart-define=API_BASE_URL=http://<IP-del-PC>:8080
```
Permessi di rete Android/iOS: `specs/05-architecture.md` § Rete e piattaforme.
