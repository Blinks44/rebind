# INPUT-005 — One-finger corner taps

- Updated: 2026-10-13.
- Stage: `awaiting_verification`.
- Owner: Released (code agent, 2026-10-13 session).
- Requirements: SPEC §§3.4, 4, 9; PLAN Phase 5.
- Code baseline: `main` `cc7c8c4`; uncommitted on top; no agent commit.

## Outcome and scope

A light one-finger tap inside one of the four trackpad corners runs the configured shortcut through the existing guarded tap engine. General one-finger taps stay out of scope: a one-finger contact is admissible only inside a corner that has an enabled rule. Physical clicks 2/3/4 remain a separate slice.

## Implementation

- `InputTrigger.cornerTap(TrackpadCorner)`, `TrackpadTapGesture.corner`, `TrackpadRuntime.cornerShortcuts`; `admissibleGesture(fingers:x:y:)` uses the qualified stroke origin and `TrackpadCorner.containing` (22 % edge regions).
- `TrackpadTapSequence.candidateFingerCounts` is now `1...4`; the recognizer, settling gate and mailbox dispatch are otherwise unchanged. The session's neutral-preservation check compares whole runtimes instead of listing fields.
- Schema **28**: older files cannot carry a corner trigger; 13–27 migrate unchanged.
- **Tap to click (user-approved 2026-10-13):** `TrackpadCornerClickFilter` consumes the left click macOS synthesizes from a tap in a corner with an enabled rule, so the rule replaces the click instead of being cancelled by it. It is updated per frame in the contact callback and consulted in the event-tap path inside the mailbox lock; a consumed click does not count as input activity. Only a click with no finger on the surface, within 350 ms of a qualified one-finger corner release, is consumed, together with its matching release. A press while a finger is down, clicks after other strokes, and paused/editing/recording states pass through.
- Editor: four corner presets in the existing selector, one explanation and Tap to click guidance in EN/RU/DE/FR. The saved Sketch gesture menu (screen 09) already lists them.

## Verification

Agent-observed 2026-10-13, macOS 27.0.1 / Xcode 27, injected software evidence only.

- New `TrackpadCornerTapTests` (13 functions), including consumed immediate and delayed tap clicks, pass-through of centre/unconfigured/late/moved/physical clicks and paused state. Earlier scope: each corner emits once after settling; centre and unconfigured corners never emit; movement cancels; button activity after the tap cancels and the next tap recovers; three-finger rules unaffected; spoofed/unconfigured dispatch refused; round trip and schema guard; four-language labels.
- Full Swift Testing module passes after updating two expectations (a one-finger stroke is now a recognizer candidate; a hard-coded future schema number). Native layout suites pass except `MainWindowLayoutTests`, not rerun after this change (it passed earlier the same day and does not touch this code).

## User-reported result — 2026-10-13

Built-in trackpad, macOS 27.0.1, Tap to click on, Debug build from the working tree: a tap in the configured corner ran the rule without a click; taps in the middle behaved as ordinary clicks and produced no rule output. One configuration, no timing measurements.

## Open checks

- [x] Corner tap replaces the tap click with Tap to click on (user-confirmed happy path above).
- [ ] All four corners, region accuracy, timing/latency, Tap to click off and other dragging options.
- [ ] **Tap to click.** Measure the real tap-to-click delay (it depends on dragging options) and confirm the provisional 350 ms window: a later click would pass through after the rule ran. Confirm no ordinary click is ever lost, including an external mouse click right after a corner tap, and during the engine's 3 s arming delay, when a consumed click has no rule output.
- [ ] Palm or thumb contact in the bottom corners while typing must not trigger rules; measure false positives before any release claim.

## Next handoff

User: on a named build with Tap to click on, add a corner rule and tap that corner: the rule should run without a click. Report clicks that still happen, clicks that go missing elsewhere, and accidental triggers while typing.
