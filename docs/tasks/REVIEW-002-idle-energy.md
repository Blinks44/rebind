# REVIEW-002: Idle energy and app-wide review

- Updated: 2026-10-18
- Stage: awaiting_verification
- Owner: Unassigned; implementation session released 2026-10-18
- Requirements: ENGINEERING §5 (bounded callbacks, safe failure); user request 2026-10-18 for an app-wide bug review against how comparable apps work

## Findings

- **Idle CPU 6–8 %** (installed build, `top`, 2026-10-18). Comparable remappers (Karabiner-Elements, LinearMouse, BetterTouchTool) are event-driven and near 0 %. Causes, from `sample`: the trackpad poll ran on the main thread every 10 ms whenever trackpad rules existed, even with no finger down; the pointer-app lookup read the whole window list (`CGWindowListCopyWindowInfo`) ten times a second while a smooth-scrolling exclusion existed; the action worker and the tap thread woke every 20 ms; the 100 ms UI refresh reassigned observed properties (Observation notifies on every assignment), redrawing observers such as the Menu Bar icon.
- **Action latency**: the 20 ms worker sleep added 0–20 ms to every action and jittered held-key repeats.
- **SIGTERM** (`kill`, launchd, installers) skipped `applicationWillTerminate`: held keys and modifiers were not released and the gesture button stayed diverted.
- Not changed, recorded for later: shortcut output carries modifiers only as event flags (no separate modifier key events; a few apps that track modifier keys may ignore them); synthetic glide events carry no scroll/momentum phase (Mac Mouse Fix and MOS add phases, which changes app-specific scroll handling). Neither has a user report; both need hardware feel checks before changing.

## Changes

- `ActionWorker` waits on a mailbox semaphore: signalled when the tap queues or releases work (never for unmatched input), or until the next held-key repeat, at most 1 s idle (audio output, Secure Input and permission rechecks).
- `EventTapWorker` runs its run loop in 0.5 s slices, 10 ms only while a hold or pointer gesture is timed, returns after each handled event, and is stopped early by the mailbox when rules, recording, pause or diagnostics change, or a hold starts off the tap (gesture button).
- `TrackpadCapture` keeps the 10 ms cadence only while frames arrive plus the double-tap interval and 0.5 s; then it polls every 250 ms and the first touch frame wakes it at once (one main-queue hop per touch). Without trackpad rules it polls every 0.5 s.
- `PointerApplicationTracker` reads the window list only while the wheel turns (a dispatch source fed from the tap) and for one second after; the app in front stands in meanwhile. A pointer-app change restarts a glide only when it changes whether that glide may run.
- `AppModel.refresh` assigns observed state only on change; its timer has tolerance.
- SIGTERM is handled as a normal quit.

## Verification

- 2026-10-18: `dev.sh test`: 853 Swift Testing tests in 132 suites + 17 native tests pass, including new `IdleWakeTests` (work deadlines, wake latency, pointer-app decision, trackpad buffer wake).
- 2026-10-18, idle, same Mac, `top` 4 × 5 s: installed build 6.9–7.6 % CPU; new Debug build 1.7 % (unoptimized; remaining samples spread over the 2 s companion-app scan, the 250 ms trackpad poll and the UI refresh). A Release measurement is open.
- 2026-10-18: `kill -TERM` quits the Debug build at once; release of a held key and the gesture button on SIGTERM not observed on hardware.
- [ ] Hardware: dual-role hold timing, held-key repeat, first trackpad tap after a quiet minute, smooth-scrolling exclusion with the pointer over a background app.

Next step: user walks section 2 of the 2026-10-18 manual checklist on the Debug build; measure Release idle CPU before the next release.
