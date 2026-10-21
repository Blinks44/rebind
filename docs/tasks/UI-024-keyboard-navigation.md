# UI-024: Restore keyboard navigation through shared controls

- Updated: 2026-10-20
- Stage: awaiting_verification
- Owner: Unassigned; grouping/profile continuation verified, remaining normal-build accessibility checks indexed below.
- Ownership checked: main e070ec9; preserve touch and parallel signing work
- Owned surfaces: shared focus ring/menu/segmented controls, main focus regions, affected native tests and handoff records
- Requirements: SPEC §§10–11, keyboard-only navigation; user reports widespread navigation failure

## Outcome

Restore predictable focus and keyboard operation without changing system keyboard settings or replacing native menu tracking. Diagnose shared control ownership before individual-screen patches. Keep visual direction and input engine unchanged.

## Findings and acceptance

- Shared focus-ring decoration installs a second FocusState binding on controls that already own focus (anchored menus and segmented controls). Use their existing focus state for decoration instead of replacing it.
- Verify native focus routing, arrow/Space activation and restoration separately from layout tests.
- Keep macOS Keyboard navigation preference behavior explicit; do not silently change it.
- User confirmation, full-window traversal and VoiceOver remain runtime acceptance.

## Implementation and checks

Uncommitted on main e070ec9. The earlier competing-focus-binding repair and sidebar shortcuts remain. The user subsequently reported no usable sidebar/Settings traversal; the earlier programmatic focus/key-equivalent tests did not prove Tab traversal.

Custom buttons now explicitly participate in editing focus, which is reachable through Tab independently of macOS's activation-only Keyboard navigation preference. A shared primitive style retains native pointer, shortcut and accessibility activation and handles Space once. It covers primary/secondary/destructive buttons, switches, anchored selectors, clear/status/banner and action-picker buttons. Sidebar rows and segments own their focus directly. Disabled controls remain inactive. Existing focus owners supply decoration without a second binding; system preferences are unchanged.

A Debug-only `--keyboard-fixture` (removed 2026-10-21 as redundant with `--application-fixture`; see Git history) launched the actual shared controls in a real app window without loading configuration, starting input capture or executing output actions. Live CUA verification on the isolated Debug artifact: sidebar Down + Space selects Mouse; Tab traverses sidebar into Settings; Right selects Permissions then Input; Tab reaches search, switch and primary action; Space toggles the switch and increments the action counter exactly once; Shift-Tab returns to the switch. The anchored selector opens with Down, Escape returns focus, Space reopens, Down/Return selects Permissions and restores selector focus. AX representation of segments/switches can omit the focused-element line while their real keyboard behavior works; selected values were checked explicitly. No real configuration/rule/permission change or remapping.

The native focus and Command-2/5 regression tests pass. Two newly added physical-Tab XCTest methods explicitly skip when the runner cannot become active/key; initial failures occurred with `NSApp.isActive == false` and `window.isKeyWindow == false`, so they are not accepted as evidence of production traversal failure or success. Live-window evidence above covers those paths. The isolated Debug build passes. Final focused run: **4 native tests pass, 2 physical-Tab tests skip**, zero failures (focus/shortcuts and two all-language mouse layout methods). Strict/deep signature verification passes with normal macOS signing access; the restricted attempt reported CSSMERR_TP_NOT_TRUSTED. `git diff --check` passes.

Research basis: Apple's [focusable](https://developer.apple.com/documentation/swiftui/view/focusable(_:interactions:)) activation/editing distinction and [SwiftUI focus cookbook](https://developer.apple.com/videos/play/wwdc2023/10162/). No global key monitor routing, event synthesis in production, preference mutation or visual redesign.

## Next handoff

Run the final acceptance queue on a normal identified build: VoiceOver/accessibility preferences and full traversal including profiles, destructive confirmations and focus restoration to the invoking control. The production-hierarchy fixture now verifies the basic editor/Settings paths below, but does not prove engine, permission or complete accessibility acceptance. Preserve user-confirmed external-trackpad behavior; six-preset Magic Mouse delivery is now user-confirmed in INPUT-015.

## Menu appearance regression and scope audit — 2026-10-19

The user's supplied screenshot shows a grey 52 × 36 pt system bezel around row options. A native Light/Dark specimen reproduces it after applying the custom Button primitive style to SwiftUI Menu; the saved Sketch plain icon/Binding Row source and a native `.plain` reference show a compact unfilled icon instead. Both BindingRow and ProfileManagerView use this OptionsMenu. No input-engine change is needed.

Restoring `.plain` with an editing focus stop removes the bezel but live CUA proves Space/Down cannot open it. The final fix uses the existing AnchoredMenu presentation and public NSHostingMenu (available macOS 14.4+, checked in the installed SwiftUI interface and [Apple documentation](https://developer.apple.com/documentation/swiftui/nshostingmenu)) for its SwiftUI menu content. The icon trigger stays 28 × 28 pt, its surface is omitted, and native tracking/action/nested-menu semantics and locale are retained. Selector controls keep their existing capsule; shared focus ownership remains intact. KeyboardButtonStyle now explicitly documents Button-only use. No custom event forwarding or accessibility-action workaround.

Audited the prior keyboard-style call sites: primary/secondary/destructive and disabled buttons, switch, circular plus, recorder clear, anchored selector, segmented settings picker, banner dismiss, action-picker and status/search buttons. Only OptionsMenu applied the Button primitive style to a Menu; the separate app-scope Menu already uses `.plain`. Shared control specimens before/after were captured with native XCTest in Light/Dark and inspected locally. Apart from restoring the options icon/row height, no additional appearance regression was observed in the sampled controls. Existing rule and profile row sites share the correction. This is a bounded affected-control audit, not full-app visual or VoiceOver certification.

Live engine-free fixture verifies Tab reaches options; Space opens the menu; Escape restores focus; Down/Down/Return executes the fixture action once and restores focus. Focus and shortcut tests plus all-six-preset/all-language mouse layouts pass: **5 native methods pass, 2 physical-Tab methods skip** because their XCTest runner cannot be active/key. Added one native appearance specimen covering both themes; temporary screenshots remain outside Git. Final live fixture also exposes the disabled item as disabled and opens/executes a nested menu action once (counter +2), then restores focus. The final appearance-method rerun passes; strict/deep app signature verification, affected local file links and `git diff --check` pass. Isolated artifact remains `REBIND_DERIVED_DATA=/tmp/rebind-mouse-native`; the installed app was not replaced. Sketch was inspected read-only, not saved. Production rules, gestures, permissions and the installed app are untouched.

## Full production hierarchy walkthrough — 2026-10-19

A Debug-only `--application-fixture` now presents the production ContentView, editors and Settings using disposable temporary storage and seeded do-nothing rules. App lifecycle does not start the engine, capture or Menu Bar service; window category persistence is disabled for this fixture. Secondary delegate scenes/tests also use temporary storage rather than the production configuration. Normal launch behavior is unchanged. Permission values in the main fixture are injected, so this is UI evidence only.

Live CUA on the first complete-window fixture reproduced two additional issues hidden by the earlier shared-control specimen:

- After switching to Magic Mouse, Command-N opened a keyboard editor, while clicking Add opened the correct mouse editor. The native key-equivalent registration retained the old detail closure. Add now resolves the current category from ContentView state at invocation, instead of capturing a previous detail scope. Settings has no input-category destination to add to.
- Tab skipped the app-scope selector and reached the note field. RuleApplicationField now uses the existing anchored selector/native NSHostingMenu route, retaining its capsule, locale, importer and choices. Its two native AX menu-button children become one keyboard-operable selector.

Before these repairs, the full mouse editor already passed Tab to Action, Space opening its popover, action search/Return selection, and focus return without executing an action. Escape dismisses the editor. Six old four-language native layout loops (main window, Input/Language, Mouse, Advanced, permissions and About) now enumerate AppLanguage.allCases, covering EN/RU/DE/FR/ES/Simplified Chinese rather than a hardcoded subset. The first fixture compile exposed the intentionally private configuration setter; fixture configuration is now saved/loaded only through its temporary ConfigurationStore. Final runtime and test results are recorded after execution below.

[Final release acceptance queue](../verification/release-candidate.md) consolidates remaining checks while preserving prior user-confirmed hardware subsets; it does not close VoiceOver, safety, device/platform or release-installation gates.

The initial expanded native run completed 18 methods and reported one unfinished main-window settings method because the test runner exited with code 0. The tester subsequently identified accidentally closing the test app; this is an interrupted run, not a product failure or a passed method. The same settings matrix was rerun in section-sized diagnostic groups: all six main-window methods pass. The retry has eight passes and two inactive-runner physical-Tab skips, zero failures. The initial run's other 18 completed methods retain their own evidence; counts overlap and are not a unique-test total.


### Final reconciliation — 2026-10-20

A third reproduced issue was Command-F doing nothing while Add owned focus. The former view-local key handler is replaced by a native Commands entry with a scene-focused search action. Search is unavailable while an editor, profile manager, deletion confirmation or setup sheet is presented. Existing localized search copy is reused; no new strings or engine behavior.

Live CUA on the final production-hierarchy fixture verifies Command-F from both sidebar and Add, Tab moving from search to Add with no residual search accent outline in the sampled view, Command-5 followed by Command-N opening the Magic Mouse editor, and Command-F leaving that editor's preset focus intact. The editor additionally verifies action selection/search, the app selector's All Apps/Choose App native menu, output Record/Cancel with Escape retaining the editor and returning to Record, and Escape closing the editor. Settings arrows select Input and keyboard changes a temporary gesture-distance value. No output action is executed. Focus returns to a usable sidebar control after editor dismissal; exact invoking-control restoration, profiles/destructive flows, VoiceOver and accessibility preferences remain open.

Artifact: isolated Debug `REBIND_DERIVED_DATA=/tmp/rebind-release-ui`, baseline `main e070ec9` plus the uncommitted UI files and layout-test changes. Final `rebind.debug.dylib` SHA-256: `476ab9231a2a2be6425c2764d816f5b9ea01b67c1f2e188449274d893d06394c`. macOS 27.0.1 Apple Silicon, installed Xcode 27.1 / SDK 27. Final build succeeds; strict/deep signature verification succeeds with normal system trust access (sandbox-only verification reports CSSMERR_TP_NOT_TRUSTED).

Local evidence: `rebind-release-ui-tests.log` (18 completed methods, one user-interrupted method), `rebind-release-ui-retry.log` (eight passes/two skips), and `rebind-release-ui-focus-final.log` (three passes/two inactive-runner skips), all in the temporary directory. Final focus result bundle: `Test-rebind-2026.10.19_23-16-04-+0300.xcresult`; the subsequent modal-search gate was built and exercised live. Layout expansion covers all six languages in both appearances in the affected suites; this does not establish fluent proofreading or every production viewport. No new visual design, Sketch save, production configuration/permission changes, installation, publication or Git commit. Signing/DMG work remains independently owned.

Next: use the [release candidate queue](../verification/release-candidate.md) for normal-build accessibility, safety and installation acceptance; preserve confirmed mouse/trackpad delivery instead of repeating the whole feature pool.


### Grouped mouse menu and profile walkthrough — 2026-10-20

User requested the same semantic separators as the Trackpad selector. MagicMouseTriggerEditor now uses the existing MenuSelector startsGroup hook before three-finger click and two-finger scroll up: three taps / physical click / two scroll directions. Six existing choices, localized labels, selection tags, engine and persistence remain unchanged. This follows the supplied Trackpad menu reference and current native implementation; no new visual component or strings. Sketch MCP is unavailable in this session, so saved six-choice source reconciliation remains open rather than claiming a source save.

The isolated Debug build succeeds. Live CUA in --application-fixture confirms two visible separators, Space opening, arrow/Return selection of the physical-click group, End/Return selecting scroll down, and focus returning to the selector. No gesture action is executed. The same disposable production hierarchy verifies keyboard opening of profile management, creation through its name field and Enter, profile switching, options menus, and Escape cancelling profile/rule deletion with the original item preserved and focus restored to its options trigger. Closing profile management restores the profile selector. Only disposable fixture storage changes; no production profile/rule changes or deletion. Native text injection did not enter the requested fixture name reliably; paste plus observed field readback and Return completed it. This is tool input behavior, not accepted evidence of a product text-entry defect.

No new implementation-mirroring test is added for the small separator configuration; the existing native menu behavior was exercised directly. Previous six-language layout checks remain dated evidence; the change adds no text or closed-control geometry. VoiceOver, accessibility preferences, import/export panels, exact editor-invoker restoration and normal-engine acceptance remain open. Release packaging results are recorded separately below when completed.


Release packaging completed through the existing release.sh on 2026-10-20: Release build, stable Rebind Release app/DMG signing, strict signatures and hdiutil integrity verification pass. Updated local artifact: apps/rebind/build/release/Rebind-1.0-1.dmg, SHA-256 fb25d5faa0ddcc128b2e1c1a278a7b8ce50358ac6ca0200b2c74195e492f260d. This replaces the previous local package at that filename; version/build remain 1.0/1 and it is not published or installed. Existing CompanionApp deprecation and create-dmg/hdiutil deprecation warnings remain; no packaging source/asset changes. git diff --check and affected local file-link review pass. Saved Sketch reconciliation is subsequently completed in INPUT-015 on October 20. Next: remaining identified-build accessibility/hardware/update checks in the release queue.


### Final readiness follow-through — 2026-10-20

REL-003 additionally verifies Add/Edit dismissal returning to their invoking Add/options controls, profile import/export panel cancellation restoring Import/options focus, and the native manual-update no-release result. Actual file transactions, full VoiceOver/preferences and normal-engine acceptance remain open. The current package is now identified in REL-003 rather than the older hashes above.
