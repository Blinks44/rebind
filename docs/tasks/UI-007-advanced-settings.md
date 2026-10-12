# UI-007 — Advanced settings and safe configuration management

- Updated: 2026-10-12.
- Stage: `awaiting_verification`; native implementation integrated, software/native cancellation checks pass.
- Owner: Unassigned; `/root` released bounded Advanced feedback/material adoption on 2026-10-12. Sketch read-only.
- Ownership checked: `main` / `a6471db`; preserved Trackpad completion documents. Scope: Advanced view/action card, additive shared success feedback token, native layout fixtures and this task/evidence/STATE/history.
- Baseline: `main` / `bf36465` plus final Advanced alert/diagnostic/test refinements; no agent commit. HEAD advanced externally during implementation.
- Requirements: SPEC §§7, 9–11, 15.12; PLAN Phases 7–9.
- Owned implementation surfaces: Advanced settings/model/file operations, scoped AppModel replacement/editor guards, diagnostics presentation, catalog additions and tests. Independent Mouse design and prior General/Input/Language work preserved.

## Outcome

Deliver Settings → Advanced in the current macOS 26 design system: existing opt-in safe mouse diagnostics, validated configuration import/export, explicit replacement/reset confirmation, protected-file and failure states, Light/Dark and compact EN/RU/DE/FR copy. Native implementation exists; required restored-binding runtime/accessibility acceptance remains open.

## Acceptance

- [x] Inspected actual diagnostics/storage and live Sketch; reused Apple macOS 26 alerts, progress and buttons.
- [x] Completed overview, diagnostic, import/reset and protected/failure compositions.
- [x] Reviewed Light/Dark, RU/DE/FR 880×600 overview and translated diagnostic sizing; fixed German footer clipping and blocked-state guidance.
- [x] Saved and reviewed source; behavior and four-language copy are inside Sketch, ownership released. No routine exports or separate visual manual.
- [x] Integrated native import/export panels, staged localized counts, safe confirmation, atomic paused replacement/reset and raw protected-original export.
- [x] Verified rollback/retry, aliases, protected originals, cancellation/stale reviews, pending-output/source-release ownership and language/setup boundaries in authored software fixtures.
- [x] Full suite: 570 tests / zero failures; Debug build/signature and native layout checks pass. Native Escape/Return cancellation checked after the alert fix.
- [ ] Execute SPEC §15.12 with restored binding behavior on an identified build; complete keyboard/VoiceOver/accessibility-preference acceptance.

## Saved source and review

Open **Rebind.sketch** through MCP: Screens **48–69**, Foundations **05** (behavior/native/accessibility) and **06–10** (EN/RU/DE/FR copy), Symbols (paired Advanced action cards and diagnostic table row). Resolve the document afresh; [DESIGN](../DESIGN.md) is the short locator/current revision. All 22 new screen/state compositions were inspected through live screenshots after their relevant edits; original 47 screens and Brand remain intact. Final saved ZIP CRC, all 2,323 previous local IDs/47 screen rectangles, 2,896 unique final local IDs and unchanged Brand were checked. All 192 original localized copy values were found in the Sketch annotations before deleting their temporary JSON duplicate. The shape/Activation correction is recorded in UI-006.

Native file panels, alerts, focus rings and accessibility adaptations use macOS controls; their actual Dark/localized rendering and transitions require app verification. Mock counts/events are authored examples. No app build/runtime/real import/reset test or Git commit by this design task.

## Implementation and verification

Read [native behavior, identified artifact, commands, review findings and limits](../verification/advanced-settings-native.md). UI-008's codec remains the storage foundation; no schema/dependency/capture-scope change. Native panels/NSAlert adapt the Sketch states; compact navigation falls back to a native menu when five segments exceed available width. Import/reset persist before runtime changes and always leave remapping paused. Setup acknowledgement stays local; language activation follows reopen. Protected originals cannot be silently overwritten. Escape required a sheet-scoped AppKit fix; final native cancellation and behavioral tests pass. Temporary interactive fixture removed before the final suite.

## Next

2026-10-11 [navigation/accessibility report](../verification/advanced-settings-native.md#user-navigationaccessibility-follow-up--2026-10-11): tester reports the named checks work. Specific controls, VoiceOver/preferences and artifact were not specified; keep detailed acceptance open. Further implementation can proceed; do not repeat a broad check as though no result was supplied.

2026-10-11 [user restoration follow-up](../verification/advanced-settings-native.md#user-restoration-follow-up--2026-10-11): backup restoration/restored rules reported working. Exact sequence and artifact were not restated; this confirms the happy path without closing the complete §15.12/accessibility gate. Next check native keyboard/focus and VoiceOver.

2026-10-11 software follow-up: [STORAGE-001 evidence](../verification/protected-saves-and-restoration.md) covers ordinary saves after launch and six temporary export/reset/import/resume scenarios through the real matcher/worker with injected output. Restored selection/options, paused import, old pending-output cancellation and held-source release ownership pass. This does not close the physical/native SPEC §15.12 or accessibility gate above.

Verify the Advanced export → reset → import → explicit resume walkthrough with disposable authored profiles on the identified build, then keyboard/VoiceOver and accessibility preferences using the evidence checklist. Production restart/login/language checks remain user-led. Mouse design is independently active in UI-009; consume only its released live Sketch scope when ready.

## Settings feedback and materials — 2026-10-12

Shared raised cards/recovery controls and semantic error/warning/success/progress/reopen states adopted from live Sketch. Feedback now follows the affected backup/reset operation. [Evidence](../verification/advanced-feedback-adoption.md): 14 functions / 34 executions, 720 native viewports, Debug/signature and scoped live Light/Dark/German checks pass. Engine/model/storage/schema/translations/Sketch are unchanged; reviewed UI-018 copy remains separate. Work is uncommitted on `a6471db`; independent Trackpad notes and later focus-confirmation updates preserved.

Bounded implementation/checks complete; broader task remains `awaiting_verification`. [User follow-up](../verification/advanced-feedback-adoption.md#user-verification-follow-up--2026-10-12): requested Advanced checks reported working; individual states/build/preferences were not restated. Preserve that bounded confirmation. Adaptive/platform and detailed §15.12 acceptance remain separate. Next implementation: remaining Input/settings surfaces and reviewed copy from live Sketch using the shared controls.
