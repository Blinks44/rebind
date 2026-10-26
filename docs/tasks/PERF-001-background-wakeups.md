# PERF-001: Fewer background wakeups and per-frame checks

- Updated: 2026-10-26
- Stage: awaiting_verification
- Owner: Unassigned; implementation/packaging complete, targeted runtime verification remains
- Ownership checked: 2026-10-26 on clean `main` at `3a157e6`
- Owned surfaces: companion monitor and MouseHardware inventory/AppModel wiring; SmoothScroller, EngineMailbox/EventTapWorker, ActionWorker/CoreAudioOutput; affected device/action/engine tests, build number and project records
- Requirements: ENGINEERING callback/actor rules; PLAN release gate "measured callback/action latency"; continues [REVIEW-002](REVIEW-002-idle-energy.md)
- Code baseline: `main` at `3a157e6`; installed baseline 1.0.0 (16)

## Outcome and scope

The user reports Rebind periodically uses noticeably more CPU. A `sample` of the installed 1.0.0 (15) on 2026-10-24 (macOS 27.0.1, real grants and rules, user typing; `top` 3.1 %, physical footprint ~74 MB, `ps` 1.4–20 %) shows the threads mostly idle, with these steady costs:

1. `CompanionAppMonitor` scans every process with `proc_pidpath` every 2 s on the main thread (~54 ms per 8 s sample). Scan only while a Logitech device is connected, and less often; `NSWorkspace` KVO already reports ordinary apps.
2. `SmoothScroller` calls `IsSecureEventInputEnabled()` and `CGPreflightPostEventAccess()` (a TCC check) on every ~120 Hz glide frame. Check TCC once when a glide starts; retain the inexpensive per-frame Secure Input guard so protection can begin mid-glide.
3. `ActionWorker` wakes every second to read Core Audio capabilities. Use a default-output-device property listener and keep a slow fallback only if needed.

Not in scope (user decision 2026-10-24): replacing the 100 ms `AppModel` refresh timer with engine-pushed updates (touches permissions, tap recovery and UI state); revisit only if measurements after 1–3 show it matters. Pointer-app timer churn is too small to matter.

## Acceptance

- [ ] Before/after measurement on the same Mac with real grants and normal rules: one idle minute, one scrolling minute with smooth scrolling, one typing minute; record `top` CPU/idle wakeups and sample duration with the named builds.
- [ ] No behavior change: companion banner/DPI ownership, Secure Input stopping a glide, permission loss stopping posting, audio device switch updating volume/mute availability.
- [x] Behavioral tests for the changed decisions; full `dev.sh test`; build bump and `release.sh` package.

## Implementation — 2026-10-26

- Companion monitoring receives the HID vendor inventory before discovery queues device probes/writes. Full process scans run only with a supported vendor connected, every 10 s (2 s timer tolerance), plus immediate inventory/Launch Services changes. Disconnect clears the irrelevant companion state. Launchd-only helper discovery can therefore take up to the timer cadence/tolerance; ordinary app launches and hardware attachment still refresh immediately.
- A glide caches event-posting authorization until its dispatch/generation changes. Secure Input and mailbox currentness remain checked every frame. Permission loss invalidates the glide through the existing tap's permission checks (up to its 0.5 s cadence); the OS also enforces posting authorization. Protected frames never use the cached TCC result to bypass Secure Input.
- Native Core Audio default-output/device-list listeners invalidate a coalesced mailbox flag and signal the existing serial action thread. Registration precedes its initial capability read; listeners are removed with the same block on shutdown. A 60 s fallback covers registration failures or driver-property changes without these notifications. Failed audio actions still refresh immediately. The one-second idle wake is removed; held repeats keep their own deadlines. Tap detection of Secure Input explicitly wakes owned modifier/key releases.
- The 100 ms UI refresh, tap permission cadence and pointer-app tracker are unchanged. No dependency, configuration schema, user rules or permission changes.

## Research

Apple's [runningApplications documentation](https://developer.apple.com/documentation/appkit/nsworkspace/runningapplications) confirms KVO support and recommends notifications over polling. Launchd helpers still need the existing bounded process scan; no public ordinary-app notification replaces that requirement. Apple's [Core Audio listener API](https://developer.apple.com/documentation/coreaudio/audioobjectaddpropertylistenerblock(_:_:_:_:)) and installed SDK headers document synchronous delivery with a nil queue and matching listener removal. The callback only marks a flag/signals a semaphore, with no HAL query, UI or task creation. Existing native HAL capability code is sufficient; the archived SimplyCoreAudio alternative remains unadopted (DEPENDENCIES). No third-party source copied.

## Measurement — initial installed baseline

Agent-observed 2026-10-26, installed **1.0.0 (16)**, Apple silicon, macOS 27.0.1 (26A434). Read-only Info.plist inspection confirms the build. A 60 s `top` capture (31 snapshots at 2 s, excluding the first cumulative CPU snapshot) gives **2.247 % mean CPU**, range **1.1–3.6 %**; idle-wakeup counter was 142 at the first snapshot and 144 at the last. An overlapping 8 s `sample` confirms the companion timer/KVO process scans on the main thread (including `proc_pidpath`); footprint 33.1 MB. This is uncontrolled desktop activity, not an identified idle/scrolling/typing protocol; no typed content was collected. Raw logs stay in temporary storage. Do not interpret this alone as a before/after gain or as hardware acceptance.

## Verification and package — 2026-10-26

- Debug compilation passes. Full `dev.sh test -quiet -parallel-testing-enabled NO` passes: **942 methods passed, 2 skipped**; the device/configuration summary reports **2477 passed executions, 2 skipped** (parameter cases overlap method counts). `Test-rebind-2026.10.26_10-41-18-+0300.xcresult`, zero failures/expected failures. Includes companion attach/disconnect gating, audio cache invalidation/coalescing/fallback, per-glide TCC and per-frame Secure Input, capture-loss cancellation, held-modifier wake/release and the existing wheel/ownership suites. Existing fixture/held-output QoS runtime warnings are retained; no new test failure. The first sandboxed build failed on standard Xcode/SwiftPM cache writes; host-context build succeeds. One initial test compilation failed on Swift Testing's expansion of a mutating call; the corrected test evaluates the result before asserting. The completed full run uses the corrected source.
- Both Debug and Release are **1.0.0 (17)**. `release.sh` passes Release compilation, nested/app strict/deep signatures, DMG signing, image integrity, checksums and Sparkle appcast generation with the existing signer. Artifact: `apps/rebind/build/release/Rebind.dmg`; SHA-256 **459fd7be8e6b59ab6175fc837f4048be17b327bb169138eba9baebb87364533f**. Appcast lists build 17 and the permanent asset name. This package is local/non-notarized and not published. An additional sandboxed codesign check reported trust failure; the same read-only check in host context passes, matching release.sh.
- After the interrupted session, read-only inspection found build 17 already installed and running. Its executable SHA-256 matches the packaged app. Native Permissions shows Accessibility and event posting enabled, and rules remain enabled. Connected hardware observed: MX Master 2S with smooth scrolling on, Logitech receiver and Mi Wireless Mouse; no hardware parameters were changed. This confirms grant/state preservation, not execution of all remappings. No installation, permission or rule changes were performed by this implementation session.

## Installed comparison — 2026-10-26

Same Mac/OS, same `top` method (31 snapshots at 2 s; first snapshot excluded), real grants/rules enabled. Installed build **16: 2.247 % mean CPU (1.1–3.6 %)**; installed build **17, no window interaction during the capture: 1.070 % (0.4–3.7 %)**. This is a **52.4 % lower observed average**, not a controlled performance guarantee: foreground apps, input activity and the visible Rebind page were not held identical. Build 17's idle-wakeup counter moved from 5 to a display-truncated `12+`; the earlier build-16 counter moved from 142 to 144. These cumulative counters do not demonstrate a wakeup reduction across different process lifetimes. The UI-interaction capture of build 17 averaged 3.513 % (0.4–12.9 %) and is excluded from the background comparison. A retry of the old-process baseline captured no valid process rows because build 16 had exited during the interruption; it is not evidence.

The second 8 s stack sample identifies build 17, footprint 37.7 MB, a reduced-cadence companion scan and an action thread almost entirely waiting on its semaphore. This identifies the expected code paths, not timer-frequency certification. No typed text was read/logged and the agent did not generate scrolling or execute configured remappings. Full three-mode/hardware acceptance stays open.

Source baseline is `3a157e6`; the scoped implementation, tests and verification records are committed together at the user's request. The build-17 package was produced from this source before the documentation/acceptance follow-up. No push or publication. Raw top/sample/build/test logs remain temporary; xcresult is in ignored local build output.

## Tester follow-up — 2026-10-26

After the build-17 handoff, the user reports successful checking and normal operation so far, with no problems observed. Preserve this as a general installed-build smoke pass. Duration and individual scrolling/typing, companion, audio-switch and protected-context cases were not specified; it does not certify the remaining measurement/safety matrix.

## Next handoff

Preserve the accepted general smoke pass. A tester conducts the controlled one-minute idle/scrolling/typing comparison and the affected companion, audio-switch and protected-context checks on installed build 17. Keep the task awaiting_verification until those checks have identified-artifact evidence; do not repeat the unrelated whole-app/copy pass.
