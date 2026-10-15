# INPUT-004: Two-finger double-tap engine and storage

- Updated: 2026-10-16 (documentation reconciliation; dated checks unchanged).
- Stage: `awaiting_verification`.
- Owner: Kilo code agent (this chat); engine/data ownership released.
- Ownership checked: 2026-10-12 / `main` `8e8a06e`; concurrent `/root` agent owns uncommitted UI-021 main-shell surfaces (ContentView/rebindApp/MainSidebar*/Navigation.xcstrings/EditorMenuSelector/ProfilePicker/MouseBindingsView and their layout tests). No file overlap; both uncommitted work preserved.
- Owned surfaces: trackpad recognizer/gate/session/runtime/mailbox, typed trigger model, schema/migration, compile-necessary trigger label, engine/persistence/label tests and affected status/evidence sections. No editor preset exposure, Sketch edits or real configuration/permission edits.
- Requirements: SPEC §§3.4, 4, 6, 9, 12; PLAN Phase 5.
- Code baseline: `main` `8e8a06e`; uncommitted on top; no agent commit.

## Outcome and scope

Connect a two-finger double tap to guarded shortcut output, completing the SPEC §3.4 "double tap with 2, 3 or 4 fingers" row for the light-tap engine. A general two-finger single tap stays out of scope and must never become output. Reuse the pure `TrackpadTapSequence` (already models `doubleTap(2)`), the click-exclusion settling gate and the guarded worker unchanged in architecture. Physical clicks (2/3/4), corners and curated modifier variants remain separate slices; editor exposure of the new preset belongs to the design-adoption agent (UI-013 final selector; the saved pool already contains "Double tap · 2 fingers").

## Acceptance

- [x] A configured two-finger pair emits exactly one double output after settling; a lone two-finger tap never falls back to any single.
- [x] Click/activity, movement, uncertainty, focus/profile, lifecycle and late polling cancel safely and recover, including the native secondary-click conflict path.
- [x] Distinct rule round-trips; historical schemas cannot carry the new trigger; four-language trigger label renders.
- [x] Targeted tests, full regression and Debug build pass; evidence recorded.
- [ ] Physical accuracy, latency and native coexistence verified on an identified build/hardware.

## Sketch source

Read-only MCP check 2026-10-12: Rebind.sketch, document `C7326969-08D8-4B1C-8899-AA9277A9763D`. Frame "106 · Gesture selector / Trackpad · Open" contains the full curated pool including "Double tap · 2 fingers"; Foundations 19 carries the EN/RU/DE/FR copy contract. No Sketch edits. The compile-necessary `InputLabels` trigger key follows the existing native `threeFingerDoubleTap`/`fourFingerDoubleTap` label pattern; reconciliation to the final selector copy style stays with UI-013/UI-018 adoption.

## Implementation and verification

Implemented in the 2026-10-12 session (agent): `InputTrigger.twoFingerDoubleTap` and payload-free `TrackpadTapGesture.twoFingerDouble`; shared `TrackpadTapSequence.candidateFingerCounts` (2...4) used by the recognizer's completed-stroke qualification and the gate's structural check; `TrackpadRuntime.twoFingerDoubleShortcut` plumbing with a generalized `admissibleGesture(fingers:)` replacing the 3/4-only `recognizes(_:)` in the session (a two-finger contact can never produce a single output); mailbox rule lookup and dispatch-interval revalidation via `gesture.isDoubleTap`; schema **27** migration guard; `InputLabels` trigger case with a new `twoFingerDoubleTap` catalog key following the existing native label morphology (design's selector copy style stays with UI-013/UI-018 adoption).

Agent-observed on macOS 27.0.1 (26A434) / arm64, Xcode 27.0 / Swift 6.4 / SDK 27, final source (uncommitted on `8e8a06e`). Injected software evidence only; no production capture/configuration/grants or actions executed.

- Targeted suites: double-tap/recognition/sequence/persistence/labels **67 tests / 5 suites**; remaining trackpad engine suites **93 tests / 9 suites**; matcher/persistence/editor-adjacent suites **53 tests / 8 suites**: all pass, zero failures/skips.
- Full `dev.sh test` run: Swift Testing module **663 tests / 90 suites pass**, zero failures. Native XCTest suites pass except: `MainWindowLayoutTests.testSettingsDoesNotExpandNavigationBeyondTheWindow` fails 632≠600 assertions from the concurrent agent's uncommitted UI-021 titlebar/shell work (their owned surface; not fixed here), and `TrackpadEditorLayoutTests` hit a default-allowance test-host timeout and passes **isolated in 20.5 s** under a 180 s allowance (`test-without-building` from the same products). [Evidence](../verification/two-finger-double-tap-engine.md).
- Debug build passes; `git diff --check` clean. Editor exposure, physical accuracy/latency and native coexistence remain open.

## Open checks / dependency

**2026-10-13:** the preset is exposed in the Trackpad editor (`TrackpadPreset.twoFingerDoubleTap`, Smart Zoom guidance in four languages); editor suites and the localized layout test pass. The exposure dependency below is closed; physical acceptance remains.

Physical/hardware acceptance requires the user on a named build. Editor exposure is complete. The earlier concurrent Settings matrix failure is historical; UI-023 records subsequent full-window adoption/checks.

## Next handoff

Verify physical two-finger double timing, lone-tap behavior and Smart Zoom/secondary-click coexistence on a named current build using the integrated preset. Complete current editor/accessibility checks through UI-014.
