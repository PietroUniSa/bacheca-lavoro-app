# Istruzioni per GitHub Copilot — app Flutter "Bacheca Lavoro"

Stai sviluppando l'app Flutter di una bacheca di annunci di lavoro (MVP per un
esame universitario). Il back-end (Dart/shelf) è già completo e testato: **non
modificarlo**. Lavori in modalità **spec-driven**: il codice implementa le
specifiche, non il contrario.

Specifiche: `../specs/` nel workspace (nel repo pubblicato: `docs/specs/`).

## Leggi prima di tutto
1. `specs/00-constitution.md`: regole non negoziabili, valgono su tutto.
2. `specs/07-tasks.md`: fase B, cioè il primo task T08–T15 non spuntato.
3. Solo le specifiche citate dal task: `05-architecture.md` (firme obbligatorie,
   rotte, dipendenze), `06-ui-flows.md` (schermate e **Key**),
   `03-domain-model.md` (validazione e messaggi), `04-api-contract.md`.

## Regole operative
- **Un task alla volta**, nell'ordine di `07-tasks.md`. Non anticipare i task futuri.
- **Test prima**: parti da un test rosso. Ogni test ha un commento `// AC-Rx-yy`
  per ogni criterio che verifica.
- **Massimo 200 righe per file.** Qui non c'è un hook che lo controlla per te:
  verificalo tu con `dart ../tool/check_line_limit.dart` dopo ogni modifica.
  Se un file si avvicina al limite, estrai un widget o un modulo. Non comprimere
  il codice.
- Usa **solo** le dipendenze elencate in `05-architecture.md`. Mai Firebase,
  Supabase o altri BaaS.
- Le **Key** della tabella in `06-ui-flows.md` sono un contratto con gli
  integration test: usale identiche (`Key('board_list')`…), non rinominarle.
- Le **firme obbligatorie** (`AppDeps`, `BachecaApp`, `CvPicker`, `CvOpener`,
  `PickedCv`, `TokenStore`, `InMemoryTokenStore`) vanno rispettate alla lettera.
- Se una specifica è ambigua o sbagliata: **fermati** e proponi la modifica
  alla specifica. Non risolvere in silenzio nel codice.
- Testi dell'interfaccia in italiano, identificatori in inglese.
- Non modificare né disattivare i test in `integration_test/` per farli passare.

## Architettura (in breve)
- `ui/` contiene solo widget: nessuna chiamata `http` diretta dalle pagine.
- `data/*_api.dart` incapsulano gli endpoint e restituiscono modelli tipizzati.
- `state/session.dart` è l'unica fonte dello stato di login; il router
  (`go_router`) lo ascolta con `refreshListenable` e reindirizza.
- Dopo login e logout si naviga con `context.go(...)`, che azzera lo stack.
- Ogni pagina gestisce caricamento, dati, vuoto ed errore (con "Riprova").

## Definizione di "fatto" (per ogni task)
1. Il test del task è verde (`flutter test <file>`).
2. Dalla radice del workspace: `dart tool/verify_all.dart --no-tests --skip-backend`
   è verde (analisi, limite righe, tracciabilità).
3. Il task è spuntato `[x]` in `specs/07-tasks.md`.
4. Riepilogo finale: file toccati, AC coperti, comandi eseguiti con esito,
   messaggio di commit proposto `T0x: …`. Non fare commit né push.

Da T15 in poi il controllo diventa completo: `dart tool/verify_all.dart`, più gli
integration test S1–S3 con il server acceso (comandi in `CLAUDE.md` di questo repo).
