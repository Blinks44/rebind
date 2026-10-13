# Phase 4: Quit selected application and open System Settings

Scope: SPEC §5 Windows and applications / Spaces and system, A1/A2, §§6–7, 9–12.
Implemented and software-tested; **requested real-app delivery is user-confirmed** (2026-10-09). Exact selected app/trigger/background/save-dialog cases were not separately restated; detailed identity/lifecycle/latency/platform checks remain open. The agent neither quit user applications nor opened System Settings or ran another input engine.

## Contract

- Windows and Applications → Quit Selected Application uses the existing native
  `.app` picker. Store a local path and bundle ID; reuse preparation on the serial
  worker to resolve symlinks and check matching APPL bundle metadata. No process
  launch, command-string interpolation or user application contents are read.
- Public `NSWorkspace.runningApplications` and `NSRunningApplication.terminate()`
  execute on MainActor through the existing single bounded Workspace handoff.
  Match bundle ID and standardized selected-copy path; require exactly one running
  `.regular` instance with a positive PID other than Rebind. Refuse missing,
  ambiguous, terminated, agent/background-only or different-copy instances. Rebind
  is excluded both by target validation and its actual PID. This quits the selected
  app, which may be in the background, rather than whichever app currently has focus.
- Recheck selected instance identity and task/generation/pause/edit/record/profile/
  session/post-permission/Secure Input gates immediately before requesting Quit.
  A request already accepted cannot be recalled. `terminate()` returning true means
  the request was sent, not that exit completed. The app may ask to save documents,
  defer or refuse quitting. Rebind never confirms dialogs, retries, forces termination,
  cold-launches a closed app, waits for app exit or claims all apps show a save prompt.
  Preparation or rejected-request failures receive a specific localized message;
  unrelated rules stay active and consumed input is not replayed.
- System → Open System Settings resolves `com.apple.systempreferences` using public
  Launch Services `urlForApplication(withBundleIdentifier:)` on the serial worker,
  validates its APPL bundle identity, then uses existing async NSWorkspace application
  opening on MainActor. No hardcoded app path, private pane URL/scheme, settings
  mutation, AppleScript/Automation permission or new dependency. System Settings
  may restore its last viewed pane; Rebind does not promise a root page.
- Existing serialized Workspace cancellation/error handling applies to both actions.
  A native opening request already accepted may still take effect after cancellation.
  New task/queue/helper or event-tap operations are not introduced.
- Schema 17 reads 1–16 without rewriting on load. Successful edits atomically save
  the new schema, retaining previous profiles, selection, rule IDs/actions/modifiers/
  activation and pause. New commands in old schemas, including inactive profiles,
  fail migration. Both have translated EN/RU/DE/FR titles, help and failures.

## Software evidence: 2026-10-09

16 new Swift Testing functions in ApplicationQuitTests and ApplicationCommandsTests;
full **342 tests / 47 suites / 0 failures** in
`build/ApplicationCommands-Final2.xcresult`. Identity/client fakes cover exact-copy
selection, own PID/ID, zero/ambiguous/terminated/nonregular targets, changes before
mutation, cancellation and one rejected request without retry. Injected Workspace
calls verify routing and non-pausing failures, final protected/lifecycle gates and
settings native-open errors. Matcher/catalog tests cover supported source families,
exact modifiers, typed payloads/labels. Unique temporary APPL bundles/stores verify
metadata validation, old-schema/inactive rejection and byte retention until save.

An initial fixture rewrote a previously read bundle's Info.plist; Foundation Bundle
cached the first identity and caused two assertions to fail. Corrected to distinct
bundle paths rather than assuming metadata-cache invalidation, then full suite passed.
The safe public lookup probe resolves System Settings at its installed path with the
expected bundle ID/type; it did not launch the app. Debug/Release/toolchain/signing
results and research/license decisions are recorded in [the historical evidence summary](../history/implementation-through-2026-10-10.md).

## Manual check

1. Restart one rebuilt authorized Rebind copy. In a test profile map a spare G603
   button to Windows and Applications → Quit Selected Application, and select a
   harmless app such as TextEdit. With its documents saved, check normal exit; also
   try the selected app in the background while another app has focus. Expect only
   the selected app to receive Quit. Record app/OS/rule used.
2. In a temporary document create an unsaved change, invoke the action, and if the
   app presents a save prompt, choose Cancel yourself. The app should remain open;
   Rebind must not confirm/discard or later force termination. Quit normally later
   with no changes. No promise every app presents a prompt (some use autosave).
3. With the selected app closed, invoke once: expect the localized failure and no
   launch. If different copies or multiple regular instances exist, check exact-copy
   matching/ambiguous refusal. Rebind must be rejected in the picker/validation.
4. Map System → Open System Settings. Check closed and already-running states,
   ordinary focus behavior and one opening per activation. Settings values must not
   change; its last viewed pane can reopen. Check old opening/activation/layout/
   click/media/Space rules and profiles after save/relaunch.
5. Safely check pause/edit/profile/record/sleep, Secure Input and revoked access
   before queued calls; no stale Quit/open/error. Accepted requests cannot be recalled.
   Rapid/hold/wheel/gesture triggers, latency, moved/deleted bundles, locales/VoiceOver,
   macOS 26 and Intel remain manual gates. Automated tests are not real-app proof.
