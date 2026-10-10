# Phase 4 — Previous Application

Scope: SPEC §5 Windows/applications / A1/A2, §§2, 6–7, 9–12.
Implemented and software-tested; the user confirms the requested AX retest works
(2026-10-09), without restating individual apps/triggers. Detailed checks remain open.
With the original AppKit backend, Rebind → app worked but Messages ↔ Finder failed
(2026-10-09).
The notification-order fix alone did not resolve background switching. Public AX
activation replaces the cooperative AppKit request and now has user-reported
happy-path confirmation. No broader safety/platform claim.
The agent did not start an observation session, activate any real application or
change user rules/permissions for this slice.

## Contract

- Shared Windows and Applications catalog → Previous Application, no parameters.
  Existing key, mouse-button, wheel and cardinal gesture triggers share the action.
- Public NSWorkspace activation notifications and running-app metadata on
  MainActor; serial worker prepares a typed value and uses one bounded Workspace
  slot. Exclusively owned AX references transfer through Swift 6 `sending` to
  a structured concurrent call. IPC never runs on MainActor or the input tap.
- Two observed regular external app handles in memory, seeded with current
  foreground at start. Repeated same-app observations preserve the preceding app.
  Rebind/background apps are skipped. From Rebind, return to the last external app;
  from another regular app, return to the preceding observed app. Visit two apps
  after starting Rebind; there is no system-wide historical Command-Tab order.
- Record the affected app from each notification's `applicationUserInfoKey`;
  the cached foreground property may still describe an earlier app in that run-loop
  turn. Resample actual frontmost app at dispatch to reconcile delayed notifications; requests never
  optimistically modify history. Native dispatch uses a value snapshot so a
  reentrant activation observation can safely update live history independently.
  Stop unregisters notifications and clears both handles. No disk, app-name log,
  text, window titles, document data, process enumeration or persistent usage history.
- Exited retained objects, unsupported foreground and changed focus are refused.
  No PID-based replacement, relaunch, older-target fallback or write retry. Set
  the public AXFrontmost attribute after support/focus/trust checks and native
  instance revalidation. The reused AX client has a 450 ms IPC budget, ≤150 ms
  per call. Verify the actual AX focused application up to six times, at most
  five 20 ms structured waits; acceptance without focus reports failure. macOS
  owns hidden/minimized windows, fullscreen, Spaces and configuration effects.
  A native write already accepted cannot be recalled by cancelling its waiter.
- Recheck Task cancellation, current dispatch generation, actual post permission
  and Secure Input immediately before activation. Profile/pause/edit/record/stop,
  sleep/locked/inactive session cancel through the existing mailbox lifecycle.
  A failure reports a localized error without pausing all rules or replaying
  consumed input. No synthetic Command-Tab, private API or dependency.
- Schema 21 retains schemas 1–20/profiles/actions/selection without rewriting on
  load. New action payloads are refused in earlier schemas, including inactive
  profiles. Three new EN/RU/DE/FR catalog keys use existing generated symbols.

## Research

Apple public notifications/activation, WWDC23 cooperative activation and actual
SDK 27 headers; pinned MIT AppRuntimeKit activation/events/manifest/license,
GitHub metadata/README/license for DockDoor and AltTab; Swift Package Index
NSWorkspace search. For the background correction, rechecked public AX and
pinned MIT AXSwift (source/full license/manifest/maintenance/SPI); its generic
wrapper adds no capability beyond the existing bounded adapter. See PLAN for revisions, limits
and decisions. No upstream implementation copied, installed or executed.

## Software verification

29 Swift Testing functions cover two-handle history/duplicate observations,
toggle, late observation, Rebind exclusion, absent/exited/ineligible targets,
selection focus/exit races, final cancellation, rejected request without optimistic
history/retry, all trigger families/exact modifiers/source release/synthetic skip,
worker → bounded MainActor routing, native accepted/cancelled/rejected handling,
eight lifecycle/protected final-gate changes, stale profile errors, localized UI
failure/label, old-schema inactive-profile rejection and isolated atomic store
migration with byte preservation until explicit save.
Four functions exercise the actual NotificationCenter/selector bridge, including
multiple activation payloads before the cached foreground advances, malformed and
ineligible events, stop/restart and reentrant native callbacks. The old observer
selects the wrong intermediate application in the burst regression.
Nine additional functions cover off-main activation policy, actual focus
acknowledgement instead of mere request acceptance, unsupported/permission/focus
guards, actor revalidation and final cancellation, delayed focus, rejected writes,
post-acceptance cancellation and Workspace ordering across awaits/profile changes.

Initial full test run found an existing recorder-lifecycle test depending on live
CGSession state. It now injects a known unlocked session, retaining production
protection. Final commands/results are recorded in [the historical software-check register](../history/implementation-through-2026-10-10.md#historical-software-check-register). Software
fakes prove dispatch/state behavior, not real native application activation.

## Detailed manual checks — remaining

1. Restart Debug Rebind, add Previous Application to a G603 side button in a test
   profile. Open Finder and TextEdit, activate Finder then TextEdit manually.
   Press the side button twice, waiting for each actual activation: TextEdit →
   Finder → TextEdit. Check keyboard focus as well as visible windows.
   Repeat the reported Messages ↔ Finder case with Rebind's window in the
   background/closed and its menu-bar presence active. Rebind must not flash into
   the foreground between apps. Record any localized failure shown by Rebind.
2. Visit a third app: subsequent action returns to the preceding observed app,
   not a fixed app, launch order or the global Command-Tab stack. Repeated same-app
   notifications should not lose the previous app.
3. Activate Rebind between two external apps. Its window should not become the
   target during external-app toggles; from Rebind the action returns to the last
   external app. Native menu-bar interactions must not corrupt history.
4. Quit the previous app, then trigger: localized failure, no relaunch/older-app
   fallback and normal unrelated input continues. Relaunch/same-ID copies must
   follow only newly observed live handles, never a stale PID.
5. Repeat with a hidden app, minimized windows, fullscreen and other Spaces or
   displays. Record actual macOS behavior; restoring/opening a window is not promised.
6. Repeat/hold triggers and alternate action types; one slot remains bounded,
   no synthetic-key/modifier changes, recursion, unintended launch or stuck input.
7. Pause/change profile, edit/record, permission loss, Secure Input/password context,
   sleep/wake/lock/inactive session and stop: no late activation from an old request.
   Test input passthrough/release and recovery separately.
8. Save/restart/profile-copy persistence, error presentation, EN/RU/DE/FR long text,
   keyboard selection/VoiceOver, light/dark/contrast/motion settings. Record timing,
   apps, triggers and OS/device. macOS 26 and Intel runtime checks remain open.

Next: remaining Phase 4 output/availability gaps need an independent research and
hardware gate; Phase 5 multitouch remains unimplemented. Do not mark either phase
complete from this slice.
