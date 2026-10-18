# INPUT-006: Physical trackpad clicks with 2, 3 or 4 fingers

- Updated: 2026-10-19 (manual evidence reconciliation; original software runs unchanged).
- Stage: `awaiting_verification`.
- Owner: Released (code agent, 2026-10-13 session).
- Requirements: SPEC §§3.4, 4, 9; PLAN Phase 5.
- Code baseline: `main` `cc7c8c4`; uncommitted on top; no agent commit.

## Outcome and scope

Pressing the trackpad while 2, 3 or 4 fingers rest on it runs the configured shortcut instead of the click. This completes the SPEC §3.4 preset pool in engine and editor; every preset still needs physical acceptance.

## Implementation

- `InputTrigger.trackpadClick(fingers:)` (valid for 2–4), schema **29** with a guard for older files.
- `TrackpadClickFilter` (replaces the corner-only filter from [INPUT-005](INPUT-005-corner-taps.md)) keeps the last contact count from the native callback. On the event-tap path a primary/secondary press is replaced by its rule when a frame no older than 100 ms shows the matching count: three or four fingers with either button; **two fingers only with the secondary button**, so macOS decides that the press was a two-finger click rather than a click with a resting thumb. The press, its drags and its release are consumed; the press still counts as input activity, which cancels pending light-tap output. The action is queued through the ordinary bounded pending list.
- `TrackpadRuntime.hasClickRules` keeps contact capture running when only click rules exist.
- Editor: three click presets with an explanation, secondary-click guidance for two fingers and resting-finger guidance for three/four, in EN/RU/DE/FR. Sketch screen 09 already lists them.

## Verification

Agent-observed 2026-10-13, macOS 27.0.1 / Xcode 27, injected software evidence only: new `TrackpadClickRuleTests` (7 functions) cover replacement for 3/4 fingers, the two-finger secondary-button rule, pass-through of other counts/stale frames/no contact, paused/editing/Secure Input, capture with click rules only, persistence and schema guard, labels. Full Swift Testing module passes (683 tests) with the native layout suites.

## User-reported result: 2026-10-13

Built-in trackpad, macOS 27.0.1, Debug build from the working tree: the user reports the click rules work as intended. No per-count breakdown or timing measurements.

## Open checks

- [ ] Physical behavior on the built-in trackpad for each count, including Force Click and Look Up settings.
- [ ] Two fingers when Secondary click is set to a corner or turned off (the rule then never runs; the editor says so).
- [ ] False positives: clicking with one finger while others rest on the surface; an external mouse click while fingers rest on the trackpad.
- [ ] Dragging started with a multi-finger press is lost while the rule exists; confirm this is acceptable.

## User-reported regression: 2026-10-16

With three-finger drag on, resting three or four fingers makes a click rule run after about 500 ms without a press. Fixed in [INPUT-013](INPUT-013-trackpad-review-fixes.md): three/four-finger rules require finger force (Force Touch) or a quick still press (Magic Trackpad).

## Current manual evidence — recorded 2026-10-19

Checklist 3.3 confirms built-in physical three-finger click replacement. No separate resting-finger/dragging trial breakdown, exact revision or four-finger result was supplied; preserve the broader open checks above. Source and artifact limits: [October 18 manual checklist](../verification/manual-test-2026-10-18.md). No build/test rerun; retain `awaiting_verification` for remaining acceptance.

## Next handoff

Verify the other click counts/surfaces and deliberate-press versus resting-finger/mixed-mouse negatives on the current corrected bundle; record secondary-click/Force Click settings and dragging behavior.
