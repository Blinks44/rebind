# UI-005: Language settings and relaunch

- Updated: 2026-10-16 (documentation reconciliation)
- Stage: awaiting_verification
- Owner: Unassigned; implementation released
- Requirements: SPEC §§10–11
- Code baseline: initial native integration `b453d8d`; six-language implementation exists in `1a0801b`. No new production relaunch/native checks in this cleanup.

## Current outcome

System Default and EN/RU/DE/FR/ES/Simplified Chinese are implemented. Selection edits a draft; Apply saves atomically, retains failed drafts for retry and preserves rules/profile/pause. Saved and active language remain distinct until ordinary user-controlled quit/reopen. SwiftUI/Foundation share launch language; manual Cocoa language projection stays in the app domain and must be repairable after interruption. No automatic restart or capture reconfiguration.

[SPEC §11](../SPEC.md#11-localization-core) owns this current behavior, [DESIGN](../DESIGN.md) the visual source, and the [historical Language handoff](../history/settings-design-through-2026-10-11.md#language) the earlier four-language design evidence. Old five-choice and unfinished-Advanced notes are superseded.

## Acceptance and verification

- [x] Selection/draft/Apply, storage protection/retry, coherent saved/active/reopen feedback and shared launch-language context.
- [x] Original four-language native fixtures, geometry and scoped live Apply/AX checks.
- [ ] Production quit/relaunch across main/standard Settings/Menu Bar/native panels for all six languages.
- [ ] System Default after external changes and interrupted app-only Cocoa projection repair.
- [ ] Complete keyboard/focus/VoiceOver, localized widths, feedback and accessibility preferences.
- [ ] macOS 26; Intel only if claimed.

[Native evidence](../verification/input-language-native.md) retains original commands/artifacts: 544 full-suite tests, zero failures, full/standard Settings geometry and Russian Dark Apply at 880 × 600; duplicate popup AX naming was repaired. The original report covers System Default plus four languages. [INPUT-009](INPUT-009-held-output-exclusions-catalog.md) records the later ES/Simplified Chinese expansion. A language-configured XCTest host does not establish production relaunch or fluent translation acceptance.

## Next handoff

Verify Language selection and relaunch on a named current bundle, preserving runtime/profile/rules. Record actual languages/native contexts, Cocoa repair and accessibility results. Settings implementation and soft-system adoption already exist.
