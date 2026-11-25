---
mode: agent
description: Implementa il prossimo task della fase B con TDD e verifica
---
Implementa il task ${input:task:ID del task, es. T10 (vuoto = il primo non spuntato)}
di `specs/07-tasks.md`. Se l'ID è vuoto, prendi il primo `[ ]` della fase B.

Segui le regole di `.github/copilot-instructions.md`. Procedi così, senza
saltare passi:

1. **Orientati.** Leggi il task e SOLO le specifiche che cita (Key UI in `06`,
   firme in `05`, messaggi in `03`). Segna il task `[~]`.
2. **Piano breve.** In 3–6 punti: file da creare o modificare (ognuno ≤200
   righe), AC coperti, test da far passare. Se trovi un'ambiguità nella
   specifica, fermati e chiedimi, proponendo il testo corretto.
3. **Rosso.** Scrivi o esegui il test del task (unit o widget in `test/`, con
   `MockClient` di `package:http/testing.dart` e `InMemoryTokenStore`) e
   conferma che fallisce per il motivo giusto.
4. **Verde.** Scrivi il codice minimo per farlo passare, niente di più.
5. **Refactor.** Pulisci, estrai widget se un file supera ~150 righe, poi
   `dart format lib test`.
6. **Gate.** Dalla radice del workspace esegui:
   - `dart tool/check_line_limit.dart`
   - `dart tool/verify_all.dart --no-tests --skip-backend`
     (da T15: `dart tool/verify_all.dart` completo)

   Se qualcosa è rosso, correggilo. Non disattivare test.
7. **Chiudi.** Spunta `[x]`, aggiorna `specs/08-traceability.md` se hai aggiunto
   test, e riassumi: file toccati · AC coperti · comandi eseguiti con esito ·
   messaggio di commit proposto `T0x: …` (non fare commit).
