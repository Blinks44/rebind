# AppKit negative geometry isolation — 2026-10-11

## Outcome

The observed `Invalid view geometry: width/height is negative` warnings originate in AppKit's window-sharing title-bar indicator during Computer Use inspection, rather than Rebind's Settings layout. No production geometry workaround is warranted by this evidence. Keep the existing full-main overflow repair; do not hide logs or change input behavior to suppress a system diagnostic.

Baseline: `main` / `b453d8d` plus existing uncommitted General/Input/Language refinements. Apple Silicon, macOS **27.0.1 (26A434)**, Xcode **27.0 (27A266a)**, Swift **6.4**, SDK **27.0**. This isolates the warning on this host; minimum-OS/Intel or other production warnings remain separate.

## Method and results

A temporary XCTest hosted the actual ContentView using isolated temporary JSON, injected missing permissions/login state, Russian locale and Dark appearance. It never called AppModel.start(), loaded user settings or activated remappings/login/permission controls. Computer Use inspected General → Permissions → keyboard rules → General; native controls remained visible.

For diagnosis only, the fixture temporarily intercepted public NSView frame/bounds setters through the Objective-C runtime and printed safe fixture-only class/size/call stacks. It did not call any private selectors. Hooks were restored at test completion; the entire investigation source was removed before final software verification.

The warning-associated size is **(-1, -1)** on **NSWindowSharingSessionRecipientIndicator**. The captured AppKit call chain is:

```text
NSView.setFrameSize
NSThemeFrame._positionSharingIndicator
NSWindowSharingSessionRecipientIndicator.invalidateIntrinsicContentSize
NSView._viewDidChangeAppearance
NSThemeFrame._updateButtons
NSWindow._updateButtonsForWindowSharingSession
NSWindow._setIsSelectivelyShared
_windowSelectiveSharingStateChangedNotification
SkyLight sharing notification / main run loop
```

Other occurrences use NSThemeFrame.layout after the same sharing indicator is installed. All 42 AppKit negative-geometry log entries in the traced run correspond to 21 negative sharing-indicator setter calls. Startup NSTextField title sizing also briefly proposed a negative width, but did not emit this diagnostic; it is distinct.

Actual commands (all via scripts/dev.sh):

- `test -only-testing:rebindTests/GeometryInvestigationTests -resultBundlePath build/AppKitGeometryBaseline3.xcresult`: **1 test passed**, no Computer Use inspection, **0** AppKit negative-geometry warnings.
- `test -only-testing:rebindTests/GeometryInvestigationTests -resultBundlePath build/AppKitGeometryInteractive.xcresult`: **1 test passed**, Computer Use transitions inspected, **60** AppKit negative-geometry warnings.
- `test -only-testing:rebindTests/GeometryInvestigationTests -resultBundlePath build/AppKitGeometryStack.xcresult`: **1 test passed**, traced Computer Use inspection, **42** warnings, all attributed above.
- `test -only-testing:rebindTests/GeometryInvestigationTests -resultBundlePath build/AppKitGeometryStack2.xcresult`: **1 test passed**, same traced actual-main fixture without inspection, **0** warnings.
- Plain-control attempts (`AppKitGeometryPlainControl[2].xcresult`) passed with no warnings; later Computer Use requests timed out. These attempts do **not** establish a successful inspected plain-window control and are not needed for the captured stack attribution.

An initial fixture compilation failed due to an optional Selector; corrected before these runs. A sandboxed runner attempt could not connect to testmanagerd; subsequent authorized Xcode test runs executed outside that restriction. Existing linkd/AppIntents messages are unrelated. Raw logs and xcresults remain ignored local outputs; the meaningful evidence is retained here.

## Decision and remaining checks

The isolated issue belongs to the OS sharing indicator. Rebind's controls were not the emitting view. No private AppKit patch, screenshot restriction, sharing disablement, or production method interception was introduced. [Apple's NSWindow.SharingType documentation](https://developer.apple.com/documentation/appkit/nswindow/sharingtype-swift.enum) also describes `.none` as a legacy unused constant; it is not an appropriate current workaround.

No Apple bug submission was made and no universal OS defect claim is implied. If a warning occurs during ordinary use without inspection/sharing, capture that reproduction separately. User-led production restart/login/language checks and VoiceOver remain open. Continue Advanced storage/UI work without treating this system diagnostic as a native layout regression.
