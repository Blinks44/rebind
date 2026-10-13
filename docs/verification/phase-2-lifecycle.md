# Phase 2 capture lifecycle — 2026-10-08

Scope: SPEC §§2, 6, 9; capture loss, protected input and workspace suspension.
Status: implemented and software-tested; **basic Pause/Resume and sleep/wake recovery user-verified; remaining lifecycle checks pending**.

## Contract

- Permission loss, Secure Input, workspace suspension, stop, tap creation failure,
  interruption and output failure clear queued actions and pending recognition,
  including held-source/pointer capture ownership. No stale output is replayed.
  This is different from ordinary Pause, which keeps ownership of already consumed
  releases while cancelling recognition; see the earlier activation walkthroughs.
- A recorder active at capture loss receives cancellation for its exact request.
  The UI consumes this result on its existing refresh timer; it need not wait for
  an input callback that may never arrive. A previously completed recording result
  is preserved. No typed text is captured.
- Tap interruption/output failure disables rules and requests the existing persisted
  emergency pause. Explicit Resume/Record advances the retry generation; there is
  no retry loop inside a callback. Missing permissions retain the user's enabled
  preference; after actual permission restoration the worker may create a fresh tap.
  A latched fault keeps its error status during/after Secure Input until explicit retry.
- Worker checks `CFMachPortIsValid` and `CGEvent.tapIsEnabled` on its owning thread
  before dispatch. Invalid/disabled tap clears acquisition and pauses even when no
  disabled callback arrives. No new observer/thread/helper; real API behavior and
  detection latency are pending physical verification.
- Sleep and inactive workspace session are independent reasons to suspend. Both
  must recover before acquisition can resume, regardless of notification order.
  Duplicate/unrelated notifications do not remove the remaining reason. Suspension
  cancels UI recording and clears acquisition; wake does not replay prior holds.
- NSWorkspace session notifications are not advertised as a general screen-lock
  detector. Secure Input remains a separate native check; protected contexts and
  notification ordering on actual machines need testing. Device disconnect is not
  detected by HID yet; the pointer gesture's five-second bound remains its fallback.
- No project/security/deployment/schema/permission changes. Termination clears
  recording/output/acquisition; mailbox stop is terminal, not a reusable worker restart.
  No callback UI, tasks, actor hops, logging, file I/O or synthetic posting.

## Software evidence

- `apps/rebind/scripts/dev.sh doctor`: Xcode 27.0 (27A266a), Swift 6.4, SDK 27.0,
  Apple Silicon macOS 27.0.1 (26A434); deployment remains macOS 26.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/Phase2LifecycleTests-Final.xcresult`:
  **143 tests / 22 suites / 0 failures**, 12 added functions in CaptureLifecycleTests
  and AppModelLifecycleTests. Covers permission loss, old-hold cancellation/fresh
  rearming, explicit retry after failure, pointer capture/output failure, secure
  cancellation across all input/poll entry paths, stop, recording cancellation,
  overlapping sleep/session recovery in both orders and duplicate notifications.
  UI refresh consumes capture-loss cancellation without another input event; that
  test reads actual permission state without requesting or changing access.
  All prior 131 tests retained. Parameterized cases are included in these counts.
- Tests never install a tap/post input, change permissions, sleep the Mac, run real
  NSWorkspace notifications, or touch user storage. They exercise the actual handlers
  and mailbox policy; they do not prove hardware/OS delivery, suppression or recovery.
- Final `apps/rebind/scripts/dev.sh build` and `apps/rebind/scripts/dev.sh release`: **BUILD SUCCEEDED**.
  Release contains arm64/x86_64, strict/deep signature verification and packaged
  privacy-manifest lint pass. No Intel/macOS 26 execution claim.
  Existing expected AppIntents metadata-skip and hosted autoShortcut service messages;
  no Swift/concurrency warning observed.

Logs: `/tmp/rebind-lifecycle-doctor.log`, `/tmp/rebind-lifecycle-{tests,build,release}-final.log`;
result `build/Phase2LifecycleTests-Final.xcresult` (ignored).

## User-reported hardware result — 2026-10-08

Manual test report, 2026-10-08: ordinary/hold/leftward-gesture bindings
continued working after Pause/Resume and sleep/wake on the rebuilt app.
Evidence source: tester report, not agent-observed input, on the previously identified
G603 LIGHTSPEED with G HUB and macOS 27.0.1 (26A434). No separate held-source
cancellation, timing, permission revocation, protected/session contexts, tap/output
faults or disconnect results were reported. Full lifecycle verification remains open.

## Physical checks (basic recovery confirmed; remaining checks pending)

Use one rebuilt Xcode copy with actual permissions, G603 LIGHTSPEED/G HUB and a
disposable TextEdit document. Preserve the working Control + Button 4, Button 5
long press and Option + Button 4 + Left rules.

1. Check ordinary/hold/gesture rules before and after Pause/Resume, background focus
   and closing/reopening the window. No stale actions or stuck input; unmatched input
   remains normal. Recheck releases when pausing during a held source.
2. Sleep/wake the Mac without holding input; verify current permissions/status and
   fresh rules work. Then check cancellation of an incomplete hold/gesture across
   sleep, without treating a previously held source as a new action after wake.
3. Check session switching/lock/unlock and Secure Input separately, never recording
   or reporting password text. Verify availability/status and safe fresh recovery.
4. While recording, revoke Rebind's actual Accessibility access in System Settings.
   Expect recording cancellation and permission guidance. Restore access for the
   same running copy; expect fresh acquisition only, no earlier action replay.
5. Tap interruption/invalid-port and output failure need controlled manual/debugger
   checks on Rebind's own tap; do not disable other utilities or change machine
   security. Verify visible interruption/pause, discarded queued input and explicit
   Resume. No such fault was induced in this session.
6. Device disconnect/reconnect, high polling-rate load and missed releases remain
   separate safety checks. Do not claim source attribution or full lock coverage.
