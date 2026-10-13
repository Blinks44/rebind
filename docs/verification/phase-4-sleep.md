# Phase 4: Put Mac to Sleep

Scope: SPEC §5 Spaces and system / A1/A2, §§2, 6–7, 9–12.
Implemented and software-tested; **requested happy path user-confirmed on 2026-10-09**.
The user reports the requested sleep → wake → existing-bindings check works on the
previously described G603 LIGHTSPEED/G HUB setup. Exact trigger, OS, individual
cases and source-release behavior were not restated; detailed checks below remain open.
The agent did not request sleep, change power settings or run a global input engine.

## Contract

- Shared System catalog offers Put Mac to Sleep without an output shortcut or
  parameters, usable by the existing supported triggers/activation modes.
- Public IOKit `IOPMSleepEnabled`, `IOPMFindPowerManagement`, `IOPMSleepSystem` and
  `IOServiceClose`. Check full-sleep support, initial cancellation and a nonzero
  connection; check current dispatch/Secure Input/post permission again after opening
  and immediately before requesting sleep. Close the connection on accepted/rejected
  request and cancellation. No retries, scripts, simulated power key, root/helper
  fallback, power assertion changes or private API. Native calls run on the serial
  action worker, never on UI/event-tap threads or while holding a mailbox lock.
- Apple documents console-user (or root) authorization; Rebind operates as the
  ordinary user. A rejected connection/request or unavailable full sleep gets a
  translated error without pausing unrelated rules or replaying the consumed input.
  The catalog disables the action when the public full-sleep capability is false;
  runtime support/access is checked again. This does not detect all sleep blockers.
- Successful IOReturn means request accepted, not physical sleep completion. macOS
  controls timing, blockers and wake behavior. The synchronous API offers no
  cancellation of an accepted request or per-call timeout; latency remains a manual
  gate. New hardware input, including source release, may immediately wake the Mac.
  Password/lock behavior follows existing system settings; this is not Lock Screen.
- Acceptance drops already queued actions and pending double/hold/pointer recognition
  for that generation, increments cancellation revision, and retains suppressed press
  ownership until release. A newer configuration's queue is not cleared by an old
  completion. Enabled state/status are not fabricated from API success: the existing
  workspace sleep/session notifications suspend/reset capture, and waking/session
  activation govern recovery. Accepted effects cannot be recalled.
- This is a one-shot request, not a power schedule or a persistent sleep controller.
  Fresh input arriving before the OS sleep notification can still be recognized;
  no artificial global input block or forced sleep loop is added.
- Schema 18 reads 1–17 without rewriting until successful user edit, retaining prior
  profiles/selection/pause/rules/actions/modifiers/activation. Sleep payloads in old
  schemas, including inactive profiles, are rejected. Titles/help/errors translated
  into EN/RU/DE/FR.

## Software evidence: 2026-10-09

12 new Swift Testing functions in SystemSleepTests. Full
**354 tests / 48 suites / 0 failures** in `build/SystemSleep-Final2.xcresult`.
Injected IOKit operations verify nonzero port ownership/close, accepted/denied/error
results, initial/post-open cancellation and unavailable support/connection. Matcher,
worker and temporary store tests cover exact modifiers/input families/synthetic
feedback, routing without output keys/audio, non-pausing errors, accepted queue reset,
new-generation preservation, delayed hold cancellation with balanced suppressed
release, final lifecycle/protected gates and schema-17 byte retention until save.
No actual IOPMSleepSystem call, global capture or user-store writes in tests.

Initial compilation caught a mailbox method inserted into nested State; moved it to
EngineMailbox. An initial test put a hold before another button down, which already
cancels holds under existing matcher policy; fixed event order to create a pending
hold after sleep was queued, then full suite passed. No matcher policy changed.

A safe native probe calls only support query and connection open/close: all return
success on the development Apple Silicon macOS 27.0.1 host. This does not prove sleep
request acceptance or wake recovery. Build/toolchain/signature/research evidence in
[the historical evidence summary](../history/implementation-through-2026-10-10.md); hardware latency, blockers, macOS 26/Intel remain open.

## Manual check

1. Restart one rebuilt authorized Rebind. Save current work, then in a test profile
   map a spare mouse button to System → Put Mac to Sleep. Invoke once and release
   the button. Expect the normal macOS sleep request, not a simulated shortcut.
   Record OS/device/trigger used and whether release causes an immediate wake.
2. Wake normally. Existing mappings, unmatched input and profile selection should
   work; no queued old click/media/Quit action or repeated sleep should occur merely
   from waking. Check sleep/wake twice, then an ordinary mouse/keyboard binding.
3. Try a deliberate hold activation to avoid incidental short presses; test wheel/
   pointer gestures separately if desired. New physical input may wake the Mac;
   Rebind does not promise it can prevent that. Compare manually choosing Apple-menu
   Sleep if the machine refuses/remains awake, without changing power assertions.
4. Check pause/edit/profile/record and permission/protected-session gates before
   queued output; no late sleep from an invalidated request. Already accepted sleep
   cannot be recalled. Other locale layouts/accessibility, rapid inputs, measured
   latency, full-sleep-unavailable/rejected access, multiple sessions and macOS 26/
   Intel remain manual gates. Passing software tests is not hardware sleep proof.
