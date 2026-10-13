# Phase 4: Direct Dock actions and system-shortcut follow-up

**Historical replacement:** the user now confirms Mission Control/current-app windows/Show Desktop work, but the separate keyboard sender still fails for Spaces. Space navigation and schema notes below are superseded by [the current HID shortcut slice](phase-4-spaces.md).

Scope: SPEC §5 A1/A2, §§6–7, 9–12, 2026-10-09. Supersedes the first
[desktop shortcut implementation](phase-4-desktop.md). The user reports that the
old generated shortcuts performed unintended functions, resembling Control/Option
confusion. **The three notification effects now have user-confirmed happy paths; the keyboard Space output failed user testing.** Exact cause of the old delivery failure is not established.

## Current contract

- **Mission Control, current-app windows and Show Desktop** use an isolated private
  Apple interface, `CoreDockSendNotification`, with three fixed notification names.
  No keyboard output, shortcut comparison/recording, shell, app launch, settings
  changes or keyboard fallback. A current failure shows a localized error without
  pausing unrelated rules. Cancellation is checked immediately before the call;
  accepted requests cannot be recalled or confirm the final visual effect.
- Dynamically resolve the symbol from the system HIServices framework; retain one
  image reference for the pointer's lifetime. Missing interface disables catalog
  entries and excludes native rules from matching (source input passes through).
  Existing capture/post permissions and Secure Input gates still apply. No new
  permission, library-validation bypass, helper, root or SIP modification.
- The private function has no published compatibility/threading/latency guarantee.
  It runs on the existing serial action worker, outside the input callback/UI;
  native IPC may delay later output. Presence of a symbol and return status 0 do
  not prove visual behavior or ABI/runtime compatibility on another macOS. UI labels
  this mechanism experimental; test entry/exit, targets, cancellation and timing.
- **Previous/next Space** still depend on an enabled matching system shortcut.
  Research did not establish a small reliable direct equivalent: Hammerspoon uses
  Mission Control Accessibility manipulation with visible UI/timing caveats; private
  Space setters are not established as correct Dock navigation. No such setter,
  UI automation or automatic enabling of disabled hotkeys was imported.
- Spaces now have their own sender: HID-state source, keyboard-type/timestamp
  metadata and explicit `flagsChanged` transitions around a tagged key-down/up
  pair. Construct the entire finite batch before posting, remove other modifiers
  for the pair, then restore the sampled flags (including Caps Lock/Fn state).
  No suspension/cancellation between transitions and restoration. Existing ordinary
  shortcut sending is unchanged. Snapshot restoration is a software property, not
  proof against interleaving physical key changes, left/right coexistence, keyboard
  modifier remaps or OS-delivery races; these remain mandatory hardware gates.
  This change must not be described as verified correction of the reported cause.
- Wrong/disabled Space shortcuts may reach the foreground app; neighbouring Spaces
  are required. Fn output is unsupported; system settings are not read or changed.
  A construction failure follows the existing output-error/emergency-pause path.
- Schema 12 migrates 1–11 without rewriting on load. In schema 11, convert the
  first three legacy desktop actions to native Dock actions in **all profiles**,
  preserving every other rule field/ID and profile selection/pause. Their old output
  chord is intentionally retired; Space custom chords and all earlier action types
  remain. New native payloads masquerading in older schemas are rejected. Atomic
  save, document limits and unsupported-file protection remain unchanged.

## Evidence

- Xcode 27.0 / Swift 6.4 / SDK 27.0, macOS 27.0.1 (26A434), Apple Silicon;
  deployment remains 26. Native SDK stub exports the symbol; a read-only dynamic
  resolution probe succeeds. No actual notification/keypress sent by the agent.
- Saved failing rule metadata contains Mission Control, key code 126, output
  modifiers 2 (Control), source modifiers 0. ModifierSet maps Control to maskControl
  and Option to maskAlternate. This excludes a simple persisted-enum swap in that
  rule; it does not establish what Dock received or rule out OS remaps/other tools.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/DockActionsTests-Final.xcresult`:
  **266 tests / 38 suites / 0 failures**. Eleven new functions, with retained desktop
  tests adapted for native versus Space routing. Coverage: fixed native requests,
  no key fallback, cancellation/failure, schema-11 all-profile migration/byte
  preservation, older-schema native rejection, native labels/errors and separate
  worker routing; constructed modifier transitions/pairs/tag/timestamp, exact output
  flags, restoration and invalid-input rejection. No real output or user-store write.
  Initial compile mismatch used a nonexistent result case; corrected to the existing
  unavailable result. Initial migration fixture tried validating legacy actions as
  current-schema actions; corrected the fixture, then full rerun passed.
- Build/signature/UI checks and user-store preservation are recorded in PLAN.
  Software event construction is not a hardware modifier-state or delivery test.

## Manual retest

1. Launch one rebuilt authorized copy. The existing Mission Control rule should show
   its action name without a retired output chord. Reopen its editor: experimental
   direct-action explanation, no system-shortcut controls. Loading alone does not
   rewrite the schema-11 file; a successful save writes schema 12.
2. From another app press the configured G603 button: Mission Control toggles once,
   without navigation/selection/other key effects. Repeat for current-app windows
   and Show Desktop; verify entry/exit and existing ordinary bindings.
3. For Space navigation, first verify physical Control+Left/Right (or your configured
   supported chord) actually switches Spaces. Record that chord in Rebind. Test
   plain side button, then trigger modifiers and physically held left/right modifiers.
   Check ordinary typing afterwards, no stuck Control/Option/Fn, no unintended app
   action. Include simultaneous physical modifier release; record exact results.
4. Check pause/profile/edit/recording/sleep/permission loss and queued cancellation,
   including old Apple Shortcut/audio/window/opening rules. Native accepted effects
   may finish; no stale errors or automatic key fallback should occur.
5. Measure repeated switching/animation/worker responsiveness; test multiple displays,
   full-screen targets and edge without neighbour if available. Inspect other locales,
   keyboard operation and VoiceOver. If Spaces still fail, keep them experimental
   and report the physical system chord/modifier remaps before extending the mechanism.
