# INPUT-017: Magic Mouse two-finger physical click

- Updated: 2026-11-10
- Stage: awaiting_verification
- Owner: unassigned; implementation ownership released
- Ownership checked: clean `main` at `832ea6e`; no overlapping changes observed
- Owned surfaces: Magic Mouse native click admission, preset/model/schema/catalog, focused tests and related documentation
- Requirements: SPEC §3.5, G1/G2
- Code baseline: `main` at `832ea6e` plus this uncommitted change set

## Outcome and scope

Add “Click · 2 fingers” immediately before the existing three-finger physical click, making nine Experimental presets. This means one mechanical press with two surface contacts. Reuse the source-attributed synchronous filter, optional modifier and shared action catalog; no new acquisition API, dependency, double-click timing or touch recognizer.

Exact fresh contact count selects the rule; an unassigned count passes through. Matched down/drag/up ownership and once-only action queuing survive contact/context/rule loss. Existing source, freshness, arming, revision, permission, protected-context and queue gates remain. Schema 51 protects the new trigger from older readers; schema-50 rules migrate unchanged.

## Earlier gesture acceptance

Tester report on 2026-11-10: all eight previously available Magic Mouse gestures were exercised successfully, with no issues found. This closes ordinary physical delivery and side orientation for the existing preset pool. Installed artifact, mouse model/transport and OS were not restated. It does not establish resting-finger edge behavior, both Natural Scrolling settings, native Smart Zoom/Mission Control overlap, measured latency, multi-mouse routing, protected-context stress, accessibility or other platforms. The new two-finger click was not in that tested pool.

## Acceptance and verification

- [x] Focused engine/persistence/editor tests, formatting and lint pass.
- [x] Final build and signed 1.3.2 (48) app/DMG/image verification pass.
- [x] Physical two-finger click: tester confirms excellent operation on 2026-11-10 after the build-48 handoff; exact running artifact/model/OS not independently inspected. Specific unassigned-click edge matrix remains unverified.
- [x] Live Sketch screen 58 Light/menu screenshot and Foundations 07 inspected. Existing selector reused; Sketch unchanged. Synchronize the new catalog entry in a future authorized design pass.

## Next handoff

Basic two-finger click delivery is accepted. Preserve the separate unassigned-click/safety/accessibility/platform checks; no general delivery rerun is required. [INPUT-018](INPUT-018-magic-mouse-three-finger-scroll.md) owns the next requested scroll presets.

## Software verification — 2026-11-10

Apple silicon, macOS 27.2 (26B123), Xcode 27.1; `main` baseline above plus the listed uncommitted app/tests/docs. `dev.sh format` and `dev.sh lint` pass. Focused run: 40 Swift Testing methods in five Magic Mouse suites plus both native editor layout tests pass (nine presets × six languages × Light/Dark × two heights, plus category status layouts). Final follow-up: 29 methods in four suites pass, covering exact two/three-contact rule selection, unmatched release passthrough after contact changes, once-only delivery/release across pause and configuration migration/backup/store protection. No full-suite rerun claimed.

The initial `dev.sh build` passed at **1.3.2 (47)**, schema **51**. `release.sh` passes: existing-identity app/DMG signatures and image verification, plus local appcast generation. Deliverable: `apps/rebind/build/release/Rebind.dmg`, SHA-256 `20f3dbf2c06fcf0adae783ceaf64bc3435aab4f3273d154e47b332bdba7b8d5a`. No app installation, publication, actual rule/permission change or Sketch save. Package is signed, not notarized; hardware acceptance of the new click remains open. Diff review preserves bounded synchronous admission, exact-count matching, paired ownership and schema gates; `git diff --check` passes.

## Menu grouping correction — 2026-11-10

The tester's installed-menu screenshot showed the new two-finger click in the tap group. Cause: `MagicMouseTriggerEditor.startsGroup` still inserted the physical-click separator before `.threeFingerClick`. Move that boundary to `.twoFingerClick`; the native menu now has five taps, two physical clicks and two scroll choices, separated by two dividers. This is a presentation-only correction; schema/recognition/copy remain unchanged. Build incremented to 48. Live Sketch menu structure was rechecked through MCP; no source edit/save. Final checks and package evidence follow below.

Build **1.3.2 (48)**: formatting/lint, both parameterized `MagicMouseEditorTests` methods and both native layout tests pass; final Debug build passes. `release.sh` succeeds with app/DMG signature and image verification. Current package: `apps/rebind/build/release/Rebind.dmg`, SHA-256 `4c2e67564adb5d516873137476c867b923f4fc90bfedd8f380a0507225797807`; this supersedes the build-47 package above. Grouping was checked against `MenuSelector.makeMenu` and the preset order; layout tests do not open the popup. No new engine/hardware verification or Sketch save claimed. `git diff --check` passes.

## Physical acceptance — 2026-11-10

The tester confirms the two-finger physical click works well after the build-48 handoff. This accepts ordinary delivery of the ninth preset; exact artifact/device/OS and targeted unmatched-click edge checks were not restated. Broader safety/accessibility/platform acceptance remains in the existing task owners.
