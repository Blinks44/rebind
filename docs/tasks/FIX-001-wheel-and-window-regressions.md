# FIX-001: Wheel direction and main-window regressions

- Updated: 2026-10-20
- Stage: awaiting_verification
- Owner: current implementation chat
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
- Window opening waits for `applicationDidBecomeActive`, or opens immediately if already active, after the activation-policy/menu transition. Uses public AppKit activation with all-windows activation rather than assuming a run-loop delay proves activation. Scope of success remains subject to actual Stage Manager verification.

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

## Next

On the next updated installed build, verify only the affected scenarios:

1. With vertical reverse enabled, hold mouse button 5 and use wheel up/down for volume up/down; then check reverse off and ordinary scrolling. Preserve the current rules.
2. Scroll/resize a long rules list and confirm the permanent top gap, stationary rounded card and bottom alignment with the sidebar; check short/search/empty lists and keyboard/VoiceOver reachability of offscreen rows.
3. Open Settings from the menu and Command-comma, and Devices from a battery row: one main window, with the gear visible in the menu.
4. Resize, quit, relaunch in background, then open: remembered size and no automatic startup window.
5. With Stage Manager already enabled, repeat the background-launch → menu Open Rebind path and confirm a frontmost window on the current desktop. Also check closed/minimized window and Dock/Finder reopen.

Record the installed artifact/signer/OS and observed results. Last recorded installed build 3 has not been replaced by this task; software checks do not close the physical/Stage Manager gates.

## Commit handoff

The wheel/window fixes, stationary card, tests, build 5 and agent build-number policy are committed together. Earlier dated no-commit notes describe their verification runs before this handoff. Build/test evidence is unchanged; installed-build/hardware/Stage Manager checks remain open. No publication or push is part of this handoff.
