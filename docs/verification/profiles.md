# Manual rule profiles — 2026-10-08

Scope: SPEC §§2, 3.2–3.3, 8–12; D1/D2 and S1/S2/S3.
Status: implemented, software-tested and Russian baseline UI inspected.
The user confirms its own bindings work after changing the selected profile.
The 2026-10-11 follow-ups confirm the requested switching scenario for one mouse button and restart persistence; separately identified selection paths and broader activation modes remain open.

## Contract

- Exactly one local profile is selected for all input categories. Only its enabled
  rules participate in matching. Identical triggers in different profiles are valid;
  ambiguous enabled rules within any profile are rejected before saving.
- Create an empty profile, copy another with fresh binding UUIDs, rename or confirm
  deletion. Names: 1–80 characters, trimmed, unique without case/accent differences,
  no control characters. UI includes the currently localized built-in label in name
  collision checks. Keep at least one profile; limit 20 profiles / 1000 total rules.
- Main-window picker and Menu Bar **Profile** submenu select manually. A profile
  named G603 applies to all mice; a name is not physical attribution. No device list,
  private sender API, detection/capability monitor or automatic app/device activation.
- Global pause is preserved on selection/create/delete. Source recognition/output
  queue and recorders are cancelled, while an already consumed source's release
  stays owned. Switching does not synthesize releases or run stale actions; an
  action already taken by the worker for dispatch before the switch cannot be recalled.
  Suppressed down/up
  symmetry is covered by software tests, not yet complete hardware measurement.
- Binding editors capture their profile; stale saves are rejected. Name dialogs
  temporarily disable matching and cancel pending recognition, with Escape/Cancel.
- Config schemas 1–5 migrate existing rules/UUIDs/actions/flags/timings/gesture
  directions and global enabled state into one stable localized **Default** profile.
  Reading never rewrites. The initial profile slice wrote schema 6; the action slices now write schema 9 atomically with all
  profiles/selection. Failed writes retain prior selection/rules/runtime; unreadable
  or mixed/future schemas lock editing without overwriting the original.
- Ordinary diagnostics retains its previous bounded mouse-only contract; no sender
  field, source checkbox or extra input subscription. Discovery/source experiments
  are retired by explicit user decision, not a universal macOS limitation claim.

## Evidence

- Xcode 27.0 / Swift 6.4 / SDK 27.0, macOS 27.0.1 (26A434), Apple Silicon.
  Deployment 26 unchanged; no Intel/macOS 26 execution claim.
- `scripts/dev.sh test -resultBundlePath build/ManualProfilesTests-Verified.xcresult`:
  **177 tests / 27 suites / 0 failures**. Retained all 159 core tests, added 18 profile
  functions, removed 21 tests alongside retired inventory/source code. Tests use
  isolated temporary stores/constructed events, not the user's file or a live tap.
- Migration versions 1–5, independent/copy IDs, inactive conflicts, duplicate names,
  malformed versions/selection, atomic round trip and failed disk commits checked.
  Mailbox/Model tests cover queue/hold/double/recording cancellation, owned release,
  unchanged pause/diagnostics, stale editor rejection and corrupt-file write locks.
- Russian native UI: original schema-5 three-rule paused configuration displays
  Default and all existing mouse rows; picker, manager, New Profile focused name
  field, blank Save disabled, cancellation and disabled final Delete inspected.
  Ordinary six-column diagnostics/permission gating inspected. Real user file hash
  unchanged; no actual profile/rule save, toggle, new permission or live posting
  performed by the agent. Menu switching with multiple populated profiles is pending.
- Debug and universal arm64/x86_64 Release, signature/privacy/project/catalog checks
  recorded in PLAN. Other locales' layout and VoiceOver remain manual checks.

- Manual test report, 2026-10-08: switching profiles changed the active binding
  output as expected. This verifies that selected-profile happy path on the existing G603
  LIGHTSPEED/G HUB setup. Exact mappings, selection UI path and OS were not restated;
  it does not verify both UI paths, held-source cancellation or restart persistence.

## User switching follow-up — 2026-10-11

In response to the requested hold → switch → release → fresh press check, the tester reports that mouse Button 4 invokes distinct actions in two profiles (audio mute and window minimize), with no old action firing when switching. This is user-reported physical selected-profile output and a successful bounded switching scenario, not agent-observed timing/suppression evidence. Mouse model, activation mode/hold duration, individual main-window/Menu Bar routes, tested bundle/revision and OS were not restated; do not infer them from the requested procedure or earlier hardware reports. Full delayed Hold/Double Press/pointer cancellation, both route-specific checks and production relaunch remain open.

### User restart follow-up — 2026-10-11

In response to the requested application-restart check, the tester confirms that the selected profile, rules and pause state persist. This is user-reported restart persistence in the tested setup. The exact bundle/revision, OS, restart method and number of enabled/paused/profile combinations were not restated. It does not establish login launch, restored-backup output, language reopen or every lifecycle/permission combination.

Next: complete disposable native export/reset/import/explicit resume with restored output in UI-007; retain the remaining route/activation/accessibility checks below.

## User checks

1. Run one rebuilt Xcode copy (⌘R). Confirm the Default profile (localized name) contains your existing
   three mouse rules and preserves pause. With rules paused, open **Manage Profiles**,
   copy Default to a second named profile; edit its actions to be visibly different.
2. Select each via the main picker and menu-bar **Profile** submenu. Check the selected
   mark/list, then actual ordinary/1000 ms hold/leftward G603 output in disposable
   TextEdit. Rules from the inactive profile must never fire; pause must not change.
3. Switch while a configured source is held or halfway through a double press/gesture.
   Release normally. No old deadline/output, new accidental activation or stuck
   button. A fresh press after release uses only the new profile's rules.
4. Open an existing binding editor, change the profile through the menu. The old
   editor should close and cannot save into the new profile. Check name-dialog
   cancellation, duplicate/invalid names, copy independence and final Delete disabled.
5. Restart with each selection, pause and enabled state; verify saved selection and
   all rules, respecting current permissions. Disconnect/reconnect the receiver:
   profiles/rules stay stored, no automatic profile switch or device list appears.
6. Rename/delete a disposable profile only; deletion asks confirmation and chooses
   another valid profile when deleting the selected one. Recheck ordinary diagnostics,
   menu operation with the main window closed, EN/DE/FR layout and VoiceOver.

Import/export, automatic activation, per-app rules and system action catalog are
outside this slice. Phase 4 audio actions are now implemented separately; see [their walkthrough](phase-4-audio.md).
