# Phase 4: Cycle windows of the active application

Scope: SPEC §5 Windows and applications / A1/A2, §§2, 6–7, 9–12.
Implemented and software-tested; **requested happy path user-confirmed (2026-10-09)**.
The user reports everything works after the three-window forward/reverse/focus
check request. Exact apps, triggers, window count and individual cases were not
restated; detailed checks below remain open.
No live window was raised, modified or read by the agent for this slice.

## Contract

- Shared Windows and Applications catalog: Next Window of Current App / Previous
  Window of Current App. No parameters or keyboard shortcut; use existing triggers.
  This slice cycles windows within one application; application switching is separate.
- Public AX focused-application/focused-window/windows/role/subrole/minimized/modal
  reads, writable `AXMain`, supported `AXRaise`, and immediate focused-window
  readback. Reuse the serial native AX client and its 450 ms total request budget
  with per-call timeout up to 150 ms. No synchronous tap/UI AX work.
- Only ordinary, non-minimized, non-modal windows whose PID matches the focused
  application participate. Do not target Rebind itself. Unknown state is excluded;
  an unsupported/missing focused window, permission, main property, raise operation
  or focus readback returns a localized error. No fallback, retry, dialog dismissal,
  launching, restoration of minimized windows, fullscreen/tile mutation or scripts.
- Read at most 32 app-reported windows; reject empty/duplicate/oversized eligible
  lists or a focused window outside the list. One eligible window is a successful
  no-op. This is a small safety/performance boundary, not an OS-wide window catalog.
- First successful operation captures the eligible AX list order; subsequent
  forward/reverse actions wrap around that stable order despite front-to-back
  reordering after raising. A changed eligible set, application or configuration
  generation starts a new order. Manual focus movement changes the current index.
  Not an exact imitation of the system Command-` order, tab navigation or MRU UI.
- The bounded cache holds only AX elements for the last cycled application on the
  action worker; no titles, document paths/content, persistent window IDs, global
  history or observers. Refresh handles from each enumeration; commit order only
  after successful native focus. Revision changes release the cache on service;
  thread exit releases it normally. No `@unchecked Sendable` or cross-actor handles.
- Recheck action generation, permission/Secure Input and app/window identity before
  each mutation. `AXMain` alone does not imply key focus: raise then read actual
  focus. Cancellation/rejection after the first write may leave a partial change;
  do not roll back against changed focus or retry another window. Already accepted
  system effects cannot be recalled. Busy apps/readback delays may report failure.
- The app's AX list can include other Spaces/fullscreen windows. macOS owns any
  Space transition; this slice neither moves windows between Spaces nor promises
  current-Space-only filtering/native cycle ordering. No private AX→CG window-ID
  mapping or title/geometry matching, and no Screen Recording permission.
- Schema 20 reads 1–19, retains all profiles/selection/actions/file bytes until an
  explicit successful save; reject cycle payloads in older/inactive profiles.
  EN/RU/DE/FR localized labels/hint/failure, unchanged bundle/target/minimum OS.

## Research and software evidence: 2026-10-09

- [Apple AXMain](https://developer.apple.com/documentation/applicationservices/kaxmainattribute),
  [AXRaise](https://developer.apple.com/documentation/applicationservices/kaxraiseaction),
  [AX client APIs](https://developer.apple.com/documentation/applicationservices/axuielement_h)
  and [messaging timeouts](https://developer.apple.com/documentation/applicationservices/1459345-axuielementsetmessagingtimeout).
  SDK 27 headers confirm public writable Main, non-guaranteed key focus, mandatory
  modal Boolean, window enumeration/count/actions and synchronous timeout APIs.
  Some DocC pages supplied only a JS shell; installed headers are the declaration
  evidence, not actual target-app behavior.
- Pinned [WindowKit](https://github.com/naviapps/window-kit/tree/0afbb8e561ecd5ca19ec5168b44a4cf332236b4b)
  controller/manifest/full MIT license reviewed again; tools 6.0/macOS 14/no packages.
  MainActor live AX architecture/broad discovery unnecessary for two serial actions.
  Its [SPI listing](https://swiftpackageindex.com/naviapps/window-kit) is accessible;
  badges are not local Swift 6/hardware proof.
- Pinned [Swindler](https://github.com/tmandry/Swindler/tree/bf2c42f1db8bb1aa6c0b634d9fca3ab4bd37931d)
  full MIT license/manifest now retrieved: tools 5.1/macOS 10.12, AXSwift/PromiseKit
  plus Quick/Nimble tests, latest commit 2022-09-06, not archived. Its broad cached
  model/dependencies are unnecessary; no package/source/build adoption. SPI fetch
  failed, so no current compatibility claim.
- [Hammerspoon's native window methods](https://github.com/Hammerspoon/hammerspoon/blob/23e387e2805a9890066366e0ac96c71b27f0cfd5/Hammerspoon/HSuicore.m)
  confirm separate public Main/raise operations. Its private window-ID mapping and
  all-app observer architecture are not adopted. Full MIT license read, latest
  pinned commit 2026-07-08, not archived; no source copied or Lua dependency.
- 20 new Swift Testing functions cover three-window forward/reverse wrap despite
  reordered AX lists, no-op/invalid/bounded lists, focus/permission/cancellation
  changes, partial/rejected operations/readback, eligibility, typed dispatch,
  source ownership/synthetic exclusion, stale errors and migration/atomic storage.
  Native windows are injected. Full suite: **391 tests in 54 suites pass**.
- Debug/universal Release checks and toolchain/commands are recorded in [the historical evidence summary](../history/implementation-through-2026-10-10.md).
  Real applications, Spaces/fullscreen/sheets, latency, locales and access changes
  still require manual checks.

## Manual checks: all open

1. Restart the authorized rebuilt Rebind. In a test profile map two spare mouse
   buttons (or different modifiers) to Next/Previous Window of Current App.
   Open three separate Finder or TextEdit windows (not three tabs), focus one and
   verify three forward actions traverse all three and return to the first;
   reverse traverses them oppositely. Type only harmless sample text to confirm
   keyboard focus follows the visible window. Record app/trigger/OS/build.
2. Repeat in another app. Manually focus a different window, then cycle. Open/close
   a window, minimize another, restore normally and verify membership/reset.
   With one eligible window the action should do nothing without an error.
3. Test unsupported/modal windows and attached save sheets: no dialog accepted or
   dismissed, no other application targeted. Verify cancellation/pause/profile
   switch/recording/access loss and ordinary mouse/shortcut mappings remain safe.
4. Check hold/double press, wheel and four-direction pointer triggers, rapid
   repeated actions, main-window-closed background operation and sleep/lock recovery.
5. Check other Spaces, fullscreen/Stage Manager/multiple displays and busy apps.
   Record allowed transitions and latency; no claim of exact Command-` behavior.
   Test macOS 26/Intel and all four locale layouts/VoiceOver separately.

Next: native application-switching slice after API/library research; brightness
and remaining Phase 4/touch/lifecycle hardware gates remain open.
