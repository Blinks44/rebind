# INPUT-019: Trackpad native zoom and post-keyboard tap investigation

- Updated: 2026-11-10
- Stage: awaiting_verification
- Owner: unassigned; source/test investigation released, physical diagnosis pending
- Ownership checked: `main` at `832ea6e`, preserving this chat's uncommitted INPUT-017/018 implementation
- Owned surfaces: trackpad investigation test, affected acceptance/research notes
- Requirements: SPEC §§3.4, 3.5; preserve unmatched input and native-context safety

## Tester acceptance and reports

The tester exercised the current built-in Trackpad and external Magic Trackpad presets successfully on 2026-11-10, with two exceptions: two-finger double taps also invoke native zoom; after ordinary keyboard keys, both surfaces sometimes appear to reject taps for approximately one second, while clicks seem unaffected. Subsequent clarification explicitly identifies ordinary keys on both surfaces, not modifier shortcuts. Exact installed build, OS, settings, timing and device model were not restated; the latest handoff was 1.3.2 (49). Accept ordinary current-pool delivery with these exceptions, without treating this as a complete safety/settings/accessibility/platform matrix or an acceptance of the still-being-tested Magic Mouse additions.

## Smart Zoom decision

Apple's [Multi-Touch guide](https://support.apple.com/en-ie/102482) assigns trackpad two-finger double tap to Smart Zoom and allows manually disabling gestures in System Settings. The [global event-monitor contract](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html) cannot prevent normal delivery. Current contact observation has no cancellation return, and the current event-tap path has no verified selective Smart Zoom ownership. The existing [native suppression review](../research/native-gesture-suppression.md) remains applicable; this is not proof that suppression is impossible under every architecture.

Recommendation: keep the preset and its existing `TrackpadPreset.systemGestureHelp` → `trackpadSmartZoomHelp` guidance; the user can disable Smart Zoom under Trackpad → Scroll & Zoom when using the Rebind double tap. No trigger removal, guessed private event numbers, blanket gesture blocking or preference mutation. Suppression would require a separate scoped capture/coexistence feasibility probe. Apple’s US guide fetch returned HTTP 429; the indexed Ireland guide and developer event-monitor page were available.

## Keyboard source review

- `EngineMailbox.handleAndDiagnose` increments input activity on real key down/up and cancels queued touch work. It stores no post-keyboard timestamp or one-second cooldown.
- `TrackpadTapSession.update` cancels an in-progress or pending gesture on activity change; known neutral survives an activity-only update. A fresh release rearms an interrupted stroke. No fixed delay is added.
- Startup arming is 3 seconds after capture starts; normal release settling is 60 ms. Three/four-finger single taps may additionally wait for their enabled double rule's interval. These are separate from ordinary-key activity.
- The shortcut sender checks currently held output keys/modifiers/buttons, not time since typing. The native buffer accepts contact states 3/4, so upstream contact filtering is another possible explanation requiring observation.
- Modifier changes can select a different runtime and, with no matching rules/clicks, stop capture and later incur startup arming. That separate path does not establish the cause of the clarified ordinary-key report.

No current Apple source established a specific one-second post-typing policy for these devices. Do not label this report standard macOS behavior without runtime evidence.

## Verification and next step

A new parameterized `TrackpadIntegrationTests.ordinaryKeyPairDoesNotDelayTheNextCompleteTap` uses the real mailbox key down/up path and injected contact frames for both categories, idle and interrupted-contact cases. It checks that the next complete tap is ready within 160 ms of the test baseline, including the existing 60 ms settling, and does not deliver twice. It does not observe actual device frames or prove the user's physical symptom resolved.

Next: reproduce once with the existing one-minute `--diagnose-trackpad` report on the identified installed bundle (see DEVELOPMENT), keeping the foreground app unchanged and contrasting ordinary keys followed by a fresh three/four-finger tap with a key-free tap. Capture remains user-controlled; existing rules can execute actions. Compare frame arrival, activity cancellation and recognition/output reasons; if the report cannot distinguish upstream frame filtering, add only a narrowly scoped aggregate observation. No actual rule, permission, OS setting, ordinary app lifecycle or physical input changed during this investigation.

Final verification: **65 Swift Testing methods in three suites pass**, including four new ordinary-key cases (both categories × idle/in-progress contact); `dev.sh format`, `dev.sh lint` and `git diff --check` pass on macOS 27.2 / Xcode 27.1. The initial test build failed because Swift Testing expanded a mutating `takeReady` call on an immutable macro temporary; the test now stores the result before asserting and the final run is green. No production source changed, so no build-number increment or repackaging is required; the current installation artifact remains 1.3.2 (49). This does not establish native post-typing behavior or resolve the physical symptom.
