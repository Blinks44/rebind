# Phase 4 — Lock Screen (Experimental)

Scope: SPEC §5 Spaces and system / A1/A2, §§2, 6–7, 9–12.
Implemented and software-tested; **requested happy path user-confirmed on 2026-10-09**.
The user reports the requested mouse-triggered lock → ordinary macOS unlock →
existing-bindings check works. Previously reported G603 LIGHTSPEED/G HUB setup
retained; exact trigger, OS and individual cases not restated. Detailed checks remain open.
The agent only checked symbol presence and unlocked-session boolean metadata.
The agent did not perform a lock request, password entry, permission grant or user-settings change.

## Contract

- System → Lock Screen (Experimental), parameterless, shared by supported input
  categories/activation modes. No recorded shortcut, sleep operation or app launch.
- Dynamically load Apple's private `login.framework` / `SACLockScreenImmediate`
  behind `ScreenLockExecutor`. Restrict the adapter to macOS major versions 26/27
  and disable it if loading/resolution fails. This is a research boundary, not
  evidence of hardware compatibility on both versions or architectures.
- Cached availability participates in catalog disabling and compiled-rule
  filtering: unavailable saved rules pass through. It is independent of audio
  device availability. Localized experimental title, hint and errors in EN/RU/DE/FR.
- Serial worker only, outside the tap, UI and mailbox lock. Recheck generation,
  posting permission, Secure Input and native console/unlocked state before the
  private function. Once invoked it cannot be recalled or timed out in process.
- The void function returns no success/failure status. `.performed` only means
  that the entry point was invoked and returned, **not proof of screen locking**.
  No keyboard/AppleScript/shell/screensaver/display-sleep/login-window fallback,
  retries, root/helper, password storage or automatic unlocking.
- After a returned request, invalidate accumulated work and temporal recognition,
  clear mouse diagnostics, and retain suppressed press ownership until release.
  The same queue transition is shared with accepted public system-sleep requests.
  A stale return cannot clear a newer profile's work. Fresh input can arrive while
  macOS transitions; this utility is not a security boundary or lock guarantee.
- `ScreenLockSession` isolates the undocumented lock dictionary key and lock/unlock
  notification names. The public `CGSessionCopyCurrentDictionary` API supplies a
  short-lived dictionary; read only boolean console/lock state, never retain,
  display or log it, user identifiers, passwords or typed text.
- On a lock notification suspend immediately. On an unlock hint recheck native
  state instead of trusting distributed notification contents. Poll native state
  on the existing MainActor permission/lifecycle refresh (0.5 s nominal fallback)
  and before starting workers; notifications may be delayed/dropped and a busy
  main run loop can delay polling. No session query/dynamic loading in the tap.
- Missing dictionary, non-console or malformed boolean metadata suspends capture
  and clears recording, pending actions and diagnostics. An absent lock key in a
  known console session means unlocked, matching the reference and the local
  unlocked probe; private metadata can change with macOS updates.
- Sleep, inactive user session and screen lock are independent suspension reasons.
  Waking/unlocking alone must not override another reason. Retain saved enabled
  preference; capture resumes through the normal tap/permission checks.
- Schema 19 reads 1–18, retaining all profiles/selection/old actions and file bytes
  until a successful explicit save. Older schemas reject lock payloads even in
  inactive profiles. No changes to target/bundle/minimum OS, TCC or power settings.

## Research / software evidence — 2026-10-09

- Apple documents [Control-Command-Q](https://support.apple.com/en-us/102650),
  [CGSessionCopyCurrentDictionary](https://developer.apple.com/documentation/coregraphics/cgsessioncopycurrentdictionary()),
  [session inactivity](https://developer.apple.com/documentation/appkit/nsworkspace/sessiondidresignactivenotification)
  and [distributed notification delivery](https://developer.apple.com/documentation/foundation/distributednotificationcenter?language=objc).
  Installed SDK 27 `CGSession.h` confirms nullable GUI-session dictionary and public
  console key. No documented local direct screen-lock API was identified. The
  shortcut can depend on customization; MDM Device Lock is unrelated to this utility.
- [Hammerspoon](https://github.com/Hammerspoon/hammerspoon/blob/23e387e2805a9890066366e0ac96c71b27f0cfd5/extensions/caffeinate/libcaffeinate.m),
  [macos-lock](https://github.com/sindresorhus/macos-lock/blob/de0756db39f3035b373a37420764fd1299dccee6/lock.c)
  and [MacLock](https://github.com/yumaitau/MacLock/blob/4828f92c82949817f9d1389e18e56c7569e13781/MacLock/ScreenLocker.swift)
  use the void lock entry point; MacLock also observes lock notifications/key.
  All full MIT licenses read; no external executable/package/source copied.
  Maintenance/compatibility decisions are recorded in [the historical evidence summary](../history/implementation-through-2026-10-10.md).
- Safe `/tmp/rebind-lock-probe.swift` on Apple Silicon macOS 27.0.1 (26A434):
  framework opens, symbol resolves, unlocked lock key absent, console Boolean true.
  Probe closes its handle and never invokes the function; no locked-state evidence.
- 17 new Swift Testing functions cover invocation/cancellation/missing entry point,
  availability passthrough, exact modifiers/synthetic exclusion, worker routing,
  queue/diagnostic clearing, stale revisions, migration/atomic storage, boolean
  parsing, recording suspension and overlapping lifecycle conditions. Native
  requests are injected; the full suite passes 371 tests in 50 suites.
- Debug and universal Release build checks are recorded in [the historical evidence summary](../history/implementation-through-2026-10-10.md). Compilation,
  symbol presence and mocked state transitions do not prove actual screen locking.

## Manual checks — happy path reported; detailed cases remain open

1. Save work, quit/restart the rebuilt authorized Rebind copy. In a test profile,
   assign a spare G603 side button/hold to System → Lock Screen (Experimental).
   Invoke once: verify the actual macOS lock screen, without sleeping or quitting
   the front app. Record exact trigger, OS/build and expected/observed behavior.
2. Unlock normally through macOS. Verify ordinary bindings and repeated lock/unlock,
   including Rebind's main window closed/background/minimized and a paused profile.
   Confirm configured enabled state/profile survive; no stuck source/modifier.
3. Keep the source held, release during lock and test rapid actions around the
   transition: no queued media/window/shortcut effect after unlock. Check hold,
   double press, wheel and pointer gesture regressions in safe applications.
4. Start ordinary mouse diagnostics and explicit recording, lock via macOS itself,
   then unlock: both stop/clear and never restart automatically. Verify capture
   stays suspended on the lock screen; do not record, print or export credentials.
5. Check lock + sleep/wake and inactive-user-session overlap; unlocking/waking alone
   must not resume another inactive condition. Test missed/delayed notifications,
   unavailable session metadata, revoked access, Secure Input and cancelled work.
6. Measure request/poll latency; check failure to lock despite function return,
   macOS 26/Intel compatibility and all four locale layouts/VoiceOver. A missing
   entry point or future unreviewed OS must disable the rule and pass input through.

Next implementation slice: remaining Phase 4 window/application switching or
brightness feasibility after focused native/library research. Phase 4 remains open.
