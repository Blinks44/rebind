# FIX-005: Built-in trackpad gestures stop after a long sleep

- Updated: 2026-10-30
- Stage: awaiting_verification
- Owner: Claude Code implementation
- Owned surfaces: `NativeTrackpadDevice` acquisition, `TrackpadCapture` surface scan, build number and affected records. No visual/copy/schema change.
- Requirements: SPEC touch capture/recovery contracts; built-in and Magic Trackpad remain separate categories
- Code baseline: `2f3d775`, source 1.3.0 (36), schema 49

## Report and cause

The tester closed the lid for about two hours with 1.3.0 (36) running. After wake, built-in trackpad gesture rules no longer fired; keyboard remapping kept working. No Magic Trackpad was attached.

Live inspection before the fix: `pmset -g log` showed a `Wake from Deep Idle` after the Rebind process started. The current built-in `AppleMultitouchDevice` had a newer registry entry than the process and only WindowServer's `AppleMultitouchDeviceUserClient`; Rebind had no client on it. The system had replaced the built-in multitouch driver during sleep, while Rebind kept the adapter created once from `MTDeviceCreateDefault` and only stopped/started that stale device on wake. External surfaces were already rescanned every two seconds and re-acquired by registry entry ID, so a Magic Trackpad most likely recovered; this is not hardware-verified.

## Fix

All three surface kinds now use one acquisition path: `MTDeviceCreateList`, filtered by `MTDeviceIsBuiltIn`, identified by registry entry ID. `TrackpadCapture` scans the built-in surface at the same two-second cadence as the Magic Trackpad while capture is active. A replaced connection retires the old adapter (never freed, per the callback-quiescence rule) and restarts capture on the new one. `MTDeviceCreateDefault`/`MTDeviceRelease` are no longer loaded. Event-tap callbacks are unchanged.

## Evidence

- Build **1.3.0 (37)**, Debug/Release equal, schema 49 unchanged.
- `dev.sh test`: 971 Swift Testing tests / 149 suites pass, `Test-rebind-2026.10.30_19-47-25-+0300.xcresult`. Existing connection tests cover registry-ID identity; the private-framework replacement itself is not unit-testable.
- `release.sh` passed for local 1.3.0 (37); the tester installed it and reports gestures working so far (2026-10-30). Published as 1.3.1 (38), same code ([REL-009](REL-009-release-1.3.1.md)).

## Remaining acceptance / next

- [ ] Installed build 37 or later: built-in gesture rules work after a lid-closed sleep long enough for deep idle (about two hours), without relaunch. `ioreg -r -c AppleMultitouchDevice -l | grep IOUserClientCreator` lists Rebind on the current built-in device.
- [ ] Same check with a Magic Trackpad attached when one is available.
