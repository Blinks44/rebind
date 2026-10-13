# Three-finger single tap engine and storage: 2026-10-11

[INPUT-002](../tasks/INPUT-002-three-finger-tap.md); SPEC §§3.4, 4, 6, 9, 12 / PLAN Phase 5. Baseline `main` / `afb7411` plus uncommitted owned changes. Independent UI-013 Sketch work remains separate. No production input engine launch, native action, real configuration/permission change, Sketch edit or agent commit.

## Implemented scope

- Distinct `threeFingerTap` and existing `fourFingerTap` triggers; complete typed single-tap identities, fixed two-rule runtime snapshot and explicit per-preset lookup. Missing/disabled/inactive-profile rules do not fall back to another tap.
- Native capture now obtains the qualified preset through the same atomic accepting/empty/no-loss buffer check and submits its configured shortcut to the existing bounded single slot. Submission also checks the selected rule against the snapshot. The serial worker still targets the captured PID and rechecks cancellation, expiry, activity, permissions and protected/held-input guards.
- Reused `ShortContactRecognizer`, which already recognizes three/four stationary contacts. Renamed FourFingerTapGate to TrackpadTapGate and allowed both complete counts. Acquisition ABI/callback, 400 ms duration / two peak frames / travel tolerances, 3 s arming and 60 ms settling remain unchanged. No task/actor hop, file work or allocation-heavy recognition added to the synchronous native callback.
- Schema 25 distinguishes the new payload from historical formats. Schemas 1–24 migrate without altering old rule identities, profiles, selection, pause or language/setup preferences. Three-finger payloads disguised as schemas 1–24 are rejected, including inactive profiles. Existing protection of future/corrupt originals remains.
- EN/RU/DE/FR labels render the persisted trigger accurately. Touch triggers remain excluded from mouse diagnostics and Quartz matching/suppression.

This is an experimental engine/data handoff, not a newly selectable product gesture. The current editor still creates four-finger rules and retains its four-finger-only help. Final preset selection and three-finger conflict UX must come from the live UI-013 Sketch design before exposing this slice. Full shared touch action support, modifiers, double taps, physical clicks, corners, external Magic Trackpad and Magic Mouse remain separate.

## Research refresh

Reviewed Apple's [AppKit touch-event delivery](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/HandlingTouchEvents/HandlingTouchEvents.html): view/responder touch handling does not establish a global capture/suppression replacement. Apple's [Multi-Touch gestures](https://support.apple.com/en-ie/102482) reserves the three-finger tap for Look Up/data detectors; coexistence requires testing and an explicit safe setup path. No system gesture setting was queried or changed by this task.

Rechecked OpenMultitouchSupport [README](https://github.com/Kyome22/OpenMultitouchSupport), [manifest](https://raw.githubusercontent.com/Kyome22/OpenMultitouchSupport/main/Package.swift), [manager source](https://raw.githubusercontent.com/Kyome22/OpenMultitouchSupport/main/Sources/OpenMultitouchSupport/OMSManager.swift), full [MIT license](https://raw.githubusercontent.com/Kyome22/OpenMultitouchSupport/main/LICENSE) and [releases](https://github.com/Kyome22/OpenMultitouchSupport/releases). Current manifest: tools 6.2/macOS 15, binary 4.0.0 target and AsyncAlgorithms; manager exposes shared asynchronous touch data from the default device. This does not replace Rebind's bounded callback buffer, independent click settling, cancellation or recognition. No package, binary or source adopted. Releases show 4.0.0; exact current main SHA/date could not be retrieved through the GitHub API. Swift Package Index search was performed, but the direct package listing failed; no SPI compatibility or local package-build claim. Retain the earlier broader MIT/GPL alternative audit in [tap reliability research](../research/trackpad-tap-reliability.md).

## Software verification

Environment from `apps/rebind/scripts/dev.sh doctor`: Apple Silicon, macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), Swift 6.4, SDK 27. Injected contacts, temporary authored configurations and shortcut worker stubs; no actual touch/output validation.

- `apps/rebind/scripts/dev.sh test -only-testing:apps/rebind/rebindTests/TrackpadSingleTapTests -only-testing:apps/rebind/rebindTests/TrackpadSingleTapPersistenceTests -only-testing:apps/rebind/rebindTests/TrackpadSingleTapLabelTests -only-testing:apps/rebind/rebindTests/TrackpadIntegrationTests -resultBundlePath build/ThreeFingerTargetedComplete.xcresult`: **48 functions / 183 expanded executions / zero failures or skips**, including existing four-finger buffer/recovery regressions.
- New tests cover three-only/four-only/both/no rules, alternating delivery once to the correct targeted worker, disabled/inactive-profile rules, profile switching, forged snapshot rejection, click delays, queued contacts, overflow/stop/focus/revision/activity/malformed-frame and busy-consumer cancellation/recovery, movement/long/ordinary contacts, expired output and cancellation during sender preparation, schema round-trip/migration/rejection/conflicts, and all four labels.
- Initial sandboxed test could not start compiler macro processes (`sandbox_apply: Operation not permitted`). Approved Xcode run exposed a mutating expression inside `#require`; evaluating it before the macro fixed compilation. Final targeted run above passes. Updated the existing Language migration test to compare against the current schema rather than hard-code 24.
- `apps/rebind/scripts/dev.sh test -resultBundlePath build/ThreeFingerRegression.xcresult`: **614 functions / 1,649 expanded executions / zero failures or skips** (602 Swift Testing functions in 84 suites plus 12 native XCTest checks). Existing AboutLayoutTests QoS warning remains; the final xcresult reports one runtime warning and no test failures. Native fixtures test the existing UI, not a three-finger preset editor.
- `apps/rebind/scripts/dev.sh build`: **BUILD SUCCEEDED**. `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` passes; local ad-hoc signing, bundle `blinks44.rebind`, Debug arm64. No distribution-signing claim. No warnings in the final standalone build log.
- Final executable: `build/DerivedData/Build/Products/Debug/Rebind.app/Contents/MacOS/Rebind`, SHA-256 `dec790e7147a076084ef84857a241a1af39e6088b799b2e2d0b1cb604342450e`. `git diff --check` passes. No later source/resource change after these checks.

Local logs/results stay under ignored `build/`; no routine verification images were produced.

## Open acceptance and next step

Hardware delivery, accuracy, latency, physical-click exclusivity, rolling contact timing and native Look Up/data-detector coexistence are **unverified for three fingers**. No suppression, supported release preset, external-device, macOS 26 or Intel claim. The existing four-finger user confirmations remain bounded historical evidence, not a test of this changed artifact.

After UI-013 releases the relevant design, integrate the complete preset selector and native-conflict guidance, then run a user-led three/four-finger comparison on an identified build. Do not create or enable real rules through a fabricated fixture/backup merely to validate this engine handoff.
