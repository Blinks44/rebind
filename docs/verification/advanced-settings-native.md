# Advanced settings — native integration, 2026-10-11

## Outcome and artifact

[UI-007](../tasks/UI-007-advanced-settings.md) integrates Advanced, native file panels and destructive confirmation, configuration replacement/reset, protected-original export and the existing mouse diagnostics. Live Rebind.sketch Screens 48–69 and Foundations 05–10 were inspected through MCP; no Sketch edits/saves by this implementation. All four languages use the existing launch-language/reopen contract. Native content cards adopt the handed-off elevation/lighting; broader main-window materials remain separate.

Checked `main` / `bf36465` plus final AdvancedSettingsView/AppModel refinements, AdvancedConfirmationAlert, behavioral-test refinements and removal of the temporary interactive test. HEAD advanced externally during implementation; this agent made no commit. Independent Mouse design work was preserved.

Environment: Apple Silicon MacBook Air, macOS 27.0.1 (26A434), Xcode 27.0 / Swift 6.4 / SDK 27. Final Debug product: `build/DerivedData/Build/Products/Debug/Rebind.app`, unchanged production bundle ID `blinks44.rebind`. Executable `Contents/MacOS/rebind` SHA-256: `9521f05388bb44d85f0ca3688cac4cc0e5af8fe73181a9a14ee75b17be01d99c`. AdvancedConfirmationAlert.swift SHA-256: `2fd1f449c819e940df09f39dc8d39ad08d65c1608c3a781c9af5fd862ccb12c1`.

## Behavior and software evidence

Import validates/migrates a bounded backup off MainActor, stages counts and requires confirmation. Replacement checks the reviewed configuration/revision and current disk contents, persists atomically before changing runtime state, then pauses remapping. Local setup acknowledgement is retained; imported language/settings require the existing reopen behavior. Reset uses defaults and the same transaction. Pending output, recording, diagnostics and stale editors are invalidated; held-source release ownership is retained. Failed writes preserve current state and allow retry. Cancellation changes nothing. No SMAppService/grant changes are performed by import/reset.

Healthy export validates a snapshot and writes atomically. Protected storage offers only original-file reveal/export; corrupt/future bytes are copied unchanged, including files beyond the JSON limit. Original-path, symlink and hard-link destinations are rejected. Native FileManager replacement staging keeps raw-copy memory bounded. Security-scoped access and page-owned asynchronous work are balanced. These are local transactions, not interprocess file locking.

- `apps/rebind/scripts/dev.sh test -resultBundlePath build/AdvancedSettingsFinal.xcresult`: **TEST SUCCEEDED**, **563 Swift Testing tests / 76 suites + 7 XCTest tests = 570 tests**, **1,464 expanded executions**, zero failures/skips. xcresult reports no runtime warnings. Authored temporary stores/injected state cover paused roundtrip, reset, rollback/retry, cancellation, stale/multiwindow review, external corrupt/future-file protection, source-release ownership, independent localized plurals, diagnostic status gates, alias protection and raw-copy/size boundaries. Tests never start the global input engine.
- Native geometry: 112 Advanced state/locale/appearance/size combinations; 16 Settings/diagnostics windows; 416 full-main Settings combinations including Advanced/protected storage, plus existing permission/General/Input/Language checks. Final Russian Light/Dark overview and protected-state attachments were inspected locally. Five sections exceeded standard width in German/French; ViewThatFits now selects a native menu when the segmented control cannot fit.
- Foundation URL metadata caching caused a failed-write retry to keep treating a repaired file as a directory. Fresh metadata URLs fix that failure; the retry and cached-URL regression tests pass.
- `apps/rebind/scripts/dev.sh build`: **BUILD SUCCEEDED** after the final suite. `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` passes; local ad-hoc signature only.

Logs retain AppIntents metadata/service messages, stale-output warnings from the isolated fixture build directory, and one excessive-live-window warning at 101 windows during the large layout matrix. No negative geometry or layout-recursion message occurred in the final non-inspected suite. The live-window warning is test-host evidence; window-count/leak profiling is not established by passing bounds assertions. Earlier interactive runs retain the separately diagnosed OS [sharing-indicator warning](appkit-sharing-indicator.md) and occasional startup layout recursion; no private OS workaround was added.

## Agent-observed native interaction and accessibility

An authored two-profile/no-binding fixture used a temporary configuration, stub login service and no AppModel.start(). Command-line bundle/output overrides isolated it from the production app; project identity/settings were unchanged. Native open/save panels, cancel, staged import counts and English Dark Advanced semantics were inspected through Computer Use. No export destination was committed or destructive replacement executed through the UI.

Final keyboard run:

```sh
apps/rebind/scripts/dev.sh test -only-testing:apps/rebind/rebindTests/AdvancedInteractiveTemporaryTests \
  PRODUCT_BUNDLE_IDENTIFIER=blinks44.rebind.advancedverification \
  CONFIGURATION_BUILD_DIR=/private/tmp/RebindAdvancedNativeProducts \
  -resultBundlePath build/AdvancedNativeKeyboard2.xcresult
```

One XCTest passed; its final assertions confirm unchanged source bytes and replacement revision zero. The temporary fixture was removed before the final full suite, so rerunning this exact historical command requires recreating a scoped fixture. Final native reset confirmation opens with Cancel focused/default; Escape closes it, and reopening then pressing Return also cancels. Earlier SwiftUI/native alert variants failed Escape with safe Cancel as the default. **P1 fixed:** AdvancedConfirmationAlert uses an NSAlert sheet with Cancel default and a local, sheet-scoped Escape monitor, removed on dismissal. Import/reset share this factory; eight localized construction cases verify button/default/destructive semantics. Final native import confirmation was not separately repeated after this fix.

No P0 finding emerged from scoped source/AX/keyboard review. Native headings/buttons/table semantics, count plurals and contrast-sensitive borders are retained. VoiceOver, complete Tab traversal and accessibility preferences were not exercised; source review does not close those gates. Local screenshots/result bundles are not versioned.

## Open acceptance and next step

### User restoration follow-up — 2026-10-11

In response to the named backup-restoration/restored-rule scenario, the tester reports that it works. Record this as a user-confirmed restoration happy path. Exact export/reset/import/resume steps, tested bindings/profile counts, enabled/paused transitions and build/OS were not restated, so this broad report does not certify the complete identified-build SPEC §15.12 walkthrough or failure/cancellation/accessibility coverage. No new agent app execution/build/test accompanied this documentation update. Next native engineering check: Advanced keyboard/focus and VoiceOver; retain the detailed runtime walkthrough where evidence remains unspecified.

Keep UI-007 `awaiting_verification`. Run SPEC §15.12 on an explicitly identified build and disposable authored profiles: export → confirmed reset → import → explicit resume → observe restored binding behavior. Then test:

### User navigation/accessibility follow-up — 2026-10-11

After the named keyboard-navigation/focus/accessibility checks, the tester reports successful operation. This is a broad user-confirmed interaction result; exact controls, Tab/Shift-Tab/Escape/Return paths, VoiceOver use, accessibility preferences, locale and artifact/OS were not specified. Do not infer a complete VoiceOver/preferences matrix or close all UI-007 acceptance from this report. Retain the detailed checks below; next implementation work may proceed independently of this evidence gap. No new agent app build/test or UI change was performed for this update.

- VoiceOver order: section navigation, card headings/actions, alert title/counts/Cancel/replace, diagnostic table columns and status; dismissing a modal returns focus to its initiating control.
- Keyboard: Tab/Shift-Tab through compact menu and card actions, both import/reset alerts and file panels; Escape/Return cancel safely, destructive action requires explicit activation.
- Light/Dark with Reduce Transparency, Increase Contrast and Reduce Motion; all four languages, long counts, compact width, language reopen and protected/error/retry states remain readable and operable.
- Multiwindow alert/editor invalidation and cancellation while navigating/closing; regression risk is modal lifetime and stale configuration, not new capture behavior.

Production restart/login/language checks remain user-led. Actual grants/revocation, hardware diagnostics expiry/collection, full restored-binding runtime behavior, macOS 26 and Intel execution remain open. No real user rules, configuration, permissions, login registration or remapping were changed in this verification.
