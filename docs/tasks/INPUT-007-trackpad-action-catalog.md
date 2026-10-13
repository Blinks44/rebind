# INPUT-007 — Full action catalog for Trackpad rules; display brightness actions

- Updated: 2026-10-13.
- Stage: `awaiting_verification`.
- Owner: Released (code agent, 2026-10-13 session).
- Requirements: SPEC §§3.4, 5 ("Every supported trigger uses the same action catalog"), 9.
- Code baseline: `main` `cc7c8c4`; uncommitted on top; no agent commit.

## Outcome

Trackpad tap, corner and click rules can run any catalog action, not only a keyboard shortcut. The catalog gains Increase/Decrease Display Brightness.

## Implementation

- `Binding.isValid` no longer requires a shortcut for trackpad triggers. `TrackpadRuntime.actions: [TrackpadTapGesture: RebindAction]` replaces the per-gesture shortcut fields; `submitTrackpad` queues the configured action with the audio device snapshot and the existing focus/activity/expiry target. The worker drops any expired touch dispatch before executing; shortcuts keep the targeted per-process delivery, other actions use their ordinary executors.
- The Trackpad editor shows the shared action picker; the gesture menu has group separators.
- `MediaAction.brightnessUp/.brightnessDown` use the auxiliary system-key sender (`NX_KEYTYPE_BRIGHTNESS_UP/DOWN`), listed under System with their own hint in four languages.
- Schema **30**: older files cannot carry a trackpad rule with a non-shortcut action or a brightness action.
- Sketch: action picker rows are single-line like the app (titles already describe the action); screen 09 already shows the Action selector for Trackpad.

## Verification

Agent-observed 2026-10-13, macOS 27.0.1 / Xcode 27: complete suite passes — 15 native layout tests and 684 Swift Testing tests, including a catalog test (non-shortcut tap/click rules validate, queue with a trackpad target, and are rejected in schema 29 files) and updated media-key tests for the two brightness codes. Software evidence only.

## Open checks

- [ ] Run several non-shortcut actions from taps, corners and clicks on hardware (window, Space, volume, app actions).
- [ ] Brightness keys on the built-in display and with an external display; the action stays unverified until then.

## Next handoff

User: bind a three-finger tap to a window or volume action and a rule to Increase Display Brightness; report whether each runs once.
