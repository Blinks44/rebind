# UI-024 — Code and design review after the redesign

- Updated: 2026-10-13
- Stage: done
- Owner: Claude Code chat, 2026-10-13; released
- Ownership checked: 2026-10-13 on `8edd690`
- Owned surfaces: `rebind/UI` (design system and views), `Localizable.xcstrings`, layout tests, **Rebind - new.sketch**
- Requirements: SPEC §10; AGENTS simplicity rules; phase 8
- Code baseline: `main` at `8edd690`; changes uncommitted

## Outcome and scope

Requested before new functionality: make the code and the Sketch file simple, consistent and free of leftovers from the withdrawn design. No behavior, engine or persistence change.

## Implementation and verification

Code:

- Design-system code lives in `rebind/UI/DesignSystem`: `Theme` (tokens), `Controls`, `Buttons`, `Card`, `Banner`, `KeyboardFocusRing`, `MenuSelector` and its helpers.
- Legacy names replaced: `EditorFeedback` → `Banner`, `PermissionCard` → `Card`, `MouseBindingList` → `BindingList`, `PermissionStatusLabel` → `StatusLabel`, `Editor…` selector/picker types lose the prefix. `EditorTypography`, `EditorMetrics`, `EditorSecondaryButton` and `MainSidebarButtonStyle` were deleted in favor of `Theme` and three button helpers (`primaryButton`, `secondaryButton`, `destructiveButton`).
- Every button is styled explicitly; `Banner` and `SettingsActionCard` no longer style their action slot implicitly, so each button has its own keyboard focus ring.
- New shared pieces replaced duplicated code: `ThemeTextField` (search fields, profile name, web address), `OptionsMenu` (row "…" menus), `SegmentedPicker` (activation picker and Settings tabs shared the same 60 lines).
- Remaining default-styled buttons and the bordered URL field in diagnostics, licenses and action parameters use the shared styles.
- 48 unused strings were removed from `Localizable.xcstrings` (433 keys remain).
- The binding editor is 520 pt wide and the setup title uses the 22 pt title, both as drawn in Sketch.

Design:

- All 43 colors in `Theme.swift` were compared with the Sketch variables programmatically: no mismatches.
- Contrast check found Light secondary text at 3.3:1 on the canvas. `Text/Secondary` Light is now 75 % (4.8:1 on canvas, 5.1:1 on cards) in Sketch and code. Tertiary text (placeholders, disabled) stays below 4.5:1 by design.
- Removed from Sketch: 6 unused layer styles, 17 unused text styles and the unused pressed-fill variables. No component is unused.
- Principles board updated for SF Symbols, the titlebar strip, keyboard focus and the editor order. Brand page renamed `04 · Brand`.

Checks, agent-observed on macOS 27.0.1: build succeeds; an uninterrupted full run after the refactor passes 15 XCTest and 663 Swift Testing tests. After that run only the secondary-text opacity and documentation changed; build and `MainWindowLayoutTests` pass on the final code.

## Open checks / dependency

- Sketch's API could not reorder pages; `04 · Brand` sits after `99 · Archive` until dragged manually.
- The app was not launched; visual effect of the contrast change was not seen in a running window.
- `AppModel.swift` (500 lines) and engine code were not part of this review.

## Next handoff

- **Code:** start functionality with the Magic Mouse feasibility check.
- **Design:** draw new screens only alongside the features that need them.
