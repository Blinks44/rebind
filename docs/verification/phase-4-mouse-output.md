# Phase 4: Mouse click output

Scope: SPEC §5 keyboard/mouse output, A1/A2, §§2, 6–7, 9–12. Implemented and
software-tested on 2026-10-09. **User confirms all four click outputs work,
including in third-party apps, on the existing G603 setup.** Exact app names and
individual trigger/guard cases were not restated; broader hardware checks remain.

## Contract

- Shared searchable Mouse action group: left, right, middle and double left click.
  Usable with existing keyboard, middle/extra button, discrete wheel and cardinal
  button-movement triggers, including existing press/double/hold activation.
  No new trigger types or fixed enum limit on source mouse buttons.
- Click at the global Quartz pointer location sampled once on the serial action
  worker just before construction, not an old trigger coordinate or a stored point.
  Same location for every event in the click; negative monitor coordinates valid,
  missing/nonfinite coordinates fail. No cursor warp or mouse-moved event added.
  Quartz mouse events contain positions and can affect the cursor; a rapid physical
  movement racing the short batch still needs a manual check. No positions are
  logged, persisted or added to diagnostic capture.
- Public `CGEvent` mouse creation with a private-state source and session posting.
  Source suppression interval zero; ordinary hardware is not deliberately blocked.
  Left uses leftDown/up, right rightDown/up, middle otherDown/up with button 2.
  Single click has count 1; double left click sends two complete pairs with counts
  1/1/2/2. Each pair has the same event number and pressure 1/0. All flags (including
  low device-specific bits) and motion deltas cleared; output is a plain click.
  No modifier key transitions/restoration or long-lived synthetic held state.
- Existing synthetic tag guard excludes every emitted event from Rebind matching
  and safe diagnostics. Other apps' synthetic input remains eligible normally.
- Check target button in both HID and combined session state before construction
  and again after it; no release of a button already held by hardware/another source.
  Mapping held middle-button input to its own middle click therefore reports an
  error; use another trigger. Other held buttons are not the output target. The
  final generation/post-permission/Secure Input gate follows preparation/state checks.
  No output on cancellation/failure; finish all two/four prepared events once
  started so every down receives up. No delay, sleep, Task or actor hop inside batch.
- Permission requirements remain the existing Accessibility/posting gate. No helper,
  private API, root, package, system preference change or new permission. A preparation
  failure reports a localized mouse error without pausing unrelated rules; consumed
  source is not replayed. Quartz cannot acknowledge target delivery or effect.
- Schema 14 stores typed MouseAction values and reads 1–13 without rewriting on load.
  Preserve all profiles/IDs, selected profile, pause, source/activation/timing fields
  and all earlier action types, including user-confirmed Spaces. Old-schema mouse
  payloads (including inactive profiles) and unknown actions fail validation/decoding.
  Only a successful user edit writes schema 14 atomically.
- Deliberately no held output, dragging, modified-click parameter, synthetic wheel,
  back/forward, pointer selection/recording or extra-button output in this slice.

## Evidence

- 17 new Swift Testing functions (8 sender + 9 action/integration); exact full-suite
  count, Debug/Release/signature/localization/store checks and commands in PLAN.
- Real CGEvent construction and AppKit NSEvent conversion confirm click-count
  metadata; injected posting verifies balanced output/order/tap, cancellation and
  allocation failure. No real global click, app effect or user rule edit by agent.
- Pure migration/state/worker tests cover schema 13 byte retention until save,
  previous action/profile preservation, all old-schema rejection, matching exact
  modifiers across trigger families, synthetic passthrough, serial order, lifecycle,
  protected contexts and localized errors. No claim of physical stuck-button safety.
- 2026-10-09: user reports the requested four-output check works, including in
  third-party apps. This establishes reported real delivery and double-click happy
  paths, not every held-modifier/button, pointer-race or fault combination. The user
  also confirms the new app icon displays correctly after the targeted registration
  refresh. No effects produced or observed by the agent.

## Hardware walkthrough

1. Restart one rebuilt authorized Rebind. Keep existing mappings/profile settings.
   From a spare side button or keyboard key, choose Mouse → Left click. Point at a
   harmless Finder selection or native control; expect one plain click. Verify the
   original side-button/key action does not leak, ordinary primary input still works.
2. Right click over a Finder item should open its context menu. Middle click over a
   browser link should match that browser's physical middle-click behavior. Choose
   a different trigger from the output middle button; don't hold the target button.
3. Double left click over a disposable folder or text word: expect open/select-word,
   not two unrelated single clicks, no extra third click. Try rapid activations,
   inactive-window activation and the system's double-click-speed settings.
4. Test Control/Option/Command/Shift source modifiers and release afterwards. Output
   is a plain click; held physical modifier state must still work for the next normal
   shortcut/click. Hold the target output button while invoking from another trigger:
   expect a preparation error and no synthetic release. Check ordinary drag afterwards.
5. Check wheel/hold/double-trigger/cardinal gesture rules, pause/edit/profile/recording,
   sleep/Secure Input/post permission loss and queued cancellation. Check pointer
   movement during output, displays with negative coordinates, and no stuck states.
6. Reopen a saved mouse rule/profile, relaunch, and regress audio/window/opening/Apple
   Shortcuts/Spaces/ordinary bindings. Other locales/layout/VoiceOver and macOS 26/Intel
   remain manual. Record exact apps, OS/build, triggers and results before broad claims.
