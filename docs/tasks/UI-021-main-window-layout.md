# UI-021 — Main window layout and raised sidebar

- Updated: 2026-10-12
- Stage: implementing
- Owner: `/root`
- Ownership checked: 2026-10-12, main `8e8a06e`; unrelated Trackpad/catalog changes preserved.
- Owned surfaces: main window scene/shell/sidebar, shared selector optional menu action, Mouse profile-row removal; scoped layout checks and project records. Sketch read-only.
- Requirements: SPEC §§3.3, 10–11, D2; PLAN phase 8.
- Code baseline: main `8e8a06e`; work uncommitted, no agent commit.

## Outcome and scope

Adopt the first live Sketch screen's main-window shell: remove redundant title/toolbar stripe, raised inset sidebar, existing app icon and brand, one shared profile selector above input categories, full-width navigation targets, Settings/About at the bottom. Preserve existing editors, transactional profile switching, protected storage and current input capabilities. Rule-table redesign and Magic Mouse implementation are separate.

## Acceptance

- [ ] Main shell/sidebar matches live Light/Dark/compact design geometry and material direction.
- [x] Profile selection/management are available from the sidebar on every main destination, with no duplicate page picker.
- [x] Enabled navigation rows activate across their entire width, with hover, selected, keyboard-focus and accessible button states (scoped live checks; spoken VoiceOver pending).
- [ ] Debug/signature and meaningful full-window/profile regression checks pass; native screenshots reviewed.
- [ ] Task, STATE and history updated; remaining manual accessibility/platform/user visual checks identified.

## Sketch source

Read-only live `Rebind.sketch`, 2026-10-12: Screens 01/02/03, Settings; shared Light/Dark Navigation states and Profile selector, Foundations 04/14, current Brand. Source ID refreshed through MCP. No Sketch edits or save performed.

## Implementation and verification checkpoint

Main scene uses a hidden titlebar; fixed-width SwiftUI shell with raised native glass sidebar, existing bundle icon, shared profile selector and optional management menu item. Category page pickers removed. Navigation uses full-width native Buttons with selected/hover states and adaptive contrast edges. Short category names use a separate four-language Navigation catalog, preserving the other agent's Localizable changes. Sketch remains untouched.

Agent-observed on Apple Silicon macOS 27.0.1 (26A434), Xcode 27 / Swift 6.4 / SDK 27, uncommitted on `8e8a06e`: initial Debug and scoped layout/profile matrix passed (8 functions; 712 viewports) before titlebar/shell refinements. These results do not certify the final source. Live isolated no-engine review confirmed Light geometry, no title stripe, Settings/Mouse/Trackpad trailing-edge clicks, Tab/Space activation and shared profile-manager opening. Final Dark/compact/VoiceOver/preferences and window controls remain unverified.

Native split containers added titlebar safe-area minimum height and were replaced by a fixed-width HStack. Whole-window sizing now uses public NSWindow integration. A native 72-viewport size check passed before adding the minimum-size assertion; subsequent checks caught SwiftUI overwriting the minimum after resize. Latest resize observation repair is not yet compiled/tested. AX virtual-node inspection failed and was replaced by checks of the native sidebar sizing anchor and scroll-view bounds. Preserve the stricter final checks; do not substitute the initial pass.

On 2026-10-12 the automatic approval reviewer refused further escalated process inspection because its usage limit was reached (review could not complete; not an unsafe-action determination). No bypass attempted. Final build/test/signature and live review require restored approval execution or user-run commands.

## Remaining layout correction

Native window controls still use the standard macOS origin, too near the sidebar's top/left edge. The user requested an explanation before further implementation. Live Screen 01 places the stoplight group at x20/y18; use public AppKit standard window buttons and preserve native behavior, resizing/fullscreen and focus. This remains part of the original layout acceptance.

## Next step

Move native window controls to the live Sketch inset, then build and run the complete final window/profile matrix. Resolve the minimum-size assertion before visual Dark/compact and user handoff. Work remains implementing; no final completion claim or agent commit.
