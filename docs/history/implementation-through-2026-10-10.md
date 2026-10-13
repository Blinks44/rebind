# Implementation evidence through 2026-10-10

This is a technical summary of earlier implementation and verification. It is not a transcript or a statement of current product readiness. Current requirements/status belong in [SPEC](../SPEC.md), [STATE](../STATE.md), [PLAN](../PLAN.md) and [CAPABILITIES](../CAPABILITIES.md). Results below were recorded in the original development sessions; documentation cleanup did not rerun them.

## Research findings / blockers

- Capture uses a public active Quartz tap on an owned run loop, with bounded synchronous matching/mailbox and separately executed actions. Device-specific Quartz attribution was not established; physical-device routing/inventory was withdrawn. See [current decisions](../research/README.md) and [reference/license register](../research/DEPENDENCIES.md).
- Accessibility and event-posting preflight are separate checks. The current tap does not require an additional Input Monitoring startup grant. Stable signing/TCC persistence and revocation remain runtime gates. See [permissions](../verification/permissions.md).
- Trackpad acquisition uses an isolated private adapter informed by pinned Subsurface ABI. Contact recognition does not prove native gesture suppression, external-device support or click exclusivity. Probe results and app integration remain separate. See [trackpad contract](../verification/phase-5-four-finger-tap.md).
- Spaces uses validated standard Control+arrow HID posting. Earlier session-posting and instant Dock-swipe approaches were superseded; the latter failed animation/edge acceptance. Dock notifications and screen locking remain experimental private paths. See [Spaces](../verification/phase-4-spaces.md), [Dock](../verification/phase-4-dock.md) and [lock](../verification/phase-4-lock-screen.md).
- Previous Application uses public AX activation after cooperative AppKit activation failed background switching. See [application switching](../verification/phase-4-application-switch.md).
- Detailed dependency pins/licenses and mechanism alternatives remain in the research register and scoped verification records rather than a copied conversation log.

## Session log

The heading is retained for earlier evidence links. Entries are scoped technical outcomes with reported or software-observed evidence, not verbatim session records.

### 2026-10-10: Click-to-tap recovery after idle native frame gaps

Pure regression tests reproduced repeated recognition cancellation after forward frame-ID gaps between neutral strokes. The fix permits forward gaps only when no stroke is open and neutral was observed. Active-stroke/pending-release gaps, backwards or duplicate IDs, malformed/stale data and nonmonotonic timing still cancel. New contacts cancel earlier pending output before starting another stroke.

Recorded checks:

```sh
apps/rebind/scripts/dev.sh test -resultBundlePath build/TrackpadClickRecoveryFinalTests.xcresult
apps/rebind/scripts/dev.sh build
apps/rebind/scripts/dev.sh release
```

Result: **479 tests / 63 suites / 0 failures**; Debug and universal Release builds succeeded; strict/deep signature verification passed. Test inputs were injected, not physical capture/output. An initial method filter selected zero tests; the recorded result is from the corrected suite/full run.

Manual reports indicated better initial recognition followed by loss of shortcut output after physical clicks. That physical sequence and recovery remain unverified on the rebuilt app; the software reproduction does not establish the hardware cause. See [INPUT-001](../tasks/INPUT-001-four-finger-tap.md).

### 2026-10-10: Four-finger tap responsiveness and natural-contact tolerances

Forwarded callback timestamp/frame metadata for zero-contact arrays. Recognition bounds changed to 30–400 ms duration, 150 ms arrival/lift spread, 0.04 per-contact travel and two peak frames. Settling changed from 500 ms to 60 ms; contact identity/movement, active-frame continuity, click/activity/focus/runtime cancellation and dispatch guards remain.

Recorded command: `apps/rebind/scripts/dev.sh test -resultBundlePath build/TrackpadResponsivenessTests.xcresult`; **476 tests / 63 suites / 0 failures**. Debug/Release builds and universal signature checks passed. Integrated output had a manual success report, but roughly one-in-seven recognition and perceived delay failed usability acceptance. Revised latency, reliability and click/lifecycle behavior remain open.

### 2026-10-10: Experimental four-finger app integration and layout

Built-in four-finger single tap → shortcut integrated with manual profiles, versioned schema 22 and experimental guidance. Pure recognition/buffer/migration/dispatch checks passed; native suppression and broader gestures were not implemented.

Recorded commands:

```sh
apps/rebind/scripts/dev.sh test -resultBundlePath build/FourFingerTapIntegrationTests-FocusGuard.xcresult
apps/rebind/scripts/dev.sh test -resultBundlePath build/TrackpadLayoutRegressionTests.xcresult
```

Each recorded **465 tests / 63 suites / 0 failures**; Debug/Release builds passed. Native layout inspection confirmed category/editor transitions at the inspected window size after removing inappropriate vertical fixed sizing. Compact resizing, accessibility and integrated hardware safety were not established by these checks.

### 2026-10-10: App icon and permission designs

Native Icon Composer delivery passed Debug/Release resource/signature checks and Finder preview inspection. The separate menu-bar template was integrated. Dock/live Menu Bar/minimum-OS/tint checks remain open.

Six first-launch/permission frames were saved and reviewed in Sketch. Their state/copy handoff is indexed in [DESIGN](../DESIGN.md) and menu-bar/onboarding verification. Saved frames are not native onboarding implementation.

### 2026-10-08–09: Keyboard, mouse, profiles and actions

The scoped records retain actual test commands, implementations, reported happy paths and remaining checks:

| Area | Evidence |
| --- | --- |
| First capture/remap and permissions | [Phase 1](../verification/phase-1.md), [permissions](../verification/permissions.md) |
| Wheel, double and long press | [Wheel](../verification/phase-2-wheel.md), [double](../verification/phase-2-double-press.md), [hold](../verification/phase-2-hold.md) |
| Pointer gestures, lifecycle and diagnostics | [Pointer](../verification/phase-2-pointer-gesture.md), [lifecycle](../verification/phase-2-lifecycle.md), [diagnostics](../verification/phase-2-diagnostics.md) |
| Manual profiles | [Profiles](../verification/profiles.md) |
| Audio, opening and Shortcuts | [Audio](../verification/phase-4-audio.md), [opening](../verification/phase-4-opening.md), [Shortcuts](../verification/phase-4-shortcuts.md) |
| Windows and application switching | [Windows](../verification/phase-4-windows.md), [layouts](../verification/phase-4-window-layout.md), [cycling](../verification/phase-4-window-cycle.md), [switching](../verification/phase-4-application-switch.md) |
| Application commands and sleep | [Commands](../verification/phase-4-application-commands.md), [sleep](../verification/phase-4-sleep.md) |
| Mouse output, media and system actions | [Mouse output](../verification/phase-4-mouse-output.md), [media](../verification/phase-4-media.md), [Spaces](../verification/phase-4-spaces.md), [lock](../verification/phase-4-lock-screen.md) |

Build/signature checks used the recorded Apple Silicon macOS 27.0.1 / Xcode 27 / Swift 6.4 environment with deployment target 26. Universal x86_64/arm64 compilation does not establish Intel or macOS 26 runtime compatibility. Temporary logs and result bundles are local artifacts, not required repository handoff material.

### Historical software-check register

These are earlier recorded runs, preserved during documentation migration rather than rerun. The invocation pattern is `apps/rebind/scripts/dev.sh test -resultBundlePath build/<bundle>` using the result-bundle names below. Final ordinary `apps/rebind/scripts/dev.sh build` and `apps/rebind/scripts/dev.sh release` and signature checks were recorded as passing for each listed slice. Exact implementation commits were not recorded with these entries; results describe their historical slice, not the current checkout.

| Date | Slice | Result bundle | Recorded full-suite result |
| --- | --- | --- | --- |
| 2026-10-08 | Mouse diagnostics | `Phase2DiagnosticsTests.xcresult` | 159 tests / 24 suites / 0 failures |
| 2026-10-08 | Typed catalog/audio | `SystemAudioActionsTests-Final.xcresult` | 192 tests / 29 suites / 0 failures |
| 2026-10-08 | AX window/application actions | `WindowActionsTests-Final.xcresult` | 205 tests / 30 suites / 0 failures |
| 2026-10-09 | Window layouts | `WindowLayout-Final2.xcresult` | 326 tests / 45 suites / 0 failures |
| 2026-10-09 | System sleep | `SystemSleep-Final2.xcresult` | 354 tests / 48 suites / 0 failures |
| 2026-10-09 | Screen lock/session protection | `ScreenLock-Final3.xcresult` | 371 tests / 50 suites / 0 failures |
| 2026-10-09 | Current-app window cycling | `WindowCycle-Initial.xcresult` | 391 tests / 54 suites / 0 failures |
| 2026-10-09 | Previous Application | `PreviousApplication-Final2.xcresult` | 407 test functions / 57 suites passed |
| 2026-10-09 | Activation-notification order fix | `ApplicationSwitchObserver-Final2.xcresult` | 411 test functions / 57 suites passed |
| 2026-10-09 | Background activation fix | `ApplicationBackgroundActivation-Final2.xcresult` | 420 test functions / 58 suites passed |

The sleep tests preceded final UI-only changes; final Debug/Release builds included them. Native effects were injected in behavioral tests. These runs do not establish hardware delivery, permissions, timing, focus, minimum-OS/Intel or complete localized/accessibility acceptance. The per-area records above retain manual reports and open checks. Current mechanism/license decisions are in the research register; expired local logs are not the sole source of the technical summary.
