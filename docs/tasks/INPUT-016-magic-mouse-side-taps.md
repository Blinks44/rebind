# INPUT-016: Magic Mouse left and right taps

- Updated: 2026-10-29
- Stage: awaiting_verification
- Owner: unassigned (implementation chat released)
- Ownership checked: 2026-10-29, released
- Owned surfaces: Magic Mouse runtime/tap session, `InputTrigger`, `MagicMousePreset`, schema 49, three Localizable strings
- Requirements: SPEC §3.5, acceptance G1/G2
- Code baseline: `main` at `854e8eb`, uncommitted

## Outcome and scope

User request 2026-10-29: more Magic Mouse gestures that are easy to recognize and do not compete with macOS. Selected: a one-finger tap on the left half and on the right half. macOS assigns nothing to a single one-finger tap on Magic Mouse (only the double tap, Smart Zoom), and the physical right click is a press, not a tap.

Rejected again with the reasons from [INPUT-015](INPUT-015-touch-release-scope.md): horizontal swipes (native page/full-screen app navigation), double taps (Smart Zoom, Mission Control), holds (need a sustained cancellation lifecycle).

## Behavior

- New trigger `magicMouseSideTap(left|right)`, two presets in the tap group of the Magic Mouse selector: "Tap · Left side", "Tap · Right side", with help and the existing Smart Zoom note.
- Same recognizer, timing and gates as the one-finger tap. The recognizer's contact centroid decides the side: normalized X ≤ 0.4 left, ≥ 0.6 right, the middle band belongs to neither.
- A side rule wins on its half. In the middle band, or on a half without a side rule, the ordinary one-finger tap rule applies if there is one. No conflict validation is needed.
- Schema 49; older files that contain a side tap are rejected like other future triggers; existing rules migrate unchanged.

## Acceptance

- [x] Recognition, fallback, dispatch revalidation and persistence covered by tests.
- [ ] Real Magic Mouse: left/right are not mirrored (native X orientation is assumed from trackpads and other projects, not measured on the mouse).
- [ ] Real Magic Mouse: a tap with another finger resting on the mouse. The recognizer counts all contacts, so a resting finger turns the tap into a two-finger contact; decide whether that is acceptable.
- [ ] Smart Zoom overlap and false positives during ordinary clicking/scrolling, as for the existing one-finger tap.
- [ ] Sketch: Magic Mouse selector (screen 58 Light/Dark) shows eight presets.

## Implementation and verification

`Engine/MagicMouse/MagicMouseSide.swift` (side bounds), `MagicMouseRuntime` (actions keyed by trigger; `trigger(fingers:x:)` picks side or ordinary tap), `MagicMouseTapSession`/`MagicMouseCapture`/`submitMagicMouse` carry the trigger instead of a finger count. `Model/InputTrigger.swift`, `Persistence/Configuration.swift` (schema 49), `UI/MagicMousePreset.swift`, labels/rows, six-language strings.

Tests added: side boundaries; side wins on its half, middle and unassigned half fall back, dispatch uses the matched rule; side rules alone ignore the middle and multi-finger taps; schema 49 round trip and rejection at 48. Existing mouse tests updated to the trigger-based API.

Build 34 on macOS 27.2, Apple silicon: full suite 996 passed, 2 skipped; the only failure was the new screen-lock version test's wrong expectation (macOS 25 does not exist), fixed and `ScreenLockTests` rerun green. Signed DMG and appcast in STATE. No hardware check by the agent.

## Next handoff

Tester with a Magic Mouse: add a rule to "Tap · Left side" and another to "Tap · Right side", tap each half with one finger and the mouse still, then tap the middle; report mirrored sides, missed taps, taps while another finger rests, and any Smart Zoom double effect. Design: add the two presets to the Magic Mouse selector in Sketch.
