# UI-025: Move Devices into the main window

- Updated: 2026-10-29
- Stage: done
- Owner: none; released in 1.2.0 (33) ([REL-007](REL-007-release-1.2.0.md))
- Ownership checked: main 6577b19
- Owned surfaces: sidebar, Devices page, Settings tabs (General/Input/Devices), affected strings in six languages
- Requirements: SPEC §10 information architecture and key screens, §3.2 mouse settings; user decision 2026-10-28

## Outcome

Settings keeps only app configuration. Connected hardware becomes main-window content: the sidebar shows the five rule categories, a hairline, then **Devices** (⌘6). The Input tab is retired: mouse wheel and gesture distance move to an always-present **All mice** card at the top of Devices; Excluded Apps moves to the end of General. Settings has four tabs: General, Permissions, Language, Advanced. Rules stay category-wide; Devices never holds rules.

## Design source

Rebind.sketch, saved 2026-10-28, SHA-256 `1dbbeabdce06d9883e21828cfdc78f28344965fb9cc475a4cf4eaa1acab05e08`; pre-change copy `Rebind (before devices move 2026-10-28).sketch` beside it.

- Every sidebar on 01 · Screens has the Devices item (new `Icon/cable.connector`, exported with `sf-symbol-svg.swift`) below a hairline.
- Screens **35–42** and **66–69** are renamed `Main · Devices`: large title and description, All mice card, then notices and device cards; Devices is selected in the sidebar. Screen 36 also fixes the battery label that overlapped the Rename button.
- Settings **31–32, 43–45** show four tabs; **31** adds the Excluded Apps card before the quit guidance.
- Former **33–34** (Input) are archived on 99 · Archive.
- Foundations **14 · Devices in the main window** owns navigation, page order, Settings scope and native acceptance.

All changed Light/Dark contexts were screenshot-reviewed through MCP. Prototype links did not reference the moved screens.

## Implementation (build 1.1.0 (32), 2026-10-28)

`MainDestination.devices` with sidebar row (⌘6, focus index 5, `cable.connector`) below a hairline; `SettingsSection` is General/Permissions/Language/Advanced. `DevicesView` (former `DevicesSettingsView`) has a fixed large-title header like the rule pages and a scrolling body that starts with `AllMiceCard` (former `InputSettingsView`). `ExcludedApplicationsCard` sits at the end of General before the quit guidance. Menu/command routing uses `AppModel.requestedDestination`; battery rows in the menu open Devices. Strings: reused `allMice`, added `allMiceDescription` and `mouseGestureDistance` in six languages, removed the retired Input strings.

Checks: `dev.sh build` passes. Affected native tests pass (navigation incl. ⌘6, Devices and Language in all locales/themes, main-window settings/devices fixtures, keyboard lighting and battery layouts, Advanced, menu route); the two physical-Tab tests skip as before. A rendered Russian Devices page matches Sketch screen 38.

Full suite: 966 Swift Testing tests in 148 suites pass; 29 XCTest methods, 2 physical-Tab skips, 0 failures. `release.sh` signed and verified `apps/rebind/build/release/Rebind.dmg` 1.1.0 (32), SHA-256 `fc3050aa478dd6823d38d0cb16fa9ceb4e6592c5d61bcef39397ac345b6b1d07` (not installed or published).

## Acceptance

The user installed 1.2.0 (33) and reported on 2026-10-29 that everything checked works. VoiceOver reading was not reported separately and stays under the general accessibility gate in [PLAN](../PLAN.md#release-gates); localized widths are covered by the six-language layout tests above.

The website device screenshots were re-exported with the new sidebar item ([WEB-002](WEB-002-website-refresh.md)).
