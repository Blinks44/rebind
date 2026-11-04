# UI-026: Battery indicators at the menu's trailing edge

- Updated: 2026-11-04
- Stage: awaiting_verification
- Owner: Codex, current implementation chat
- Ownership checked: clean `main` at `7425ee5`; scoped ownership active.
- Owned surfaces: MenuBatteryView, MenuBarController battery rows, MenuBarBatteryTests, build version and related records.
- Requirements: SPEC §3 device battery menu and native semantics/accessibility; existing six-language copy preserved.
- Baseline: `main` / `7425ee5`; released in `57018b8`, tag `v1.3.2`.

## Outcome

Match the existing Sketch menu battery indicators more closely: larger secondary SF battery symbols, 8 pt percentage/icon gap, and a shared trailing inset with the pointer-speed values. No discovery, battery-reading, input-engine or configuration changes.

## Source and implementation

Live Rebind.sketch inspected on 2026-11-04: screen 53 Light and its layer tree. Existing battery components use 24 × 16 slots and end at the DPI value/slider edge. Sketch unchanged.

Native attributed titles end before AppKit's reserved shortcut column. A full-width `NSMenuItem.view` supplies the requested edge alignment, retaining the enclosing title/action, exposing a combined accessible menu-item label and press action, and supplying pointer/highlight drawing. Public SDK NSMenuItem.view documentation supports width autoresizing; NSMenuItemBadge supports only strings/counts and cannot carry a battery image. [Apple view contract](https://developer.apple.com/documentation/appkit/nsmenuitem/view). The older archive’s keyboard-event restriction differs from the current SDK header. The view accepts first responder only while selected and handles Return/Space/keypad Enter; the menu delegate supplies keyboard highlight state.

## Verification and next action

Agent-observed on macOS 27 / Xcode 27.1:

- Targeted `dev.sh test` for MenuBarBatteryTests and MenuSettingsVisualProbeTests: four test functions pass (two parameterized across all six languages). Covers long localized names, growth by 120 pt, trailing inset, combined accessible label, enabled action and disabled rejection. Initial assertions used frame edges instead of AppKit text-field alignment rectangles; corrected to compare alignment rectangles.
- Isolated AppKit probe using the production MenuBatteryView (fixture battery/localization inputs only): Light/Dark normal and charging rows rendered and visually inspected. Larger secondary symbols and right alignment match the intended source geometry. No real configuration, discovery or input capture.
- Native popup probe: type-select reaches G915 TKL; Enter fires the fixture action exactly once after enabling first-responder acceptance and explicit activation handling. Arrow navigation also reaches the row. This proves the isolated current-OS route, not installed-app or VoiceOver acceptance.
- Final `dev.sh build`: pass, 1.3.1 (39). Signed `release.sh` packaging passes: `apps/rebind/build/release/Rebind.dmg`, app deep/strict signature, DMG strict signature and `hdiutil verify`. SHA-256: `3dbe85eff5df9f027ba7794f462233e5a43c9fb0e1386b183c5d02707623e21a`. Signed with the existing identity; no installation or publication.

Tester report, 2026-11-04: the result is accepted; exact installed build and keyboard/VoiceOver coverage were not specified. Included in release candidate 1.3.2 (41), [REL-010](REL-010-release-1.3.2.md).

## 2026-11-04: Initial selection regression

Tester reports that opening the 1.3.2 status menu highlights G915 TKL before pointer movement. Cause: unconditional `acceptsFirstResponder` makes AppKit select the first focusable custom row during initial menu setup. Build 42 accepts focus only after the row is highlighted and explicitly transfers focus when selected, preserving Return activation. Scope: MenuBatteryView, its regression test and build number; baseline `e43c8fb`, committed as `aac69f6`. No Sketch geometry/copy changes.

Isolated native popup probe on macOS 27: initial `menu.highlightedItem == nil` and row highlight false; type-select then Return invokes the fixture action exactly once. Final `dev.sh build` and targeted `dev.sh test` pass: five functions in two suites, including six-language cases and the new focus regression. Signed `release.sh` packaging passes: app/DMG signatures and image verification; local `apps/rebind/build/release/Rebind.dmg`, 1.3.2 (42), SHA-256 `170b3a3f2ddd7aaaaeff03fbc32675995e8d9658439cbec33ebc21b745999e85`. Published as the replacement v1.3.2 build under explicit maintainer authorization ([REL-010](REL-010-release-1.3.2.md)); not installed by the agent. This replaces the earlier incomplete opening-state verification; it does not establish installed status-item or VoiceOver acceptance.

## Open checks and next action

On 1.3.2 (42), first confirm opening the status menu leaves battery rows unselected before pointer/keyboard movement, then complete the remaining status-menu checks: compare battery/DPI trailing edges; hover/click a battery row; use arrows and Enter to open Devices; use VoiceOver to hear each device/charge once and activate it. Expected: one Devices transition per activation, readable highlighted text, complete charging/low-charge state. Check Light/Dark and Increase Contrast. macOS 15/26 remain unverified. No hardware-reading behavior changed; regression risk is limited to custom menu-row sizing, highlight and activation/accessibility.

Ownership: implementation and packaging complete; released for installed verification. Sketch was unchanged for the battery-menu correction.
