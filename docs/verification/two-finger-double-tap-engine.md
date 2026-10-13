# Two-finger double-tap engine and storage: 2026-10-12

Scope: [INPUT-004](../tasks/INPUT-004-two-finger-double-tap.md), SPEC §3.4 "double tap with 2, 3 or 4 fingers", PLAN Phase 5. Baseline `main` / `8e8a06e` plus uncommitted INPUT-004 source/tests. No agent commit, no production capture/configuration/grant changes, no action execution and no Sketch edits (read-only MCP confirmation of the saved preset pool only).

## Mechanism

No new capture mechanism, dependency or research decision. The existing private acquisition, short-contact recognizer, settling gate, pure sequence and guarded PID-targeted worker are reused unchanged in architecture; the two-finger identity flows through the same paths as the three/four-finger doubles from INPUT-003.

- `InputTrigger.twoFingerDoubleTap` (schema **27**; schemas 1–26 reject the payload, including inactive profiles) and payload-free `TrackpadTapGesture.twoFingerDouble` mapped to the existing sequence gesture `.doubleTap(fingers: 2)`.
- `TrackpadTapSequence.candidateFingerCounts` (`2...4`) is the single source of truth for completed-stroke qualification in `ShortContactRecognizer` and the structural gate check; one-finger/corner counts arrive with their own slice.
- `TrackpadRuntime.twoFingerDoubleShortcut` with a generalized `admissibleGesture(fingers:)`: a two-finger contact can only ever qualify the `.twoFingerDouble` identity; a general two-finger single tap remains out of scope and never becomes output or pending fallback. Mailbox lookup/submit revalidate the injected system double-click interval via `gesture.isDoubleTap`.
- A localized `twoFingerDoubleTap` catalog key (EN/RU/DE/FR) follows the existing native `threeFingerDoubleTap`/`fourFingerDoubleTap` label morphology so restored/imported rules render in lists; reconciliation to the final selector copy style ("Double tap · 2 fingers", Foundations 19) stays with UI-013/UI-018 native adoption, which also exposes the preset in the editor.

## Verification

Agent-observed on macOS **27.0.1 (26A434)** / MacBook Air arm64, Xcode **27.0** / Swift **6.4** / SDK **27**. Injected software evidence only.

- Targeted `dev.sh test -only-testing:` runs on final source: double-tap/recognizer/sequence/persistence/label suites **67 tests / 5 suites** (includes 8 new two-finger double-tap tests: pair-once, no-single-fallback at any interval, cross-finger pending drop without fallback, physical-click cancellation and recovery, targeted worker delivery, spoofed/stale-interval rejection, disabled-rule isolation; two-finger recognizer stationary/travel qualification; schema 26→27 migration and 1–26 rejection; four-language labels): pass; remaining trackpad engine suites (single/scheduling/focus/integration/sender/corner/diagnostics/buffer) **93 tests / 9 suites**: pass; matcher/persistence/migration/backup/store-protection/editor-adjacent suites **53 tests / 8 suites**: pass. Zero failures/skips in all three runs.
- Full `dev.sh test` run, same final products: Swift Testing module **663 tests / 90 suites, zero failures**. Native XCTest suites pass, with two recorded exceptions: `MainWindowLayoutTests.testSettingsDoesNotExpandNavigationBeyondTheWindow` fails 632≠600 viewport assertions caused by the concurrent uncommitted UI-021 main-shell/titlebar work (not this slice's surface; left to its owner), and `TrackpadEditorLayoutTests` hit the default test-host allowance and passes **isolated in 20.5 s** under a 180 s allowance (`xcodebuild test-without-building` from the same products). The known Settings-matrix 60 s allowance limitation documented in [double-tap-engine.md](double-tap-engine.md) applies.
- Debug `dev.sh build` passes on final app source; `git diff --check` clean; string catalog JSON validated.
- During development two fixture defects were fixed and are recorded, not hidden: the new two-finger tests initially constructed the default harness (no two-finger rule configured) and one test expired a pending pair via a late virtual-time poll before its second tap. Neither failed attempt is presented as passing evidence.

Not claimed: physical recognition accuracy/latency on real hardware, secondary-click/Zoom/Look Up coexistence under native settings, editor preset exposure (not implemented in this slice), macOS 26/Intel execution, or any suppression of native gestures.

## Next check

After the design-adoption agent exposes the "Double tap · 2 fingers" preset from the saved UI-013 source, compare physical two-finger doubles on a named build: pairs, lone taps, interval, physical secondary clicks (the native two-finger click conflict), and pause/focus cancellation. Identify device, OS/settings and actual grants.