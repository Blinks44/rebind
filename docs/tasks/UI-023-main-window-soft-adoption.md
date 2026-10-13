# UI-023 — Main window in the soft design system

- Updated: 2026-10-13
- Stage: awaiting_verification
- Owner: Claude Code chat, 2026-10-13; released at handoff
- Ownership checked: 2026-10-13 on `ca02747`; advisory coordination, not a lock
- Owned surfaces: `apps/rebind/rebind/UI/Theme.swift`, `ThemeControls.swift`, `BindingsView.swift`, `BindingRow.swift`, `MainSidebar*.swift`, `ContentView.swift`, main-window layout tests
- Requirements: SPEC §§4, 10; phase 8
- Code baseline: `main` at `ca02747`; all changes uncommitted

## Outcome and scope

Trial native adoption of Sketch screen **01 · Main · Keyboard** from [UI-022](UI-022-soft-design-system.md), requested as the go/no-go check for the new direction. The same list view now serves Keyboard, Mouse and Trackpad. Editors, Settings, onboarding, profiles and About keep their previous appearance. No engine, persistence or matching behavior changed.

## Acceptance

- [x] Window shell, sidebar, header, profile/status row and rules card follow the Sketch geometry, type and colors in Light and Dark.
- [x] Existing behavior kept: add/edit/delete, per-rule switch, profile selection and management, pause/resume, permission notice, search.
- [x] Debug build and affected layout tests pass.
- [x] User ran the app and accepted the direction (2026-10-13); follow-up requests are recorded below.
- [ ] Keyboard focus, VoiceOver, Increase Contrast and RU/DE/FR at minimum width reviewed in the running app.

## Implementation and verification

- `Theme.swift`: adaptive colors, type and geometry copied from the Sketch variables; `ThemeCanvas`, `ControlSurface`.
- `ThemeControls.swift`: `Keycap`, `TriggerChip`, `ActionTile`, `PrimaryButtonStyle`, `ThemeSwitchStyle`, `StatusPill`.
- `BindingsView.swift` + `BindingRow.swift` replace the inline Keyboard/Trackpad list and `MouseBindingsView`/`MouseBindingRow` (deleted).
- Sidebar: no logo or profile selector; 240 pt column, 14 pt selection radius; window buttons centered 28 pt from the leading/top edges.
- Default window 1080 × 720; minimum 880 × 600 unchanged.
- Added `ActionKind.symbol`, seven strings in EN/RU/DE/FR; removed six unused navigation colors and the sidebar logo asset.

Decisions:

- The status capsule is a button: it pauses/resumes, or opens Permissions when access is missing. The emergency-pause hint moved to its tooltip.
- Development hints and the diagnostics shortcut left the list footer; diagnostics remains in Settings → Advanced.
- Magic Mouse stays a disabled sidebar item because no such scope exists yet.
- Count text reuses the existing plural strings ("7 bindings, 6 enabled"); Sketch says "6 on".
- The Trackpad sidebar symbol stays `rectangle.and.hand.point.up.left`; no SF Symbol matches the Sketch drawing.
- Non-press activation is appended to the row caption ("Keyboard · Double Press"); Sketch does not show this case yet.

Checks, 2026-10-13, macOS 27.0.1, Xcode 27, agent-observed:

- `apps/rebind/scripts/dev.sh build`: succeeded.
- `MainWindowLayoutTests/testKeyboardScreenRendersAtSketchSize` (new): passes; renders 1080 × 720 Light/Dark with seven fixture rules. Compared by eye with the Sketch frame: sidebar, header, row pitch 72, arrow/tile/switch/menu columns match within about 1 pt.
- Full `apps/rebind/scripts/dev.sh test` after the final code and asset changes: 15 XCTest layout tests and 663 Swift Testing tests in 90 suites pass, zero failures.

## Follow-up 2026-10-13

Requested after the first review and integrated:

- **Window buttons no longer jump on resize.** The custom repositioning was removed; an empty unified toolbar gives the window a tall titlebar and macOS places the buttons itself.
- **Brand row** (app icon + name) between the window buttons and navigation; it shows the running app's own icon.
- **New app icon and Menu Bar template** in the soft style; see [brand README](../DESIGN.md#brand).
- **Binding editor restyled** with the same tokens: one layout for all three categories, keycaps in capture fields, segmented activation, banner-style feedback, primary/secondary capsule buttons. The Keyboard editor now uses the shared capture field; its separate Clear button and listening row were removed. `EditorGlassSurface`, `BindingEditorSection` and the preview specimen file were deleted.
- Settings tabs and selectors pick up the new surfaces through the shared controls; the Settings pages themselves are not restyled yet.

Checks: build succeeds; `testKeyboardScreensRenderAtSketchSize` and `testLocalizedMouseEditorsFitCompactNativeWindows` pass and their Light/Dark renders were reviewed; full-suite result in Review. The rendered `AppIcon.icns` from the Debug build was inspected. A second app instance was started once by mistake while the user's own build was running and was quit immediately; the app is not launched by the agent any more.

## Follow-up 2 — 2026-10-13

User review of the running app reported outlines on controls after mouse clicks, a stale app icon and an unstyled action picker.

- **Focus:** `KeyboardFocusRing.swift` replaces the system focus effect on themed controls with an accent outline shown only while focus is keyboard-driven (a local monitor notes key-down versus mouse-down; no key content is read). The sidebar buttons no longer force click focus. Text fields show an accent border instead of the system ring.
- **Action picker:** now a 360 × 420 popover anchored to the selector, with a themed search field, category labels, action tiles, hover and a checkmark. Return picks the first available match.
- **Icon:** the user's Xcode build already contained the new icon; the stale image came from the system icon cache. The bundle was re-registered and `iconservicesagent`/Dock were restarted.

Checks: build succeeds. The full suite failed once without a captured cause and passed on the immediate re-run (15 XCTest + 663 Swift Testing); the first failure was not diagnosed and may recur. Keyboard-only focus behavior and the popover were not seen in a running app by the agent.

## Follow-up 3 — 2026-10-13

- **Icon is full-bleed.** The user found the keycap-on-a-light-tile icon too small in the Dock and sidebar. The icon is now the keycap itself: deep-blue fill, lighter top face, larger arrows. Rendered `AppIcon.icns` inspected; Sketch `05 · Brand` updated.
- **Toolbar approach withdrawn.** The empty unified toolbar overlapped the header (controls start 36 pt from the top, the bar is 52 pt), and the user reported damaged top borders on the search field. The window is `hiddenTitleBar` again. The link between the toolbar and the border defect is the agent's inference, not a confirmed cause.
- **Window buttons are pinned synchronously.** macOS has no placement API and restores its own position on every titlebar layout. `MainWindowSizingView` now listens to each button's frame-change notification and moves it back in the same pass, instead of correcting one run loop later (the earlier cause of jumping). Native placement would put the buttons on the sidebar panel's rounded corner (measured: close button at 9, 9).
- Sketch traffic lights use the native 14 pt size and 23 pt pitch.

Checks: build succeeds; `MainWindowLayoutTests` passed three consecutive isolated runs, including the 28 pt button-center assertion. Two of four full-suite runs today ended with "Restarting after unexpected exit" inside `testSettingsDoesNotExpandNavigationBeyondTheWindow`, with no crash report and no failed assertion; the other two passed all 15 + 663 tests. The cause is unknown; an earlier intermittent Settings runner exit is noted in history. Resize behavior and the search-field border were not seen in a running app by the agent.

## Follow-up 4 — 2026-10-13

User review found that the zoom button drifted away during resize and the search-field outline still lost its top or bottom edge, swapping when the app lost focus; the empty state collapsed into a narrow column.

- **Manual window-button placement removed for good.** Pinning the buttons from frame notifications still fought AppKit. The window uses the unified toolbar style again with one empty item, so macOS owns button placement. Because that strip is 52 pt tall, the detail header now starts 56 pt from the top (Sketch screens shifted to match). This supersedes Follow-up 3's "toolbar withdrawn".
- **The earlier toolbar diagnosis was wrong.** The outline defect persisted without the toolbar. Its cause is still not identified. Two changes target it: `ControlSurface` now draws a single border (hairline or focus accent) instead of two stacked strokes, and draws it inside a layer 2 pt larger than the control so the stroke cannot sit on a clipped layer edge. Whether this fixes it is unverified.
- **Empty state:** an empty `ScrollView` collapsed to its content width and squeezed the overlay; it now fills the detail. Rendered Light/Dark and reviewed.
- **Permission notice** uses the shared warning banner instead of the old card.

Checks: build succeeds; `MainWindowLayoutTests` (3 tests) pass; empty-state and Keyboard renders reviewed. Full suite not re-run after this follow-up. Window-button behavior and the outline were not seen in a running app by the agent.

## Follow-up 5 — 2026-10-13

The search-field outline was still broken after Follow-up 4, so that fix did not work. The defect was then reproduced in a test window by making the field first responder: the default continuous `Capsule()` draws a malformed outline on macOS 27.0.1 (extra end ticks at 1x; the user sees a missing top or bottom edge at 2x). The same artifact appeared on the primary button's hairline. All capsule shapes in the app now use `Capsule(style: .circular)`, after which the reproduced outline renders cleanly. `ControlSurface` keeps fill and border as one shape.

Checks: build succeeds; focused-field render reviewed before and after in Light/Dark. `MainWindowLayoutTests` passed two of three runs; the third ended with the same "unexpected exit" and no crash report. The exits coincide with the user relaunching their own debug build of the same bundle, which is a plausible but unconfirmed cause. The fix was not seen in the running app by the agent.

## Follow-up 6 — 2026-10-13: Settings

- All five Settings tabs, the permission cards, the first-run setup, About and the hold-duration card now use the design system through the shared primitives: `PermissionCard` is the raised 22 pt card (tinted when it carries a severity), switches use `ThemeSwitchStyle` with their labels, prominent buttons use `PrimaryButtonStyle` (28 pt with `.controlSize(.small)`), text uses the `Theme` type scale and colors, and `ThemeCanvas` replaces `PermissionCanvas`.
- Settings content aligns with the main detail (32 pt leading, 40 pt trailing, below the titlebar strip).
- 24 unused color assets and `PermissionCanvas.swift` were deleted; the asset catalog now holds only the accent color and the Menu Bar template.
- Sketch gained screens 13–15 (Settings Input, Language, Advanced) in Light and Dark.

Known differences from Sketch: the native Advanced tab still stacks buttons under each description, while Sketch shows one row per action with a trailing button; Input and Language keep their native headings above the cards.

Checks: build succeeds. Main-window, Permission and General layout tests pass; Russian Light/Dark renders of General, Permissions, Language and Advanced were reviewed. A full-suite run reported all 663 Swift Testing tests passing but three "unexpected exit" restarts of the XCTest host between test classes; each affected class passes when run alone. No crash report or log entry was found. Resolved the same day: the user had been closing the test host window, taking it for a hung app. An uninterrupted full run on the final code passes 15 XCTest and 663 Swift Testing tests with no restarts.

Still open from the user's review: the search-field focus outline improved with circular capsules but still shows a defect.

## Follow-up 7 — 2026-10-13: remaining surfaces

- **Advanced** rows now show the title and description with their actions trailing (stacked when space is short), matching Sketch apart from Export and Import sharing one row.
- **Profile manager** rebuilt as a sheet with one card of profile rows (tile, name, count, Active mark or Select, options menu) and a footer; the **profile-name sheet** has a themed field and primary/secondary buttons, and Return saves.
- **First-run setup** and **About** use the sheet surface and themed buttons.
- Sketch gained screens 16–18 (Profiles, first-run setup, About). The app-icon component is drawn as paths so it scales cleanly and now also serves as the in-app logo.
- The render test now attaches the profile, setup and About sheets alongside the main window and editor.

Checks: build succeeds; an uninterrupted full run passes 15 XCTest and 663 Swift Testing tests. Light/Dark renders of the profile manager, setup and About were reviewed. None of these surfaces was seen in the running app by the agent.

## Follow-up 8 — 2026-10-13: design and app reconciled

Requested: bring Sketch and the app into agreement before new functionality. Each difference was resolved toward whichever side was better.

App moved to Sketch:

- Rules list shows a neutral "paused" banner with a resume button, and an information banner about system gestures on Trackpad.
- Binding editor: profile-and-scope caption for Keyboard (new string `keyboardEditorScope`, four languages), recording limits moved under the capture field, and a Delete Binding button with confirmation when editing.
- First-run setup: warning or success banner, access buttons and steps, then one card listing the other permissions.

Sketch moved to the app:

- Editor sheets: titles Add/Edit Binding with a scope caption, no close button, "Activation" label, Save Binding/Delete Binding; capture-field components show the Record Trigger and Cancel Recording buttons and the empty text.
- Settings General and Permissions redrawn to the app's structure (status heading, one card per setting or permission; no "Active profile" row). Input and Language gained their section heading; Advanced shows one card per action group with Export and Import together.
- Counts read "N bindings, N enabled"; the paused banner button reads "Enable Bindings"; the Trackpad banner has no action.

Deliberately not reconciled: the Trackpad gesture selector stays a native menu (Sketch shows a drawing of it); Sketch still shows planned gestures the engine does not have (three-finger click, corner taps, mouse double-click) and an active Magic Mouse section; the action picker has no per-action captions because those strings do not exist.

Checks: build succeeds; an uninterrupted full run passes 15 XCTest and 663 Swift Testing tests; the Keyboard editor render and the revised Sketch editor and Permissions frames were reviewed. Not seen in the running app by the agent.

## Follow-up 9 — 2026-10-13: larger sidebar brand

User request: the sidebar logo and app name read too close to body text. Tried 40 pt / Title Small first; the user chose the larger step. The brand row now uses a 44 pt icon and the **Title** style (22 pt Semibold) with a 12 pt gap; the row starts 50 pt from the top so navigation keeps its position. All 50 sidebar screens (Light and Dark) in Sketch were updated and the document saved; `MainSidebar.swift` mirrors the values.

Checks: build succeeds; `MainWindowLayoutTests` (3 tests) pass; the Light 1080 × 720 render was compared by eye with Sketch screen 01. Not seen in the running app by the agent.

## Follow-up 10 — 2026-10-13: field outline cause found

The uneven focus outline was reproduced in an on-screen test window on the user's 1x display (2560 × 1440) and measured by pixel: a 1.5 pt `strokeBorder` renders 1 px on the top edge and 1.5 px on the bottom and sides. Any fractional pixel width shows the same loss; whole-pixel widths are even. The capsule style, clipping and layer size targeted in Follow-ups 4–5 were not the cause.

`Theme.accentBorderWidth(displayScale:)` snaps the 1.5 pt accent border to whole device pixels (2 px at 1x, 3 px = 1.5 pt at 2x). `ControlSurface` (text fields) and `BindingCaptureField` (listening state) use it; no other fractional stroke widths exist in the app.

Checks: build succeeds; the full suite passes (699 Swift Testing tests, XCTest host succeeded); the test-window capture shows 2 px on every edge after the change. Measured at 1x only; the 2x path is unchanged arithmetic and was not captured. Why the top/bottom loss appeared to swap when the app lost focus was not reproduced. Not seen in the running app by the agent; the user confirmed the outline is even in the running app on the 1x display the same day.

## Open checks / dependency

- The offscreen `cacheDisplay` capture draws shadow offsets upward, so shadow direction, keycap ledge and button glow were not verified by image. They need a look in the running app.
- The real app was not launched; nothing was checked with the user's configuration, live window chrome or traffic-light position on screen.
- Hover, pressed and focus states, the switch animation, native menu placement and long RU/DE/FR titles at 880 pt are unreviewed.
- Tasks that adopted UI-011 glass (UI-016, UI-017, UI-019) still show the old materials next to this window.

## Review

Final diff reviewed against the Sketch frame and the acceptance list. The layout assertions were updated for the 240 pt sidebar column and the 28 pt window-button center. After the 2026-10-13 follow-up the full suite was run again on the final code: 15 XCTest layout tests and 663 Swift Testing tests in 90 suites pass. Only documentation changed after that run. Open items are listed above; none is hidden behind a passing test.

## Next handoff

- **User:** run `apps/rebind/scripts/dev.sh run`, compare with Sketch screen 01 in Light and Dark, and report differences.
- **Code:** restyle Settings pages, the action picker sheet, hold-duration card, onboarding, profiles and About with the same `Theme` components; reconcile the permission banner with the Sketch Banner.
- **Design:** continue UI-022's remaining screens.
