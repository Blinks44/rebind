# First-run and permissions: native implementation

Routine capture files were moved to ignored local storage during repository cleanup on 2026-10-11. The dated observations, commands and acceptance limits below are preserved; these images are not automated test baselines.

2026-10-11, UI-001; SPEC §§6–8/10–11 and S2. Implementation is integrated and software-tested, **awaiting native permission/accessibility acceptance**. Baseline `main` / `acce2f4` plus existing uncommitted trackpad repair/design records and the permission implementation files below. No Git commit or Sketch edit/save was performed for this implementation.

## Implemented behavior

- New installations with missing required access open setup once in the main window. Accessibility, event-posting and ready states use the existing public AX/Quartz preflights. Check Again and application-focus return reread actual state. Only explicit buttons request access; polling never prompts.
- Set Up Later and Continue atomically save setup acknowledgement in configuration schema **23**. Neither changes rules, profile selection, global enabled/pause intent or the runtime mailbox. Continue rechecks required access immediately before finishing. Failed acknowledgement keeps setup open with the existing localized storage error; unreadable/future files remain locked and untouched.
- Schemas **1–22** migrate in memory with setup acknowledged, preserving profiles, rules, IDs, actions and enabled state. Migration alone never writes. Schema 23 requires a valid Boolean acknowledgement field; corrupt/future data is not replaced.
- Main recovery notice opens the relevant explicit grant request or Settings → Permissions. Existing manual rule editing/profile controls remain available. Recording/remapping still require confirmed access. The notice follows missing grants, rather than treating sleep or another nonpermission suspension as a grant failure.
- A valid→missing transition opens the recovery sheet at most once per main-window lifetime, while the app is active and no editor/profile/diagnostics/delete flow is open. Other cases keep the inline notice. Closing recovery or receiving later polling results does not repeatedly reopen it. Required-grants success remains separate from engine failure and deliberate pause.
- Permission loss cancels remaining recording, after consuming any existing worker cancellation result. The existing synchronous tap/output guards are unchanged. Grant changes do not rewrite enabled flags.
- Settings is reachable from the sidebar, standard Settings command (⌘,) and Menu Bar. All use the delegate's existing model; opening Settings does not start another engine. Input Monitoring is always Not required for this active-tap path; Automation remains action-specific. Finder reveal retains the running bundle URL and signing guidance.

## Live design and bounded differences

Read-only Sketch inspection resolved document `56ED9B64-CF2D-4FE8-AB0E-4EA4E3501214`, API 2.0.0. Explicit-ID live screenshots/tree/style inspection covered frames 08, 10, 11, 12, 14 and 17. The subsequent independent UI-004 delivery changes the document identity; resolve current DESIGN before future work. Permission source IDs remain the ones in [design delivery](../history/settings-design-through-2026-10-11.md#permissions).

The implementation reuses the delivered 32 pt setup margins, square 48 pt bundle icon, 88 pt introduction region, 16 pt action gaps, pinned footer, 28 pt Settings margins, 16 pt card padding/gaps and 12 pt card corners. Four named Light/Dark color assets reproduce live canvasTop/canvasBottom/surface/warning variables. Opaque content gradients and surfaces coexist with system-native navigation/control materials; no glass was added to permission content.

Main default is 1040 × 640; minimum is now 880 × 600 to reconcile the compact design. Setup prefers 560 × 580, minimum 520 × 560; scrolling handles excess content without shrinking type. The standalone native Settings scene supports a 600 × 480 minimum, preferred 760 × 600; the sidebar route uses the normal main detail width.

Deliberate bounded differences: unavailable Settings tabs and About are omitted; full main/sidebar/profile/list/editor visual integration is still pending. The sidebar Settings destination and standard separate Settings window share the same permission content. Existing Finder/signing help remains below the privacy note. System semantic fonts and native button sizing replace Sketch's exact typography/control pixels. Inactive fixture windows render neutral native buttons; active-window accent/focus and actual material behavior remain runtime checks.

## Software and artifact evidence

Host: Apple Silicon, macOS **27.0.1 (26A434)**, Xcode **27.0 (27A266a)**, Swift **6.4**, SDK **27.0**. Target remains macOS 26+, Swift 6 strict concurrency, scheme/module `rebind`, product `Rebind.app`, bundle ID `blinks44.rebind`; no dependencies or project settings changed.

- `apps/rebind/scripts/dev.sh doctor`: reports the above toolchain and `rebind` / `rebindTests` targets. Restricted execution emits cache/Simulator-service warnings but completes.
- Initial restricted `apps/rebind/scripts/dev.sh build` failed because sandbox-exec denied the Swift macro plugin. Xcode checks subsequently ran outside the sandbox through the authorized build script.
- Final `apps/rebind/scripts/dev.sh test`: **508 tests / 68 suites / zero failures**, `TEST SUCCEEDED`, 2026-10-11; runner completed at 08:33:57 local. Includes the pre-existing trackpad repair tests. Fifteen new test functions cover missing/ready grants, grant/posting progression, cancellation/engine separation, durable deferral, failed writes/corrupt/future files, one-time presentation/editor protection, schema 1–22 migration and schema-22 trackpad preservation without rewriting. No global input posting or ordinary app-engine launch in the test host.
- The first full test attempt exposed two regressions: cancellation result consumed too late, and a prior trackpad migration assertion hard-coded schema 22. Both were corrected; final full tests include their regressions. Pure presentation state is explicitly nonisolated/Sendable under the app's main-actor-default configuration.
- `apps/rebind/scripts/dev.sh release`: `BUILD SUCCEEDED`; Release Mach-O contains **x86_64 + arm64**. This does not prove Intel or macOS 26 execution.
- `codesign --verify --deep --strict` passes for final Debug and Release bundles. Only expected AppIntents metadata-skip warnings; macOS test-host linkd service warnings did not fail tests.
- All **53** handoff keys exactly match EN/RU/DE/FR catalog values (52 additions and the existing permissionsTitle updated to the delivered heading). Copy reviewed with Writing for Interfaces; no artificial line breaks.
- `git diff --check` passes. Shared source/skills/design inputs remain versioned; build/xcresult output remains under existing narrow ignore rules.

Identified binaries (SHA-256, before any subsequent rebuild):

| Artifact | Digest |
| --- | --- |
| `build/DerivedData/Build/Products/Debug/Rebind.app/Contents/MacOS/Rebind` | `d4d459adad22a2ab4126edf02cd72d551092720fb6346ac22000c8420dbabc19` |
| `build/DerivedData/Build/Products/Release/Rebind.app/Contents/MacOS/Rebind` | `c32f27bdf78fc7987af740865dbbb5265eb9004f9e8d2d21602c1ddaa3c99939` |

## Native fixture rendering

A temporary XCTest-hosted capture helper used NSHostingView, isolated injected grants, temporary configuration and inactive AppKit windows. It was removed before the final full test run. These are native rendering fixtures, **not actual-grant, input-delivery or full-window acceptance**.

Reviewed 32 nonempty setup/permission/banner captures: three permission states × four locales for setup and Settings; Light/Dark compact German recovery, expanded Russian setup, wide Settings and French recovery banner. Setup 560 × 580, recovery 520 × 560, expanded 720 × 680, Settings detail 648 × 600 / 808 × 640 and banner 648 × 220. The translations wrap, controls fit, footer stays visible and permission content scrolls. A separate AppKit high-contrast appearance trial rendered, but does not establish the actual system Increase Contrast/Reduce Transparency/Motion environment behavior.

The complete main NavigationSplitView offscreen attempt was blank; it is excluded from accepted screenshot evidence. Main navigation/list/material/focus review must use an actual ordinary window. No global permission/preferences were changed to produce screenshots.

Reviewed captures and locale/state contact sheets (now local):

- All setup locales/states, all permission locales/states.
- English setup, Russian event sending, French ready.
- Compact German recovery, Dark, English Settings, German event-sending Settings, Dark Settings, French recovery banner.

## Remaining native acceptance and accessibility review

Static SwiftUI review found no demonstrated P0/P1 accessibility blocker in these additions. Native text buttons retain independent actions, status/title groups preserve their text and expose header semantics, decorative icon is hidden, and state is conveyed with text independently of color. Semantic fonts, wrapped content, ViewThatFits button/header fallbacks and scrolling avoid typography shrinking. No custom gesture activation or animation was introduced. This is source review, not VoiceOver certification; regression risk remains in sheet focus/navigation and grant timing.

On an explicitly identified bundle, with the user controlling real permission changes:

1. Start with a genuinely new test configuration and missing AX access. Setup should appear once; Tab/Shift-Tab reaches settings/check/later actions, Continue is unavailable. Set Up Later must leave the main notice, editable rules and paused intent; reopen should not show first-run setup again. Do not replace a real configuration to manufacture this state.
2. Grant Accessibility for the identified running copy, return to Rebind and compare the actual posting preflight. If posting is missing, only its explicit request is offered. A failed/denied prompt stays missing. Continue becomes available only with both required grants; an intentionally paused app stays paused.
3. With a disposable recording active, revoke access and return. Recording ends safely; rules/profile/enabled intent stay intact, normal input passes through and the relevant notice appears. Verify one-time recovery and no modal interruption during an editor/delete/profile/diagnostics flow. Restore access, check retained pause and separate tap-failure/Secure Input status.
4. Verify sidebar Settings and category return, ⌘, / Menu Bar Settings, Finder reveal, reopen/window close/single engine. At 880 × 600, preferred and expanded sizes, inspect full main and permission scrolling in EN/RU/DE/FR; primary actions and help must remain reachable.
5. VoiceOver: read heading → status → explanation → primary action → Check Again → instructions; buttons must be separately actionable, navigation selected state understandable, focus restore after closing sheets. Keyboard-only Tab/Shift-Tab, Return and Escape must work without trapping focus. Use Accessibility Inspector on an ordinary window; native automation and manual VoiceOver are still open.
6. Enable actual Increase Contrast, Reduce Transparency and Reduce Motion, check readable surfaces/native navigation, visible focus and no lost control/status. Check macOS 26 and Intel separately where claimed; stable signing/TCC persistence remains open.

## Main-window rendering regression: 2026-10-11

The user reported a blank sidebar and clipped main content. Read-only Computer Use inspection reproduced the visual failure in the already-running Xcode Debug `Rebind.app` (process 20230, `main` window; ordinary Xcode DerivedData artifact, not the script-produced artifact identified above). The accessibility tree contains category rows, Settings, profile controls, heading, recovery text/buttons and footer; the screenshot shows an empty sidebar, recovery buttons clipped at the upper edge and only the centered empty-rule state. At that initial inspection the cause was not established. Prior software/isolated-fixture evidence did not verify this full window or disprove the regression; the repair below supersedes that open diagnosis.

Live Sketch frame 14 (`C7666697-D667-433D-87E7-2ED3AEE66AB0`), document `E50CA3D9-82B1-44C0-AC97-39F1A9663700`, was screenshot-inspected again: its sidebar, heading, recovery banner and content are intact. Full desktop styling remains unimplemented; that separate gap must not obscure the native rendering failure.

Display-name discovery briefly opened a separate historical lowercase `rebind.app`; its unrelated three-column UI was excluded from evidence and the accidentally opened process was closed. Use an exact existing bundle path for subsequent native inspection. No permission prompt, rule edit or configured action was performed.

At the user's stop request, General implementation was halted before source edits. This investigation changed documentation only; no fix, build or new test run is claimed. The existing app implementation and independent work remain preserved.

## Main-window repair and verification: 2026-10-11

The recovery description's `.fixedSize(horizontal: false, vertical: true)` caused SwiftUI's native split-view minimum-size probing to compute an oversized height. In an isolated 1040 × 640 window, the split hierarchy measured 1040 × 1309 at y = −334. With the notice absent it measured 1040 × 640; removing only the description's fixed-height modifier restores 1040 × 640 with the notice present. The production fix is limited to that modifier in `PermissionRecoveryBanner.swift`; normal localized wrapping remains. No GeometryReader, hard-coded notice height, project setting or engine change was retained. Native sizing guidance was checked against [Apple's NSHostingController sizing contract](https://developer.apple.com/documentation/swiftui/nshostingcontroller/sizingoptions).

A permanent XCTest native layout regression in `apps/rebind/rebindTests/UI/MainWindowLayoutTests.swift` checks split-view bounds inside the window viewport for **72 combinations**: EN/RU/DE/FR × missing AX/missing posting/ready × empty/one-rule profile × 1040 × 640, 880 × 600 and 1280 × 800. It uses injected grants and a unique temporary store, never starts capture or loads real configuration. This is geometry coverage, not hardware or actual-grant acceptance.

Computer Use screenshot and accessibility inspection confirmed:

- Visible sidebar, profile controls, heading, recovery notice, empty state and footer in the 1040 × 640 native fixture; French/Dark 880 × 600 also fits.
- Recovery Review Permissions → sidebar Settings, return to Mouse and Trackpad, editor opening with recording disabled for missing access, Cancel restoring the main window, and Tab reaching Settings.
- The standard ⌘, command opens the separate native Settings scene; scrolling reaches the privacy/Finder/signing content.
- A genuinely unacknowledged isolated configuration presents first-run setup. Clicking Set Up Later closes it, returns to the intact main window and persists acknowledgement while keeping global enabled false. The temporary host asserts both in-memory and saved values. The first attempt expired during an interruption before the click and failed those manual-action assertions; the repeated action/check completed successfully.
- The final ordinary Debug bundle at `build/DerivedData/Build/Products/Debug/Rebind.app` was opened and screenshot-inspected after final tests/builds: the original blank-sidebar/clipping failure is absent. No configured action, rule edit or permission prompt was performed.

Twenty-four additional native fixture captures covered compact setup/Settings locales, missing-posting/ready/recovery and Light/Dark main variants. Split-view cache captures contain incomplete composited backgrounds/text and are excluded from visual evidence; main-window claims above rely on on-screen Computer Use screenshots. Thirteen non-main captures were visually reviewed; compact French setup, posting-required Settings and ready Dark Settings were inspected; their capture files are now local. Temporary capture/manual-wait XCTest helpers were removed before the final run; only the self-verifying native geometry test remains. A temporary attempt to reinstate the faulty text modifier was interrupted; it is not a successful automated before/after check. Original measured geometry and final bounds checks provide the regression evidence.

Final checks on the repaired source, baseline `main` / `acce2f4` plus the existing uncommitted implementation:

- `apps/rebind/scripts/dev.sh test`: **508 Swift Testing cases / 68 suites + 1 XCTest layout test, zero failures**, `TEST SUCCEEDED`; completed 09:12:44 local. The layout test checks all 72 combinations and passes in 11.240 seconds. Debug build is included. Log `/tmp/rebind-window-final-test.log` is supplementary.
- `apps/rebind/scripts/dev.sh release`: `BUILD SUCCEEDED`, **x86_64 + arm64**, 09:13:10 local; supplementary log `/tmp/rebind-window-release.log`.
- Both final bundles pass `codesign --verify --deep --strict`; all 53 four-language handoff keys exactly match the catalog; `git diff --check` passes. Expected AppIntents metadata-skip/test-host linkd warnings remain. The isolated manual sheet dismissal emitted transient AppKit negative-geometry warnings, but the returned window was intact and final geometry/full tests pass; ordinary-window transition stress remains open.

| Repaired artifact | SHA-256 |
| --- | --- |
| Debug `Rebind.app/Contents/MacOS/Rebind` | `5d6c73aba56745acb3468455e70ae8e1774a8dd4bb41240b9a12ebd73b6c9afa` |
| Release `Rebind.app/Contents/MacOS/Rebind` | `f16315306938e279ab5f0b1a108da13ec92719b4d89561c16b18ddfb79e0c263` |

**Next:** actual grant/revocation and VoiceOver/accessibility-preference acceptance remain user-controlled gates. The reproduced layout failure is repaired; General/Input implementation and whole-app soft styling have since been integrated; current continuation is in UI-001/STATE. No Sketch save or Git commit, new capability claim or user configuration/permission change.
