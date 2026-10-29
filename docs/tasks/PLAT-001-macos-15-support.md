# PLAT-001: Run Rebind on macOS 15

- Updated: 2026-10-29
- Stage: awaiting_verification (UI and rules tester-confirmed on 15; touch input open)
- Owner: unassigned (implementation chat released)
- Ownership checked: 2026-10-29, released
- Owned surfaces: Xcode deployment target, `ContentView` toolbar, `InputDiagnostics`, private-API version gates, platform lines in AGENTS/SPEC/ENGINEERING/DEVELOPMENT/PLAN
- Requirements: SPEC header (platform), PLAN release gate "Platforms"
- Code baseline: `main` at `854e8eb`, uncommitted

## Outcome and scope

User request 2026-10-29: lower the minimum from macOS 26 to macOS 15, which still has a large installed base. Same app, no separate code paths beyond availability guards. The public README, website (six locales and `seo.ts`) and release notes still say macOS 26 because the published 1.2.0 requires it; change them together with the first release built from this source.

## Acceptance

- [x] `MACOSX_DEPLOYMENT_TARGET = 15.0` for Debug and Release; app and tests build without warnings; `LSMinimumSystemVersion` becomes 15.0.
- [x] No macOS 26-only API without a guard; SF Symbols used by the app exist on macOS 12 or earlier (checked against the system `name_availability.plist`).
- [x] Launch, first run, permissions, main window/sidebar/toolbar appearance and Settings on macOS 15 (tester, build 35, VM; menu bar/Sparkle not itemized).
- [ ] Keyboard and mouse rules, window/Space/media/system actions and Lock Screen on macOS 15. Rules generally work (tester, build 35; e.g. mouse button 3 → Minimize Front Window); individual actions and Lock Screen not itemized.
- [ ] Trackpad and Magic Mouse gestures on a real Mac with macOS 15 (multitouch does not reach a VM).
- [x] README, website and release notes switched to macOS 15 for 1.3.0 ([REL-008](REL-008-release-1.3.0.md)).

## Implementation and verification

A trial build with the target lowered showed exactly two macOS 26 APIs:

- `InlineArray` in `Engine/InputDiagnostics.swift` is replaced by an `Array` allocated once with 128 slots. `snapshot()` copies entries into a new array, so the ring stays uniquely owned and the callback's slot write never copies.
- `ToolbarItem.sharedBackgroundVisibility(.hidden)` in `ContentView.swift` is applied under `if #available(macOS 26, *)`; macOS 15 has no shared toolbar glass to hide.

Runtime gates found by reading the code: `NativeTrackpadDevice` (MultitouchSupport, used by trackpads and Magic Mouse) and `ScreenLockExecutor` (`SACLockScreenImmediate`) accepted only majors 26–27, so touch input and Lock Screen would have been silently unavailable on 15. Both now accept 15–27. Both private entry points are long-standing and used on macOS 15 by MiddleClick/Hammerspoon; this widens a compatibility gate, it is not evidence they work. Other private calls (`CoreDockSendNotification`, attached-HID scroll) have no version gate. Open Apps already hides itself when `/System/Applications/Apps.app` is missing; window layout uses Accessibility geometry, not the system tiling menu.

Window chrome differs on 15 (no Liquid Glass sidebar/toolbar); the design is opaque-first, but the titlebar strip, window-button placement and sidebar material need a visual check.

Build 34. Debug build and full test suite on macOS 27.2 (Apple silicon): see [INPUT-016](INPUT-016-magic-mouse-side-taps.md#implementation-and-verification) for the shared run. No macOS 15 execution yet.

## Tester report and fix, build 35 (2026-10-29)

Tester, build 34 in a macOS 15.6.1 VM: the app crashed on every toggle. Crash report: `EXC_BREAKPOINT` on SwiftUI's display-link thread in `dispatch_assert_queue` from `swift_task_isCurrentExecutor`, inside the `NSColor(name:dynamicProvider:)` closure of `Color(light:dark:)` (`UI/DesignSystem/Theme.swift`). The app target's default main-actor isolation made the provider a main-actor closure; macOS 15 SwiftUI resolves it off the main thread during the toggle animation and the Swift 6 runtime check traps. macOS 26+ did not hit it. Fix: the initializer is `nonisolated` (the provider only does arithmetic on captured values). `ThemeColorTests` resolves a theme color from a detached task: it crashes the test host without the fix and passes with it. No other dynamic AppKit providers exist in the app.

Tester follow-up, build 35 in the macOS 15.6.1 VM (2026-10-29): toggles no longer crash; the app and rules generally work. Screenshots of Mouse, Settings → General and Devices match the macOS 27 layout: sidebar panel with window buttons inside it, toolbar strip, cards and toggles render correctly. Which actions, menu bar items and Sparkle check were exercised was not itemized.

## Next handoff

Tester: optionally check Lock Screen, the menu bar menu and Check for Updates in the macOS 15 VM. Touch gestures need a real Mac on 15 when one is available. Release agent: switch README, website and release notes to macOS 15 with the next published version.
