# Phase 4: action catalog and audio controls: 2026-10-08

Scope: SPEC §§2, 4–6, 9–12; A1/A2. Implemented and software-tested;
Russian native catalog/editor and current-output capability checks inspected.
The user confirms the configured audio mapping and existing bindings work after
the dispatch change. Each audio variant, output replacement and cancellation/fault
scenarios remain hardware gates; exact actions/triggers were not restated.

## Contract

- Every currently supported keyboard/mouse button/wheel/pointer trigger uses the same
  searchable Keyboard/Sound catalog. Record a keyboard shortcut or choose volume
  up, volume down, or toggle mute. Other system/window/media actions are not listed
  until implemented. Choosing an action never executes it; Save stores the rule.
- Use only public Core Audio default-output main-element properties. Volume adds or
  subtracts 1/16 of the 0…1 scalar and clamps at the endpoints. This is a scalar step,
  not a loudness/decibel guarantee. Volume leaves mute unchanged; mute is a separate
  toggle. Rebind does not capture microphone/audio samples or require audio capture
  permission. No private media events, shell/AppleScript or extra dependency.
- Check main-volume/mute existence, readability and settable status independently.
  Absent/fixed-volume/channel-only output controls are unavailable in this slice;
  do not flatten channel balance or guess from an output model/transport. The picker
  disables unavailable actions, stored rules show a hint and leave input untouched.
- Capability snapshots refresh once per second on the action worker, and after a
  dispatch failure. Output identities are transient internal values, not an inventory
  or profile association. Pending audio calls target the captured default output;
  the native adapter rechecks it before writing and never redirects old work to a
  replacement output. OS device changes can race with a platform call already accepted.
- Matching/capture stays synchronous and allocation-light. One separate serial
  action thread handles HAL calls and balanced/tagged Quartz shortcut pulses. The
  shared queue is limited to 16 waiting actions, with at most one accepted call in
  flight; no unbounded task/dispatch queue. The tap run loop and UI never do HAL I/O.
- Dispatch requires active capture, enabled/not-editing/not-recording/not-suspended
  state, no Secure Input and actual post access. Revision checks cancel work after
  dequeue if profile/configuration/edit/record/pause/capture state changes. Output
  replacement/capability changes clear queued actions and temporal recognition.
  Owned releases survive cancellation when capture remains available.
- A call already accepted by the worker/platform cannot be recalled. HAL acceptance
  is not an acoustic acknowledgement, just as Quartz provides no target-delivery
  acknowledgement. Latency under slow drivers, sleep, high event rates and device
  replacement requires measurement; no real-time completion guarantee is claimed.
- Failed audio operations report a localized error and do not replay consumed source
  input; other rules remain available. Failed shortcut construction/sending requests
  emergency pause. Protected/permission-loss paths clear waiting work safely.
- Schema 7 preserves all schema-6 profiles, names, rule IDs, current selection,
  activations/directions/durations and pause, plus schemas 1–5 legacy data. Reading
  migrates only in memory; atomic Save writes the current version. New system actions
  masquerading as old schemas, unknown action values, corrupt and future files are
  rejected without overwriting. Existing unavailable audio rules remain stored.

## Evidence

- `apps/rebind/scripts/dev.sh test -resultBundlePath build/SystemAudioActionsTests-Final.xcresult`:
  **192 tests / 29 suites / 0 failures**; prior 177 retained, 15 new action functions.
  Tests inject execution/capability/preflight callbacks and use isolated storage or
  constructed input. No real Core Audio setter, global posting, live tap or user
  store writes are invoked by these tests.
- Tests cover scalar clamp/invalid readings, required shortcut data, independent
  capabilities, typed keyboard/button/wheel plus hold/double/pointer actions,
  old/current schema round trips/gates, queue ordering, cancellation after dequeue,
  unsupported-rule passthrough, output replacement/owned release, Secure Input,
  permission loss and audio/shortcut failure policy.
- Native Russian Debug UI inspected: shared chooser, grouped entries, localized
  search, current mark, audio selection, wrapped hint and Escape cancellation.
  The current output exposes available main-volume and mute controls. Main window
  still uses the saved profile; no rules/profiles saved, no audio changed and no
  AX/post grant made. User configuration remains byte-for-byte unchanged.
- Final build/signature/catalog/privacy checks and environment are recorded in PLAN.
  Deployment stays macOS 26; Intel/macOS 26 execution, EN/DE/FR layout, VoiceOver,
  physical disabled-output behavior and all audio/cancellation variants remain unverified.

- Manual test report, 2026-10-08: the configured volume-down mapping and
  existing shortcuts passed the requested regression check. Record that configured
  happy path on the existing G603 LIGHTSPEED/G HUB setup; exact actions, output,
  trigger and OS were not restated. This does not verify all three actions,
  mute/endpoint semantics, output changes or cancellation/fault cases below.

## Manual checks

1. Run one rebuilt Xcode copy with your existing permissions. In a disposable profile,
   edit/record a G603 side-button rule. Under **Action → Sound**, choose **Decrease
   Volume**, save, and press it with sound at a comfortable level. Check one step per
   press and normal release, plus existing shortcut rules. Do not test loud output
   with headphones at high volume.
2. Try **Increase Volume** and **Toggle Mute**, check endpoints and repeated mute
   toggles. Changing volume while muted must not implicitly unmute. Confirm the
   actual sound/output UI, not only Rebind's queued diagnostic row.
3. Try keyboard, a 1000 ms hold and modifier + discrete wheel. Check exact modifiers,
   one-shot hold, wheel throttle, pause/resume, emergency bypass and profile switch.
   Switch while a source is held; old pending actions must not appear after release.
4. Change the default sound output. Within roughly one second, the chooser/list should
   reflect its actual writable controls. For a fixed-volume or channel-only output,
   unavailable rules should pass the source through. Reconnect/sleep/wake and slow
   drivers need separate checks; never infer acoustic success from an enabled item.
5. Restart and inspect saved profile/selection/actions. Cancel catalog/editor changes
   without saving. Verify previous keyboard-shortcut recording, synthetic feedback
   protection and ordinary mouse diagnostics after the worker change.
6. Check localized search/no results, whole-row click, keyboard navigation and Escape
   in EN/RU/DE/FR, compact window sizes and VoiceOver. No script/permission workflow
   is expected for these audio controls.

Next: focused native/library research and implementation for application/window
commands. Mission Control/Spaces, playback, mouse output and other Phase 4 items
remain unimplemented; the phase is not complete.
