# About and licenses — native integration, 2026-10-11

## Outcome and source

[UI-010](../tasks/UI-010-about.md) integrates About beside Settings and replaces the standard application-menu About command with the same single SwiftUI window. Live Rebind.sketch `07 · About / Rebind` was inspected through MCP tree, text and screenshot on 2026-10-11; Sketch remained read-only. After the independent Mouse release saved a new document ID, the unchanged About tree/text/screenshot was rechecked in the current source. The delivered app icon is resolved from the running bundle. Version/build come from its Info.plist; all 12 new interface keys have EN/RU/DE/FR translations. Original bundled license text is preserved verbatim in its source language.

Baseline: task started on `main` / `bf36465` with independent Advanced/design edits. External commit `8daa97b` captured those earlier changes during this task. About source/catalog/navigation/tests and this task's documentation remain uncommitted; no agent commit or project-setting change.

Native adaptation: the compact centered Sketch composition opens as a reusable auxiliary window from both entry points. Done/Return/Escape close it. Licenses opens a native document sheet with read-only NSTextView, selection/scrolling and a Find button/Command+F using AppKit's built-in find bar. Missing/unreadable notices produce a localized explanation. No new dependency, external website, capture/action path, real configuration/grant/login change or configured remapping.

The implementation reuses public [NSTextFinder](https://developer.apple.com/documentation/appkit/nstextfinder), NSTextView/NSScrollView and SwiftUI's [appInfo command placement](https://developer.apple.com/documentation/swiftui/commandgroupplacement/appinfo). Current Apple documentation and the installed SDK declarations were checked; no custom search engine or library is needed. AppKit focus/find-bar work is deferred beyond the SwiftUI representable update, with a weak view/window check, to avoid a demonstrated update cycle. This queue is UI-only; synchronous input callbacks remain unchanged.

## Agent-observed native checks

Apple Silicon MacBook Air, macOS 27.0.1 (26A434), Xcode 27.0 / Swift 6.4 / SDK 27. Computer Use inspected the identity-isolated test host (`blinks44.rebind.aboutverification`), with no AppModel.start() and no user configuration. The second fixture uses an authored empty/paused temporary store, acknowledged setup, injected missing grants and a stub login service. Its terminal assertions confirm remapping remains paused and bindings empty. App-level Dark appearance is scoped to the isolated test process; system preferences were not changed.

```sh
apps/rebind/scripts/dev.sh test -only-testing:apps/rebind/rebindTests/AboutInteractiveTemporaryTests \
  PRODUCT_BUNDLE_IDENTIFIER=blinks44.rebind.aboutverification \
  CONFIGURATION_BUILD_DIR=/private/tmp/RebindAboutNativeProducts \
  -resultBundlePath build/AboutInteractive2.xcresult
```

One temporary XCTest passed. Its source was removed before final checks; the historical command requires recreating the fixture. Native observations are separate from its basic assertions:

- Application-menu and full-main sidebar actions both open the actual `about` scene; Russian Light/Dark identity, version 1.0 (1), icon and compact text were reviewed live.
- Readable full license text and native scroll/document semantics are exposed in the AX tree. Command+F opens the native search field; an authored search finds/highlights the expected credited source. Closing/reopening Find works. Escape first hides Find, then dismisses Licenses; focus returns to Licenses in About. Return and Escape close About and reveal the original main window.
- The first native run exposed an inert Command+F despite `usesFindBar`; the visible localized Find button now supplies its window-scoped keyboard command. This was checked live in the second run.
- The second run and the first full regression run exposed attribute-graph cycles when Find changed focus during updateNSView. The final source defers that work to the next main-queue turn; the final targeted regression below covers this repair; live interaction was not repeated after the deferral.

Interactive logs also contain the previously isolated [AppKit sharing-indicator geometry warnings](appkit-sharing-indicator.md), startup layout-recursion and AppIntents/service messages. These runs do not establish a warning-free app. Local screenshots/attachments are not versioned. Offscreen Dark attachment capture did not faithfully capture all SwiftUI text/control layers; live Dark inspection supplies visual evidence instead.

## Final checks and artifact

- `apps/rebind/scripts/dev.sh test -resultBundlePath build/AboutFinal.xcresult`: **TEST SUCCEEDED**, 564 Swift Testing + 10 XCTest = **574 tests**, 1,468 expanded executions, zero failures/skips. This full run preceded the final Find deferral; it established the unchanged input/storage/Settings regressions and exposed the cycle subsequently repaired.
- `apps/rebind/scripts/dev.sh test -only-testing:apps/rebind/rebindTests/AboutInformationTests -only-testing:apps/rebind/rebindTests/AboutLayoutTests -resultBundlePath build/AboutFinalRepair.xcresult`: **four tests pass**, zero failures/skips, on the final source. Shipped metadata/notices match actual bundle resources; 48 About/available-unavailable license size/locale/appearance combinations fit. NSTextView is read-only/selectable, localized and focusable. Find opens/reopens and ordinary updates preserve selection/content. No attribute-cycle or negative-geometry message in this run. Native bounds assertions alone are not complete visual/accessibility acceptance.
- The repaired run retains one internal QoS priority-inversion warning at the test's NSHostingController root replacement. It is recorded rather than treated as a warning-free result; no production latency/profile conclusion is established.
- `apps/rebind/scripts/dev.sh build`: **BUILD SUCCEEDED** after the final targeted checks. `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` passes; local ad-hoc signature only.
- Catalog review: 12 new manual keys, all four translations present. `git diff --check` passes; local screenshot exports are covered by the existing narrow ignore rule.

Final production Debug artifact: `build/DerivedData/Build/Products/Debug/Rebind.app`, bundle ID `blinks44.rebind`; executable SHA-256 `049b114d542f50b25315d592c442f2f09eca38e28e55559acb9845242a3d3309`. Final ReadOnlyNoticesText.swift SHA-256 `4d19ff52078fd22a0aee5980b858fd29711f66a2b880713e7d1b3023b9fc645f`. Temporary interactive source is absent from final builds. Initial sandbox-only build could not execute Swift macro tooling; builds/tests above used the authorized Xcode execution path. Early missing Done key/read-only-environment fixture errors were corrected before passing checks.

## Open acceptance and next step

Keep UI-010 `awaiting_verification` after implementation/software checks. Verify About and Licenses with VoiceOver: heading/identity/order, Read All and Lines navigation through the full notices, selection by word/line, Find/next/previous and Done, then return to the originating window. Complete Tab/Shift-Tab navigation and search-field Return semantics. Exercise Reduce Transparency, Increase Contrast and Reduce Motion in all four languages. Source review/native AX checks do not establish those manual results; Accessibility Inspector was not used.

Regression risk is limited to auxiliary-window/document focus, Find-bar lifetime and sidebar sizing. macOS 26/Intel execution and production language/relaunch remain open. Advanced restored-binding acceptance and independent Mouse design remain separate.
