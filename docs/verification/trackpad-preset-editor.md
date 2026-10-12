# Trackpad tap preset editor — native/software evidence

2026-10-12, [UI-014](../tasks/UI-014-trackpad-presets.md). Baseline `main` / `afb7411` plus the existing INPUT-002/003 engine/data work; no agent commit. macOS 27.0.1 (26A434), Apple Silicon MacBook Air, Xcode 27 / Swift 6.4 / SDK 27. Minimum macOS 26 and Intel remain unverified.

## Implemented scope and design reconciliation

One complete preset selector exposes three/four-finger single/double taps. Saved edits retain rule ID, enabled state and shortcut; selecting a preset normalizes press/no-modifier semantics. The output recorder remains independent, supports clear/cancel/Escape and preserves previous output on cancellation or stale requests. Save retains existing profile/replacement/storage guards. Duplicate feedback identifies the selected profile and asks for another gesture or editing the existing rule.

Read live Rebind.sketch through MCP on 2026-10-12: Screens 93/99/106, shared Complete preset component and Foundations 16/22, document `4B31A177-0924-4510-AC9B-D71EB9C06470`, Sketch 2026.3.1/API 2.0.0. [DESIGN](../DESIGN.md) owns the saved revision/digest. Applied the 512 pt scrollable editor, 36 pt glass capsule selector, concise changing explanation, independent raised capture surface and pinned actions. Header/form spacing and full localized recording labels were corrected after native inspection.

This is a bounded adoption, not the complete final release design: only four engine-backed presets and keyboard shortcut actions are exposed. Two-finger doubles, physical clicks, corners, modifiers, broader touch actions and final Trackpad list/search/keycap/profile/material adoption remain separate work. No unsupported future item is presented as operational and no touch trigger recorder or arbitrary gesture builder was added.

## System coexistence and native APIs

Guidance is conditional, not a settings/grant probe. Three-finger single taps identify possible Look Up/data-detector coexistence; three-finger double taps identify possible Accessibility Zoom coexistence; all presets disclose lack of native suppression. Apple's [Multi-Touch gestures](https://support.apple.com/en-ie/102482) and [Zoom guide](https://support.apple.com/en-gb/guide/mac-help/mchl779716b8/mac) were refreshed on 2026-10-12. No native preference writes, new capture mechanism or dependency.

The recovery button uses public Launch Services application lookup and NSWorkspace opening, with visible failure handling. It opens System Settings at the app's chosen pane; text supplies the relevant Trackpad or Accessibility → Zoom route. This deliberately avoids relying on a private pane URL. The button was not executed during agent review.

Apple's [Glass button documentation](https://developer.apple.com/documentation/swiftui/glassbuttonstyle) and installed SDK declarations were checked: the used Glass/identity/glassEffect APIs support macOS 26. Selector/action surfaces fall back to opaque surfaces for Reduce Transparency; the selector strengthens its edge for Increase Contrast. Actual system preference and VoiceOver acceptance remains open.

## Checks and review limits

- Initial behavior run: `scripts/dev.sh test -only-testing:rebindTests/TrackpadBindingEditorTests -only-testing:rebindTests/MouseBindingEditorTests -only-testing:rebindTests/AppModelRecordingTests -resultBundlePath build/TrackpadPresetBehavior.xcresult` passes: 19 functions / three suites. Covers exact preset persistence, identity/enabled retention, normalization, profile conflicts, stale/cancelled/wrong-category capture and save-failure retention, with Mouse/recording regressions.
- New native matrix: four languages × Light/Dark × ten editor states × 488/640 pt heights = 160 viewport checks. States cover all four saved presets, new draft, duplicate, missing injected access, recording, storage failure and disabled rule. These fixtures never start capture or load real configuration. Bounds/scroll-width assertions certify sizing, not complete accessibility or visibility.
- Early native attempts found test assumptions to repair: macOS accessibility preferences are read-only environment values; safeAreaInset does not shorten the outer NSScrollView frame; offscreen hosting does not expose the footer AX nodes. Those assertions were removed rather than mislabeled as proof. Live bounded AX/visual review supplements the final geometry matrix; full traversal remains open.
- An isolated native review bundle used `blinks44.rebind.verification.trackpad`, temporary authored configuration and an explicit no-load/no-start guard. Live RU Light/Dark inspection confirmed glass rendering, full recording labels and Cancel/Save accessibility identifiers. Preset switching updated descriptions/guidance while keeping the shortcut; recording disabled selector/Save, and Escape restored the prior output with focus returning to Record. The final compact header/menu were reviewed in live Dark. A later transient menu element ID prevented completing an additional keyboard-navigation check; full arrows/Return/Tab traversal remains unverified. No action output was posted.
- Temporary review source was removed and the ordinary `rebindApp.swift` restored before the final regression/build. Production project settings and bundle ID remain unchanged. GPU glass is not fully represented by offscreen bitmap attachments; these are not material certification. SwiftUI locale fixtures and explicit Foundation translation tests do not prove production language activation/relaunch.

## Regression and identified artifact

- `scripts/dev.sh test -test-timeouts-enabled YES -maximum-test-execution-time-allowance 180 -resultBundlePath build/TrackpadPresetFinalRegression.xcresult`: **TEST SUCCEEDED**, **647 functions / 1,824 expanded executions**, zero failures/skips. Includes the native Trackpad matrix, all existing Mouse/editor/storage/engine tests and the previously slow Settings matrix (64.067 s). About's pre-existing QoS warning and AppKit aggregate live-window-count warning remain; this is not a warning-free runtime claim.
- `scripts/dev.sh build`: **BUILD SUCCEEDED**; no Swift compiler errors/warnings in the final standalone log. `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` passes, local ad-hoc signature only.
- Ordinary Debug artifact: `build/DerivedData/Build/Products/Debug/Rebind.app`, bundle ID `blinks44.rebind`. Executable SHA-256 `cabe4a333b1d4f7cd8d5d20eb1731f65b1195b2e8c9c6109a840a6dd2301c447`; `Rebind.debug.dylib` SHA-256 `043976322415fe70bc9409b979182b0a3dcf1781b9a82b33832f5bf903cda29e`.
- Final local attachment review covered DE full labels/Look Up, FR duplicate state, RU recording and EN failure fixture. Glass rendering limitations and scrolled/clipped lower feedback mean the offscreen images alone do not certify all feedback/control visibility. The failure fixture was subsequently given a rendering yield before its snapshot; app code is unchanged.
- Catalog review: all 19 Trackpad keys include EN/RU/DE/FR; new guidance does not read or change native settings. `git diff --check` passes.
- `scripts/dev.sh test -only-testing:rebindTests/TrackpadEditorLayoutTests -resultBundlePath build/TrackpadPresetFeedbackRecheck.xcresult`: **TEST SUCCEEDED**, one native function / the same 160 viewport combinations after the test-only rendering-yield change. App source and the identified debug implementation digest are unchanged. Offscreen failure snapshots still do not establish that the error card is rendered/reachable; actual save-error feedback verification remains open.

Logs, result bundles and images stay ignored/local under build; no screenshot is versioned. No Sketch edit/save, real rule/grant/login/preference change, production engine launch or agent commit.

## Remaining acceptance and next step

On an identified normal build and an authorized test profile, verify real three/four-finger single/double taps, capture/output cancellation, click exclusion, pair timing, native Look Up/Zoom coexistence and safety/lifecycle recovery. Keep prior INPUT-001 user-confirmed subsets separate. Complete keyboard/VoiceOver, adaptive preferences, all production locale contexts and minimum-OS/Intel checks. UI-014 remains `awaiting_verification`; broader touch engine/action/list adoption remains in PLAN.

## Direct menu and full-area hit testing follow-up

2026-10-12: the custom Menu label's expanded visual frame lacked a matching hit shape; a default Picker nested inside Menu produced an intervening category submenu. Add a rectangular content shape after the full-width/minimum-height label frame and use an inline, labels-hidden Picker. Preserve native selected-item semantics, accessibility purpose/value, recording-disabled state and existing glass composition.

Live isolated fixture `blinks44.rebind.verification.trackpadmenufix` used temporary authored rules and a no-load/no-start guard. Pointer checks on left label, empty center and right chevrons opened the same four direct items; Escape closed the list. Selecting the four-finger double tap updated explanation/guidance and preserved the shortcut. No configured output or real configuration changes. Temporary scene/delegate changes were restored before normal product checks.

The fresh Sketch tree request did not respond and was stopped. No new visual direction or Sketch edit; this interaction correction follows the explicit product requirement and previously inspected source. Reconcile separate UI-015 refinements when released.

- `scripts/dev.sh test -only-testing:rebindTests/TrackpadBindingEditorTests -only-testing:rebindTests/TrackpadEditorLayoutTests -resultBundlePath build/TrackpadMenuFixTests.xcresult`: **8 functions / 23 executions**, zero failures/skips, **TEST SUCCEEDED**. The native function covers 160 viewport combinations. Earlier 647-function regression is retained, not rerun for this control-only fix.
- `scripts/dev.sh build`: **BUILD SUCCEEDED**; strict/deep ad-hoc signature passes. Current normal Debug product: bundle ID `blinks44.rebind`, executable SHA-256 `4d2f444bf56ea5e613f34a8a826307188deb7b8a1647f0df5642ae4517d0ee6e`, implementation dylib SHA-256 `26da3aff29d8618eb829a6ca1923553dbb2b9afd18d67330f73ee94a3ce6cde8`. This supersedes the earlier artifact for runtime checks.
- `git diff --check` passes. No engine/catalog/project setting change or agent commit; broader physical/accessibility gates remain open.
