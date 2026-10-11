# Trackpad buffer loss and readiness — 2026-10-11

[INPUT-001](../tasks/INPUT-001-four-finger-tap.md); SPEC §§3.4, 6, 12, T1/T2. Engineering-only follow-up to the existing experimental four-finger tap. No Sketch, UI, catalog, schema, dependency, gesture-threshold or native-suppression change.

## Defect and correction

Previously native polling checked overflow once before draining. A producer could overflow after the terminal release was dequeued but before classification finished. The session could then qualify and consume a tap despite lost intervening frames. Separate queue draining/readiness also allowed an already queued contact to wait until after that readiness decision.

The existing buffer now drops further frames while overflow is unacknowledged. Session draining checks loss throughout its bounded 64-frame turn and after its final dequeue, cancelling recognition and reporting the existing aggregate overflow reason. Readiness checks acceptance, loss and queued frames together under the buffer mutex: loss/stop cancels, remaining frames defer the decision until consumed. Only session state changes under this short lock; clocks, diagnostic callbacks and mailbox submission remain outside it. Native callbacks still copy bounded value data synchronously and retain no native pointers.

This is a readiness check against the queue, not atomicity between native acquisition and Quartz posting. A callback can arrive after the decision; existing worker activity/focus/runtime/permission/deadline guards remain. No new end-to-end safety or suppression claim follows.

Retained the existing Swift Synchronization primitive after reviewing official [Mutex](https://developer.apple.com/documentation/synchronization/mutex) and [withLock](https://docs.swift.org/latest/documentation/synchronization/mutex/withlock(_:)/) documentation. No new acquisition/action mechanism, library or copied third-party implementation was introduced.

## Injected software verification

Baseline began at `main` / `8daa97b`; external commit `9253799` integrated independent Mouse/About/design records during this work. Checked source is `9253799` plus scoped changes to NativeTrackpadBuffer, TrackpadTapSession, TrackpadCapture and their two test files. Environment: MacBook Air / Apple Silicon, macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), Swift 6.4, SDK 27. Test host never calls AppModel.start(), starts acquisition or posts a test shortcut; real configuration/grants/login are untouched.

- Before correction: `scripts/dev.sh test -only-testing:rebindTests/TrackpadIntegrationTests -resultBundlePath build/TrackpadBufferRegressionBefore.xcresult` failed the new before/during-drain cases (four assertion issues); other tests passed. The during-drain case deterministically injects producer overflow between dequeue and terminal-release classification, without timing sleeps.
- After correction: `scripts/dev.sh test -only-testing:rebindTests/TrackpadIntegrationTests -only-testing:rebindTests/NativeTrackpadBufferTests -resultBundlePath build/TrackpadBufferSafetyChecked.xcresult` passed **40 test functions / 106 expanded executions**, zero failures/skips. Tests cover overflow quarantine, loss before/during/after draining, stop after drain, queued new contacts and the 64-frame budget with a continuously refilled queue.
- Repeated injected stress: **200 overflow/recovery cycles**, 200 cancelled candidates, 200 fresh readiness results, zero cancelled-candidate outputs and zero duplicates, with 200 overflow reports. These are session decisions over fabricated frames, not physical gestures, Quartz delivery or latency measurements.

The first sandboxed Xcode attempt could not reach testmanagerd; actual tests used the approved native execution path. A method-level Swift Testing filter selected zero tests; suite filters above provide the real evidence. Result bundles and logs stay local/ignored.

## Final regression and artifact

- `scripts/dev.sh test -resultBundlePath build/TrackpadBufferFullRegression.xcresult`: **TEST SUCCEEDED**, 579 Swift Testing functions / 78 suites + 12 XCTest = **591 tests / 1,496 expanded executions**, zero failures/skips.
- `scripts/dev.sh build`: **BUILD SUCCEEDED**; `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` passes. Local ad-hoc signature only; no distribution/signing claim.
- Debug bundle: `build/DerivedData/Build/Products/Debug/Rebind.app`, unchanged bundle ID `blinks44.rebind`. Executable SHA-256 `e3c430af00f3405fd6666b606ee05aab9c952d01f91a4c94c0287e66130361fc`; implementation `rebind.debug.dylib` SHA-256 `e53d56243bd1e7b4f87c34dedfffe2ef7ba24f7156fcb94736b5fd83ed1a3956`.
- Existing About Find fixture QoS warning remains in xcresult; the aggregate main-window matrix logs an excessive live-window count of 101, as in earlier verification. Apple Shortcuts service messages also remain. Passing bounds assertions do not establish production leak/performance acceptance or a warning-free app.
- Final diff review preserves bounded synchronous acquisition, the 64-frame turn, existing thresholds/dispatch guards and diagnostics outside the buffer lock. `git diff --check` and scoped document links pass. No agent commit or production app launch.

## Remaining acceptance

INPUT-001 remains `awaiting_verification`: measured physical latency, quantified quick/held-click/mixed-input stress, protected-session/native-conflict and macOS 26/Intel gates remain open. Previously confirmed delivery/click-only recovery and lifecycle subsets are preserved. Next verify delayed/busy-consumer cancellation and subsequent fresh-tap recovery on an identified build and disposable target, without repeating already confirmed scenarios absent a new concern.
