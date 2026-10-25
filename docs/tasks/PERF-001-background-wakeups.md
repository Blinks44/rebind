# PERF-001: Fewer background wakeups and per-frame checks

- Updated: 2026-10-24
- Stage: planned
- Owner: unassigned
- Ownership checked: 2026-10-24 on `main` after `f961b3b`
- Owned surfaces: `Devices/CompanionApp.swift`, `Engine/SmoothScroller.swift`, `Actions/ActionWorker.swift` / `Actions/CoreAudioOutput.swift`
- Requirements: ENGINEERING callback/actor rules; PLAN release gate "measured callback/action latency"; continues [REVIEW-002](REVIEW-002-idle-energy.md)
- Code baseline: `main` at `f961b3b`; no code changed

## Outcome and scope

The user reports Rebind periodically uses noticeably more CPU. A `sample` of the installed 1.0.0 (15) on 2026-10-24 (macOS 27.0.1, real grants and rules, user typing; `top` 3.1 %, physical footprint ~74 MB, `ps` 1.4–20 %) shows the threads mostly idle, with these steady costs:

1. `CompanionAppMonitor` scans every process with `proc_pidpath` every 2 s on the main thread (~54 ms per 8 s sample). Scan only while a Logitech device is connected, and less often; `NSWorkspace` KVO already reports ordinary apps.
2. `SmoothScroller` calls `IsSecureEventInputEnabled()` and `CGPreflightPostEventAccess()` (a TCC check) on every ~120 Hz glide frame. Check once when a glide starts.
3. `ActionWorker` wakes every second to read Core Audio capabilities. Use a default-output-device property listener and keep a slow fallback only if needed.

Not in scope (user decision 2026-10-24): replacing the 100 ms `AppModel` refresh timer with engine-pushed updates (touches permissions, tap recovery and UI state); revisit only if measurements after 1–3 show it matters. Pointer-app timer churn is too small to matter.

## Acceptance

- [ ] Before/after measurement on the same Mac with real grants and normal rules: one idle minute, one scrolling minute with smooth scrolling, one typing minute; record `top` CPU/idle wakeups and sample duration with the named builds.
- [ ] No behavior change: companion banner/DPI ownership, Secure Input stopping a glide, permission loss stopping posting, audio device switch updating volume/mute availability.
- [ ] Behavioral tests for the changed decisions; full `dev.sh test`; build bump and `release.sh` package.

## Next handoff

Code: measure the current build per the acceptance protocol, then make change 1, 2 and 3 as separate small commits, re-measuring after them.
