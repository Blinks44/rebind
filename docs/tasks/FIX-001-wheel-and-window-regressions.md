# FIX-001: Wheel direction and main-window regressions

- Updated: 2026-10-20
- Stage: done
- Owner: unassigned; implementation and scoped tester acceptance complete
- Ownership checked: main `ad412de`, clean checkout; implementation released; scoped review complete
- Owned surfaces: wheel adapter/tap, main window lifecycle/menu/navigation, rules viewport, related tests and records
- Requirements: SPEC §§3.2, 7–8 (wheel, menu, background launch, active Space, resizable window)
- Code baseline: main `ad412de`; implementation, tests and records included together in the wheel/window regression commit

## Outcome and acceptance

- Wheel and held-button wheel rules follow Rebind's configured per-axis reversal, without speed affecting direction or phased touch streams.
- A fixed 24 pt gap remains above a stationary rounded rules card. Rows scroll inside it; short lists fit their rows, and long lists align with the sidebar bottom (8 pt window inset) during scrolling/resizing.
- Menu Settings has a gear and opens Settings inside the main window; battery rows open its Devices section. Command-comma uses the same route.
- Main-window size survives quitting/relaunch while background startup stays suppressed.
- Opening from the menu after background launch presents the main window on the active desktop, including Stage Manager.

## Source and verification

Live Rebind Sketch inspected 2026-10-20: Mouse Light frame 06 and menu frame 53; Mouse header ends at y=180 and list begins y=204. User requests the menu gear and main-window Settings route. No Sketch edits.

Implementation is complete, based on `ad412de`:

- `ScrollEventAdapter` normalizes only direction from the active per-axis adjustment before matching. Original event deltas and output adjustment/smoothing remain separate; speed does not affect matching. `EventTapWorker` supplies the active adjustment. No callback actor hop, I/O or new capture mechanism.
- `BindingsView` places the 24 pt gap outside the card and moves the background/border/rounded clipping to the viewport around the scrolling rows. The existing 72 pt row metric limits short-card height without a separate measurement system; long cards fill the available height, ending at the sidebar’s 8 pt bottom inset.
- Menu and Command-comma send a consumable Settings request to `ContentView`; battery rows select Devices. Removed the separate Settings scene; existing sections/localizations remain shared.
- `MainWindowPersistence` restores/saves the native frame under a stable name, independently of disabled scene restoration/background-launch suppression.
- Build 6 supersedes the activation-gated implementation: scene opening is unconditional after leaving menu tracking; the exact registered main window is deminiaturized/ordered forward and activation is requested. Activation notification only finishes focus, never gates creation. The app-lifetime menu host alone installs the SwiftUI opener; the closing main scene no longer overwrites it.

Native references: [activation options](https://developer.apple.com/documentation/appkit/nsapplication/activationoptions), [cooperative activation](https://developer.apple.com/videos/play/wwdc2023/10054/), and [native frame restoration](https://developer.apple.com/documentation/appkit/nswindow/setframeusingname(_:)). Installed SDK headers confirm activation is asynchronous. Existing native APIs suffice; no dependency or new input/action mechanism.

Checks on 2026-10-20, Xcode 27.1 / SDK 27 / Apple silicon macOS 27.0.1:

- `apps/rebind/scripts/dev.sh build`: initial and final Debug builds succeed. Final app: `apps/rebind/build/DerivedData/Build/Products/Debug/Rebind.app`. Initial sandbox-only attempt could not write standard SwiftPM/Clang caches; authorized normal-cache retry succeeds.
- `apps/rebind/scripts/dev.sh test` selecting `ScrollEventAdapterTests`, `WheelAdjustmentTests`, `ButtonScrollTests`, `ScrollMailboxTests`, `ScrollMatcherTests`, `WindowRegressionTests`, `MenuBarBatteryTests`: **38 functions in seven suites pass**, no skips. Result: `apps/rebind/build/DerivedData/Logs/Test/Test-rebind-2026.10.20_15-26-31-+0300.xcresult` (local ignored output).
- Covers four directions × reverse on/off through actual matcher action selection, independent axes, continuous wheel, phased/diagonal rejection; native window recreation with a unique disposable autosave name; pre-attachment/repeated Settings requests; a 20-rule list scrolled to the bottom with viewport top retained below the header.
- First selected run had two fixture assumptions fail: Input uses segmented controls rather than a native slider, and the list fixture unintentionally showed the paused banner. Corrected those assumptions/setup; final run above passes. No production workaround added for fixture failures.
- Local native snapshot of the scrolled list inspected: gap remains visible above clipped rows. Snapshot has a transparent page background and is evidence for viewport spacing only, not full-window appearance/accessibility parity.
- `git diff --check` passes. Test host never starts capture or loads production configuration. No real rules/permissions, installation, Git commit or Sketch save changed.

Build/test output contains the existing AppIntents metadata warning and a native layout-recursion warning in the Settings host. No assertion/compiler failure remains; this does not claim a warning-free runtime.

Build-number follow-up (2026-10-20): AGENTS and WORKFLOW now require an agent-owned increment for each new app change set. The pending fixes use **1.0.0 (4)** in both Debug and Release, with marketing version unchanged. `apps/rebind/scripts/dev.sh build` succeeds after that metadata change; the 38-function behavioral run above predates the number-only increment and was not rerun. No build-4 package/installation was made by this task. This dated metadata result precedes the build-5 card follow-up below. Documentation links/settings and `git diff --check` reviewed.

## Stationary rules card — 2026-10-20

Latest user direction: preserve all four rounded card corners and scroll only the rows; at capacity, align the card with the sidebar bottom. Live Sketch frame 06 refreshed (Rebind, Sketch 2026.3.1): existing row/corner/short-list geometry reused. No Sketch edit/save. Source is **1.0.0 (5)** in both configurations; no package or installation by this task.

- `dev.sh test` selecting `WindowRegressionTests` and `MouseLayoutTests/testMouseDetailFitsFullMainWindowInAllLanguages`: **3 Swift Testing functions + 1 XCTest function pass**, no skips/failures. The native matrix covers 96 language/appearance/permission/rule-count/size combinations on the updated card implementation. Local result: `Test-rebind-2026.10.20_15-40-36-+0300.xcresult` under the normal DerivedData test logs.
- Final expanded `dev.sh test -only-testing:rebindTests/WindowRegressionTests`: **4 functions pass**, no skips/failures. Added explicit 8 pt bottom bounds, stationary viewport after scrolling, short-list height and full-window resizing across 880×600/1080×720, two/twenty rows and EN Light/RU Dark (eight native viewports). Local result: `Test-rebind-2026.10.20_15-41-30-+0300.xcresult`.
- Full-window local native snapshots reviewed: short Light card, long scrolled Light card and compact long Dark card. Long card’s lower edge matches the sidebar, corners remain visible, rows scroll inside, short card does not fill the page. These isolated fixtures do not prove live VoiceOver, scrollbar-preference or keyboard-focus behavior; generated rule labels follow the test host’s global localization.
- Earlier wheel/window/hardware acceptance remains as recorded; no engine change in this follow-up. `apps/rebind/scripts/dev.sh build` succeeds; the built Info.plist is **1.0.0 (5)**. Affected local links and `git diff --check` pass.

## Repeated menu opening repair and tester report — 2026-10-20

Baseline `9bb23e2`; current uncommitted source **1.0.0 (6)**. User reports the latest wheel/card/settings/geometry checks pass, update preserves working configuration/access, keyboard navigation works, and sleep/pause/permission loss recover correctly. Exact tested installed hash/build/settings are not supplied; retain this as scoped tester evidence, not an agent-observed platform matrix. VoiceOver remains untested. Current Apple Development signing is explicitly retained for further testing; Developer ID is not a prerequisite for that testing. Publication/site work remains deferred.

Repeated Menu Bar Open is still intermittent after the initial open. Code review found two independent defects: a closing scene overwrote the app-lifetime opener, and scene creation depended on an activation notification that is not guaranteed. An isolated background fixture of the old code recorded a show request with inactive app and no subsequent opener/activation message during the failed UI request. That confirms the activation gate can prevent creation; it does not independently prove every tester failure had that cause.

Research: Apple's [OpenWindowAction](https://developer.apple.com/documentation/swiftui/openwindowaction) creates/orders the identified Window; [NSApplication activation](https://developer.apple.com/documentation/appkit/nsapplication/activate()) is a request. [Rectangle AppDelegate](https://github.com/rxhanson/Rectangle/blob/main/Rectangle/AppDelegate.swift) keeps a window controller and calls showWindow with activation rather than waiting for activation; [SettingsWindowController](https://github.com/sindresorhus/Settings/blob/main/Sources/Settings/SettingsWindowController.swift) uses the same native pattern and modern activate on macOS 14+. Current upstream sources inspected 2026-10-20. Settings is MIT; Rectangle was behavioral reference only, no source copied/license adoption. No package installed or dependency needed for existing AppKit operations. Maccy's app delegate also retains its panel, but popup-specific mechanics are not adopted.

Implementation: `MainWindowPresenter` owns the pending scene request and weak main-window reference; `MainWindowRegistration` reports the actual scene window without replacing SwiftUI’s delegate. Menu, Settings and Dock/Finder reopen share this route. Removed main-scene opener and activation-gated closure. A Debug `--window-fixture` exercises real menu/presence/scene behavior with temporary configuration and no engine startup, permissions, login registration or device discovery.

Verification:

- Build 6 Debug build succeeds. `dev.sh test` selecting `MainWindowPresenterTests` + `WindowRegressionTests`: **6 functions pass**, no skips/failures. Local result `Test-rebind-2026.10.20_16-13-46-+0300.xcresult` in normal DerivedData test logs.
- Twelve native close/show cycles succeed with activation deliberately withheld; pending request survives late scene-opener/window registration. Existing geometry/Settings/card tests pass. These tests use native windows but do not automate actual status-menu clicks or Stage Manager.
- Separate ad-hoc UI fixture with a distinct temporary bundle ID: CUA eventually observes actual Rebind main window, sidebar and Settings controls after reopening; response was severely delayed, so repeated native menu/Stage Manager acceptance is **not** claimed. Fixture stopped; installed Rebind unchanged. First temporary copy signing needed deep signing because test plug-ins were present; production signing is unchanged.
- No visual styling, input engine or real rules changed. No install, publication or new Git commit. `git diff --check` passes. Existing test-host layout-recursion/AppIntents warnings remain qualified.

## Stage Manager follow-up / Monny comparison — 2026-10-20

Tester confirms build-6 behavior always creates/shows a window, but approximately half of menu opens immediately put it into Stage Manager's inactive strip. Monny does not exhibit this on the same user's setup. This supersedes any implication that visibility alone accepted foreground behavior.

Read-only comparison of the user-identified Monny checkout: `apps/monny/monny/monnyApp.swift`, `openDashboard` promotes activation policy, leaves menu tracking, calls `NSApp.activate()`, then deminiaturizes/orders its existing dashboard; `openWindow` is used only if no dashboard exists. Rebind build 6 did the reverse ordering, invoked the scene opener on every show, and added an activation-notification second focus path. No Monny files changed or source copied.

Build **1.0.0 (7)** now follows that native ordering: promote policy → next main-loop turn → `NSApp.activate()` → deminiaturize/unhide/order the known main window, or request the scene only if no window exists. Removed all-windows activation and the second activation-observer path. App-lifetime opener and pending cold-start registration remain. This is a code-supported correction of the ordering difference, not proof that Stage Manager's compositor behavior is fixed.

`dev.sh test` with MainWindowPresenterTests + WindowRegressionTests: **6 functions pass**, no failures/skips; local `Test-rebind-2026.10.20_16-29-48-+0300.xcresult`. Twelve close/show cycles verify reuse without any scene-open call for an existing window. Added a further assertion that each activation request precedes window visibility; **2 presenter functions pass**, no skips/failures; local `Test-rebind-2026.10.20_16-30-44-+0300.xcresult`. Native test output includes rendering-fence timeout warnings and the earlier Settings layout warning; no product workaround added. `dev.sh build` succeeds and the built Info.plist reports **1.0.0 (7)**; affected local links and `git diff --check` pass. No installed-app replacement or live Stage Manager claim.

## Scoped acceptance — 2026-10-20

After the build-7 Monny-order follow-up, the tester reports improvement and explicitly accepts closing the window-opening issue for now. Together with the earlier wheel/card/settings/geometry acceptance, this closes FIX-001’s bounded regression scope. Exact installed hash/build, number of cycles and platform/settings matrix are not independently supplied; this is tester acceptance, not a claim of exhaustive Stage Manager verification. No new test/build accompanies this documentation update.

## Next

Continue the release queue with VoiceOver/accessibility preferences and another-Mac/current-signature installation. Do not repeat the accepted window/wheel/card/update/safety checks without a new regression or affected change. If foreground opening recurs, reopen this task with the installed build and reproduction sequence. The opening repair, tests, build 7 and scoped acceptance records are included together in the follow-up commit; publication/site deployment remain deferred.

## Commit handoff

The wheel/window fixes, stationary card, tests, build 5 and agent build-number policy are committed together. Earlier dated no-commit notes describe their verification runs before this handoff. Build/test evidence is unchanged; installed-build/hardware/Stage Manager checks remain open. No publication or push is part of this handoff.
