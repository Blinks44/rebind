# Trackpad foreground round-trip cancellation — 2026-10-12

[INPUT-001](../tasks/INPUT-001-four-finger-tap.md), SPEC §§2, 3.4, 6, 12 / T1/T2/S1. Engineering-only safety repair; no UI/Sketch change or stronger hardware-support claim.

## Defect and repair

Previously, changing the foreground PID cleared the queued touch slot but left the input-activity snapshot unchanged. An action already dequeued by the serial worker, or a recognition snapshot still waiting for admission, became current again after A → B → A. Buffered contact frames from before that transition could also qualify as a new tap after returning to A. A delayed activation notification could read the final PID A and skip mailbox invalidation entirely.

`EngineMailbox.updateTrackpadForeground` now advances the existing transient input-activity counter when the PID changes, including transitions to/from nil. An explicit `activationChanged` argument invalidates on every observed application-activation notification, even when the latest sampled PID is unchanged. Stable polling is a no-op. The counter is already captured by native frames, tap sessions and dispatch targets, so their existing guards reject obsolete input and output without a second queue, new lock, actor hop or capture mechanism. General action revision and keyboard/mouse matcher ownership remain intact.

`TrackpadCapture.poll` publishes the foreground update before reading its runtime snapshot. Initialization and session update use the same PID sample. The activation observer retains its session interruption and always invalidates the mailbox snapshot. Thresholds, click settling, single/double arbitration, output expiry, tagged balanced output, storage schema and opt-in timing diagnostics are preserved.

The repair covers transitions observed by existing polling/activation notifications. It cannot recall a balanced pair after posting starts or detect an OS transition that has not yet reached either observer. It does not establish private-framework callback timing/quiescence, same-application window-focus safety, physical reliability, suppression or minimum-OS compatibility.

## Sources and review

Reviewed installed Swift Concurrency, Swift Testing and API Design skills, current callback/worker/session code and the [existing touch audit](../research/touch-library-audit.md). Retained native AppKit observation and the existing synchronous mailbox; no dependency or third-party code added. This repairs cancellation state rather than adding a new capture/action mechanism.

The installed SDK 27 `NSWorkspace.h` confirms application activation/deactivation notification declarations and the affected-application userInfo key. An attempted refresh of [Apple's activation documentation](https://developer.apple.com/documentation/appkit/nsworkspace/didactivateapplicationnotification) returned a JavaScript-only page; no notification-ordering guarantee is inferred from it. [Swift SE-0433](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0433-mutex.md) supports retaining scoped synchronous state access; external calls and native posting remain outside locks. The notification path deliberately invalidates even if a frontmost sample already reflects the final application, rather than assuming every intermediate PID will be sampled.

Self-review checked production call ordering, snapshot propagation, no-op stable polling, unchanged action revisions, release ownership, obsolete-buffer rejection and recovery. Tests isolate each mailbox/buffer, inject clocks and capture posts. No sleeps, production input startup, real configuration, permission changes or native output occur.

## Environment and checks

Started on `main` / `e74ae71` plus pre-existing uncommitted timing diagnostics/tests and independent UI/docs/gitignore work. This repair changes `TrackpadCapture.swift`, the foreground-update method in `TrackpadRuntime.swift`, adds `TrackpadFocusCancellationTests.swift` and updates scoped records. Earlier timing changes in the same runtime file are preserved. During verification the checkout advanced externally to **`a6471db`**, containing the unchanged repaired source/tests and earlier work; final checks refer to that source revision. Completion records remain uncommitted. No agent commit.

`scripts/dev.sh doctor`: Xcode 27.0 (27A266a), Swift 6.4, SDK 27; arm64 host, macOS 27.0.1 (26A434). Target/scheme/module/bundle/minimum-OS settings preserved. Test host bypasses production input startup. Logs, JSON and xcresult bundles remain ignored under `build/`.

- Before repair: `scripts/dev.sh test -only-testing:rebindTests/TrackpadFocusCancellationTests -resultBundlePath build/TrackpadFocusBefore.xcresult` — **TEST FAILED**, four functions / seven expanded executions, all seven fail with eleven assertion issues. Reproduces old-runtime readmission, dequeued-action revival, posting during a focus round trip and buffered pre-switch stroke qualification for both finger counts.
- Final scoped run: `scripts/dev.sh test -only-testing:rebindTests/TrackpadFocusCancellationTests -only-testing:rebindTests/TrackpadIntegrationTests -only-testing:rebindTests/TrackpadDoubleTapTests -only-testing:rebindTests/TrackpadSingleTapTests -only-testing:rebindTests/TrackpadSchedulingTests -only-testing:rebindTests/TrackpadShortcutSenderTests -only-testing:rebindTests/ProfileSwitchTests -only-testing:rebindTests/EngineMailboxTests -resultBundlePath build/TrackpadFocusScoped.xcresult` — **TEST SUCCEEDED**, 89 functions / 283 expanded executions, zero failures/skips, checked against xcresult. Seven new functions / ten executions cover the defect, nil targets, fresh recovery, unchanged-PID activation, stable polling, and preserved keyboard dispatch/down-up ownership. Existing single/double, scheduling, sender and profile checks pass.

- Final full run: `scripts/dev.sh test -resultBundlePath build/TrackpadFocusFull.xcresult` — **TEST SUCCEEDED**, **666 unique functions / 1,870 expanded executions / zero failures/skips**. Swift Testing console: 652 functions / 90 suites; XCTest: 14 functions. Legacy xcresult root/test-tree inspection confirms all 1,870 metadata entries are Success, including all ten new focus-cancellation executions. No error/warning/test-warning summaries. Existing console messages about the aggregate 101-window fixture count and Apple Shortcuts service connections remain; this is not a production leak/performance result.
- `scripts/dev.sh build > build/TrackpadFocusBuild.log 2>&1` — **BUILD SUCCEEDED**, ordinary Debug bundle after removal of test-host embedding. `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` — passes local signing verification; distribution acceptance remains separate.
- Final source/diff/link review and `git diff --check` — pass. The bounded software repair is complete; physical acceptance remains open.

Final ordinary Debug artifact: `build/DerivedData/Build/Products/Debug/Rebind.app`, source **`a6471db`**. Executable SHA-256: `f3d91911df89c7fdc12b23eb5bf0286555a9f12b7e429d481112372b9dce9dd0`; `rebind.debug.dylib`: `147b3a607f64e870e4cf708baf85002fc47f1a36a49de035bbc8003c26ec5aa2`. Tests use injected output; the agent did not launch this ordinary app or change actual rules/grants. Tests ran with authorized test-manager access; the ordinary build/signature/result inspection ran in the sandbox.

## User hardware follow-up — 2026-10-12

The tester reports the requested focus-switching/fresh-tap walkthrough works after the repair. This is user-reported confirmation of that bounded scenario in the established Trackpad setup, following the identified `a6471db` Debug handoff. The running digest, target apps, actual grants, device/OS details, counts and exact switching timing were not independently captured or restated. It does not quantify the final posting race or establish three-finger/double-tap coverage, measured latency, stress or broader platform/safety acceptance. No agent runtime check or new software test was performed for this follow-up.

## Next step

Preserve the confirmed focus-switching/fresh-tap scenario; do not repeat it without a new concern. Collect the separate [aggregate scheduling measurement](trackpad-scheduling-timing.md#next-step) on an identified ordinary bundle before physical latency claims. Full protected-context/native-conflict, quantified stress and macOS 26/Intel acceptance remains open.
