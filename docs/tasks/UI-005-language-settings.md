# UI-005 — Language settings

- Updated: 2026-10-11.
- Stage: `awaiting_verification`; selection/persistence/reopen path and software/layout/live Apply pass; production relaunch/accessibility acceptance open.
- Owner: Unassigned; `/root` native Language implementation released 2026-10-11 on `main` / `b453d8d`. Concurrent design preserved; Sketch read-only in this implementation.
- Ownership checked: 2026-10-11, `main` / `acce2f4`; delivered design owners released; native UI-001/trackpad work preserved.
- Owned surfaces: language preference/model/view/defaults/localization context, Configuration/AppModel/scene integration and required UI label resolution; tests/catalog/task/copy/native evidence and scoped indexes. Saved Sketch sources remain historical design deliverables.
- Requirements: SPEC §§10–11; PLAN Phases 7–9.
- Code baseline: design started at `acce2f4`, delivered at `b453d8d` with language preference absent. Native implementation uses `main` / `b453d8d` plus preserved General/permission work; no agent commit.

## Outcome and scope

Complete Settings → Language: System Default and EN/RU/DE/FR choices, clear active versus pending language, save failure and conditional reopen guidance. Reuse existing shell/native controls and preserve rule/profile names and runtime state. The original design delivery is now followed by native integration below; no automatic restart.

## Acceptance

- [x] Saved Light/Dark and compact four-language states, open choice menu and save/reopen feedback.
- [x] Live reusable sources, four-language copy and precise selection/persistence/native activation contract.
- [x] MCP screenshots, representative resizing/restoration, source integrity and curated evidence.
- [x] Records/index/remainder updated; native acceptance separate and ownership released.

## Saved design and checks

Current visual revision: [materials/alignment review](../verification/material-design-review.md), saved 2026-10-11. Shared Language card/profile/sidebar materials, Dark section controls and compact body offsets supersede affected original exports below; draft/save/activation/copy contracts remain valid.

`Rebind.sketch`, 2026-10-11; document ID `C93BE2C5-55E6-4493-9B4B-FD998F2DE986` (resolve again). SHA-256 `ac799cf544157aeb6efee53213eccd87eb2c848a40408b2479c4ffd818fee5d2`. Successful save callback observed; 47 screens total.

[Delivery](../verification/language-settings.md) owns eight frame IDs (40–47), six sources in live Sketch and the draft/save/native activation contract. [Copy](../verification/language-settings-copy.json): 16 four-language keys, now integrated into the app catalog.

All final frames and three resize views screenshot-inspected; 91 screen-node frames restore exactly. Saved ZIP preserves all 2,047 preceding local nodes and existing shared styles; adds 276 local nodes. PNG dimensions/signatures, copy structure and 32 outbound routes checked. Native menu/activation/persistence/accessibility and rendered translated/Dark feedback remain open. No app/rule/grant/runtime change or Git commit performed by this task.

## Native integration and acceptance

Five native choices/autonyms, page draft/Apply, failure/retry, protected storage and saved/active/reopen feedback integrated. Schema 24 migrations from 1–23 preserve source bytes/setup state. Launch language is shared by SwiftUI/Foundation labels; successful JSON save projects manual Cocoa language to the app domain only. No engine reconfiguration or automatic restart. **544 full-suite tests / zero failures**, native full/standard matrices and live Russian Dark Apply/880 × 600 inspection pass. Popup AX-name duplication repaired and rechecked. [Artifacts, activation decision and limits](../verification/input-language-native.md).

Verify actual user-controlled quit/relaunch across main/standard Settings/Menu Bar/native panels, System Default after external changes and interrupted Cocoa projection repair. Complete keyboard/focus/spoken VoiceOver/accessibility preferences. A language-configured XCTest host is narrower than production relaunch acceptance. Current material adoption is separate.

## Next handoff

- **Verification:** verify production quit/relaunch/native contexts and Cocoa projection repair; preserve runtime/profile/rules. Complete the delivery's remaining keyboard/VoiceOver/accessibility checks.
- **Design:** Settings → Advanced (safe diagnostics and import/export/reset), then category/editor/empty-state coverage in DESIGN. Existing General implementation ownership is preserved.
- User-facing handoff: **Verify Language selection and relaunch**; no task ID is required.
