# General settings — full-main-window overflow repair

Routine capture files were moved to ignored local storage during repository cleanup on 2026-10-11. The dated observations, commands and acceptance limits below are preserved; these images are not automated test baselines.

Updated 2026-10-11. Scope: [UI-003](../tasks/UI-003-general-settings.md). Reported missing Settings header/sidebar reproduced and repaired in the native main-window hierarchy. This supersedes the earlier assumption that isolated General fixtures established full-window layout correctness.

## Reproduction and cause

Baseline `main` / `b453d8d` plus the uncommitted General layout/accessibility refinements recorded in [initial native evidence](general-settings-native.md). Existing permission/trackpad and independent Language design work preserved; no agent commit.

The reported screenshot showed only lower General content, with the header and sidebar shifted out of view. A native XCTest hosted the actual `ContentView` / `NavigationSplitView` with initial General selection, Russian locale, isolated configuration and injected login/permission state. Capture never started and no real rules, grants or login settings changed.

At a **1157 × 750** content viewport, the native split measured **1157 × 1588**, with its origin at **y = −419**. The regression assertions failed. Removing vertical `fixedSize` from the Settings subtitle reduced the split height to **1092**, still overflowing. Removing it from the pinned General runtime title/description restored the native split to **1157 × 750**, origin **(0, 0)**. The partial-fix probe also failed; the complete-fix probe passed.

These pinned texts participated in native minimum-size measurement and demanded excessive height. The root hosting view itself still had correct bounds, so checking only that root was insufficient. Apple's [fixedSize documentation](https://developer.apple.com/documentation/swiftui/view/fixedsize(horizontal:vertical:)) explains that the modifier fixes the selected dimensions to ideal size; the measured split inflation here is project-specific observed evidence.

The earlier 264 General geometry combinations hosted `SettingsView` directly. The 72 main-window combinations exercised the rules page. Neither exercised General inside the real split-view hierarchy. They were valid for their narrower scopes and did not establish full Settings integration. Skill guidance did not replace this missing acceptance check.

## Fix and regression coverage

- Pinned Settings/runtime texts now honor the parent's size proposals. Content rows retain wrapping inside the scroll view. No clipping workaround, hardcoded height, per-locale offset, sidebar rewrite or target/toolchain change.
- `ContentView` accepts an initial destination, preserving the default keyboard page and subsequent local navigation state. Tests can host the actual main composition for each implemented Settings section.
- `MainWindowLayoutTests.testSettingsDoesNotExpandNavigationBeyondTheWindow` checks **224 combinations**: seven states (paused, active, missing access, capture failure, login approval, missing/allowed Permissions) × EN/RU/DE/FR × Light/Dark × 880 × 600 / 1040 × 640 / 1157 × 750 / 1280 × 800. It checks the actual native split and both columns against viewport bounds, as well as root sizing.
- Existing 72 main/rules and 264 isolated General combinations remain. No test starts input interception or uses real configuration. Temporary printing, visible-window holds and manual inspection helpers were removed before the final suite.
- ENGINEERING records the concrete sizing hazard and requires full-window integration/resizing/transitions when adding sections.

## Native review and final artifact

Live Sketch General source was reread without edits: document `C93BE2C5-55E6-4493-9B4B-FD998F2DE986`, frame `2C9A6A68-F839-46C2-BF15-E672107FB024`. Direction and copy remain unchanged.

In an isolated visible XCTest window containing the actual main hierarchy, native UI inspection confirmed the complete Russian General header, runtime state, toggles and sidebar. General → Permissions → keyboard rules → Settings transitions retained visible controls and restored General. No permission/login/remapping controls were activated. This proves the inspected native hierarchy and navigation; it does not prove real login, grants or VoiceOver.

Environment: Apple Silicon macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), Swift 6.4, SDK 27. macOS 26 deployment target, Swift 6 strict concurrency, scheme/module/product/bundle ID unchanged.

- `scripts/dev.sh test -resultBundlePath build/GeneralMainRepairFinal.xcresult`: **529 Swift Testing cases / 71 suites plus three native XCTest cases, 532 total / zero failures**; `TEST SUCCEEDED`.
- Native fixtures were then corrected to set both NSWindow AppKit appearance and SwiftUI color scheme. A fixture-only compile error (appearance referenced in the earlier non-theme loop) was corrected; `scripts/dev.sh test -only-testing:rebindTests/MainWindowLayoutTests -resultBundlePath build/GeneralMainRepairAppearanceFinal.xcresult`: **two tests / zero failures**, covering all 224 Settings and 72 rules combinations; `TEST SUCCEEDED`. No production behavior changed in that fixture refinement.
- `scripts/dev.sh release`: `BUILD SUCCEEDED`; universal `arm64` / `x86_64`. Final Debug/Release signatures pass `codesign --verify --deep --strict`.
- Current executable SHA-256: Debug `6be3427e8cb162d6fadc820242abbac2bc5dc1b21d14e067958992e14b8fc8af`; Release `8a61d043da5ee923e9a4703335070599980c79896fbe3710d05a2f8417d8c1d7`.
- Affected links, ignored build/result output, curated screenshot paths and `git diff --check` reviewed. No agent commit or Sketch save. Raw logs/result bundles remain local/ignored.

Reviewed final full-main fixtures at 1040 × 640: General paused, login approval, Permissions missing. Permissions lower guidance continues in the scroll viewport. All use authored test data; images cover the hosting content rather than window title-bar chrome. Native live Russian General/navigation was separately inspected as described above.

At the initial repair review, offscreen Dark sidebar labels remained low contrast in cached captures even with matching window appearance; those images are excluded from visual acceptance. The subsequent on-screen review below addresses ordinary Dark rendering. Partial AppKit caches never establish visual acceptance.

## Live Dark follow-up — 2026-10-11

Production source remains the same `b453d8d` plus recorded layout refinements. The current Sketch source was reread without edits: document `702933BB-95EC-4EA6-8571-1058528AF3BB`, Dark paused General frame `410A654D-4DF2-4810-9EA2-79242185FEC3`. The newer [materials review](material-design-review.md) remains a separate native implementation handoff; this check does not claim its adoption.

A temporary visible XCTest hosted the actual full `ContentView` with an isolated Russian configuration, injected missing permissions/login state, AppKit Dark Aqua and SwiftUI Dark. The running executable/test-host identity was checked before native UI inspection. Input interception never started; real rules, grants, login items and system appearance preferences were unchanged.

Agent-observed General → Permissions → General navigation at **1040 × 640** content size retained the header, section controls and sidebar. General remained inside the viewport after interactive resizing to **880 × 600**, with descriptions wrapping and the bottom window/quit guidance visible. Active-window sidebar labels were readable; inactive-window dimming was also observed. This is visual inspection of ordinary Dark in Russian, not a measured contrast/accessibility certification or every state/locale. The black-label offscreen cache was not reproduced in this visible window.

Reviewed native window captures (including 32 pt title-bar chrome): Dark General, Dark Permissions. Both show the inactive-window appearance. Compact General was observed live; a capture taken after the fixture closed showed the unrelated test-host window and was discarded. Permissions lower guidance remains scrollable.

- `scripts/dev.sh test -only-testing:rebindTests/DarkWindowInspectionTests -resultBundlePath build/GeneralDarkVisible.xcresult`: one temporary inspection test passed, 55 seconds.
- The extended 180-second inspection hold (`build/GeneralDarkVisibleReview.xcresult`) failed with an unexpected test-host exit after approximately 128 seconds; it is not acceptance evidence. A shorter rerun, `scripts/dev.sh test -only-testing:rebindTests/DarkWindowInspectionTests -resultBundlePath build/GeneralDarkWindowSelection.xcresult`, passed: one test, zero failures, 90 seconds.
- The passing live run logged AppKit `Invalid view geometry: width/height is negative` warnings during navigation/resizing. No visible overflow was observed, and the test did not assert these transient geometries. Their cause remains open: isolate the emitting native view/transition before declaring the resize path warning-free.
- The temporary inspection test was removed. `scripts/dev.sh build-for-testing`: `TEST BUILD SUCCEEDED`; Debug and Release executable digests remain exactly those recorded above, and both signatures pass `codesign --verify --deep --strict`. No production or permanent test source changed in this follow-up; the earlier 532-test suite remains the software regression evidence, not a new full-suite run.

No agent commit or Sketch save. Technical records are retained; screenshots, result bundles and raw logs remain ignored local output.

## Remaining limits and next action

Real registration/approval/removal, paused/missing-access relaunch/login, spoken VoiceOver and accessibility preferences remain open. Full production signing/TCC persistence, macOS 26 and Intel execution are not established by universal compilation. Closing/reopening via the real app Menu Bar remains a separate lifecycle check.

Next: isolate the AppKit transition geometry warnings; use the identified bundle for the required General acceptance walkthrough. The prepared Input/hold slice can follow this repair; every added Settings section must include the full-main integration check.

### AppKit diagnostic follow-up — 2026-10-11

The previously open negative-geometry warning is now [isolated to AppKit’s window-sharing indicator during Computer Use inspection](appkit-sharing-indicator.md). No production layout change follows from that diagnostic. Existing geometry/visual evidence remains scoped as recorded; actual restart and accessibility checks remain open.
