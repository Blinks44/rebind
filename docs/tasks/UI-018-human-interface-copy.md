# UI-018 — Plain-language interface copy

- Updated: 2026-10-12.
- Stage: `ready_for_implementation`; design copy and self-review complete.
- Owner: Unassigned; `/root` released design ownership 2026-10-12.
- Ownership checked: Started on `main` / `59f5754`; completion on `e74ae71` plus unrelated Trackpad work. Existing native work and the UI-019 Language materials were preserved.
- Owned surfaces: Rebind.sketch user-facing screen copy, shared Rebind text sources/overrides and corresponding localization specimens; concise task/STATE/DESIGN/history notes.
- Requirements: SPEC §§4, 7–11; PLAN phases 8–9. Preserve behavior and EN/RU/DE/FR.

## Outcome and acceptance

Review all 125 screen/state compositions and their reusable copy. Replace technical or unnatural wording with clear instructions, familiar terms and specific recovery actions. Keep the final planned design, permission distinctions, manual profile selection, independent input/output recording and language reopen behavior.

- [x] Screen, shared-source and four-language copy reviewed and edited in live Sketch.
- [x] Updated text checked live for clipping, consistency and behavioral accuracy.
- [x] Sketch saved; source/readiness notes and `git diff --check` completed.

## Evidence and next step

**Rebind.sketch**, saved/reviewed 2026-10-12 through Sketch 2026.3.1 MCP. Current document ID `C7326969-08D8-4B1C-8899-AA9277A9763D`; SHA-256 `350bfd7cfdeb2ef9b1a2be55c748c8c224bb465c72698c15eb88fd663b565902`. Inspect the live source and localization boards directly.

User-facing terminology now uses rules, concrete key/button/gesture labels and backup save/restore actions. Setup, recording, pause, profiles, errors and recovery explain the action and its result without capture-engine jargon. EN/RU/DE/FR specimens retain placeholders, permission distinctions, paused restore/reset and manual language save/quit/reopen behavior. Foundations 10 includes localized help explaining macOS button numbering.

Final self-review covered all 125 screen compositions through MCP screenshots and the edited reusable/localization sources. Corrected remaining nested labels, French grammar, recorder instructions, fixed-sensitivity wording, compact Russian wrapping and narrow access buttons. Expanded the shared empty-recorder label and the diagnostics localization board to fit complete copy. Final captures show no unresolved copy clipping; all 125 screen IDs/names/frames, Brand content and 46 imported symbol links match the initial archive. Saved archive CRC and repository whitespace checks pass.

No app code/catalog edits, build/runtime/hardware checks, routine image exports or agent Git commit. Native copy still needs reconciliation; design review does not verify actual permissions, gesture support, VoiceOver or native text expansion.

Next: **Adopt the prepared plain-language interface copy from live Sketch into the EN/RU/DE/FR String Catalog and affected native labels/help.** Preserve localized count forms and the existing language activation contract, then verify native compact layouts and accessibility on the resulting artifact.
