# UI-001 — coherent first-run and permission recovery

- Updated: 2026-10-10, seeded from saved design/implementation evidence.
- Stage: `planned` (next composition slice); initial onboarding design saved/reviewed, native onboarding not implemented.
- Owner: Unassigned. Check existing design/code chat ownership before claiming shared sources.
- Owned surfaces when claimed: named permission frames/components, affected `UI/PermissionView.swift`, new onboarding/Settings permission views and catalog keys. Coordinate `ContentView.swift`, `AppModel.swift`, `rebindApp.swift` and shared styles before edits.
- Requirements: SPEC §§6–8/10–11, S2; PLAN Phases 7–9; DESIGN's modern macOS 26+ direction.
- Code baseline inspected: `6c1a5be`, functional actual permission checks/guidance exist.

## Outcome and scope

Provide a clear native first-run flow and recovery when grants are missing/revoked. Preserve real checks and user rules/intentional pause. Start by completing the missing-permission main-window and Settings → Permissions design, then implement a bounded onboarding slice; do not build all Settings, fake grants or alter capture behavior to match a mock.

## Design handoff

Saved `Rebind.sketch`, 2026-10-10; last document ID `5E7440F8-E8FE-4C5B-9691-D1A211777C77`, resolve live again. Six initial permission frames and stable source IDs are in [DESIGN](../DESIGN.md#screen-index-and-implementation-status) and [verification](../verification/menu-bar-onboarding.md). Existing Light/Dark setup components and Apple macOS 26 controls are reusable.

Saved/reviewed states: Accessibility missing Light/Dark, AX granted/event-posting missing, ready, revoked and German expansion. Setup-later's main-window destination and Settings → Permissions need composition. Ready means actual grants, not a successful tap/engine. RU/FR/runtime layouts remain open. The saved design was visually reviewed; no separate blanket user-acceptance claim is made here.

[Copy handoff](../verification/permissions-onboarding-copy.json): 28 keys × EN/RU/DE/FR, not integrated into the app catalog. Use Writing for Interfaces when revising user-visible text; preserve terminology and all languages.

## Acceptance

- [ ] Missing-permission main-window and Settings → Permissions states saved and visually checked in current Sketch, with IDs/version/state behavior recorded.
- [ ] Native onboarding uses existing AX/posting preflights; grants are never inferred from button taps or requested by polling.
- [ ] Setup-later, ready and revocation routes are real; recording/remapping remain unavailable without required access, engine errors stay visible, deliberate pause/rules preserved.
- [ ] Current tap does not ask for unrelated Input Monitoring/Full Disk Access/Screen Recording. Automation remains action-specific.
- [ ] Native implementation builds; meaningful transition tests use isolated state; permission behavior separately checked with actual grants when authorized.
- [ ] Light/Dark, window sizing, EN/RU/DE/FR, keyboard/VoiceOver and transparency/contrast/motion settings verified for the delivered slice; handoff retains open checks.

## Implementation and verification

Baseline has `InputPermissions`, `InputPermissionRequirement`, `PermissionView`, `AppModel` actual checks and explicit request/settings/refresh routes. Existing guidance is not the saved first-launch UI. Current app has no Settings scene/About/onboarding implementation. Menu Bar asset delivery is separate and already integrated.

Prior screenshots, saved-document integrity, copy and icon-resource build checks are recorded in [menu-bar/onboarding verification](../verification/menu-bar-onboarding.md). No app build or permission grant was performed during this workflow migration.

## Next handoff

Refresh the live Sketch source and claimed ownership, compose the two missing permission surfaces using existing components and material direction, save/screenshoot and record frame IDs. Then hand the bounded onboarding implementation to a code agent using this record plus the live frames, recording any deliberate difference from the design. No automatic agent messaging or extra design-approval gate is implied.
