# FIX-003: Bounded menu errors and dismissible action alerts

- Updated: 2026-10-27
- Stage: awaiting_verification
- Owner: current implementation agent
- Ownership checked: main / 8eba440, clean starting checkout; scoped files owned for this fix; follow-up adds BindingsView and Sketch screen 70 / Foundations 13
- Owned surfaces: AppModel error lifetime, MenuBarController error row, BindingsView error banner, affected UI tests, build number, Sketch screen 70 / Foundations 13 and this task/STATE/SPEC/DESIGN/history
- Requirements: SPEC §8; action reporting A1
- Code baseline: main / 8eba440; uncommitted changes

## Outcome and scope

A failed window action leaves a long error in the native status menu, expanding every row to its full text width and remaining indefinitely. Bound the visible error to the ordinary menu's measured width with a trailing ellipsis. Keep the full message in its tooltip, accessibility label and existing main-window notice. The main-window category lists now use the shared red Banner with a localized Hide message button. Closing it clears the shared notice in both the main window and menu; another failure can show it again. No capture, window-action mechanism or localization changes.

Action execution errors expire 30 seconds after the latest failure using a monotonic deadline and the existing UI refresh timer; opening the menu also checks expiry. An already tracking native menu keeps its current rows until reopened. Explicit dismissal/another UI error cancels expiry. Persistent storage/validation errors take precedence and never expire because of the action deadline. No new timer or callback work.

## Source

Live Rebind.sketch menus 51–53 inspected for the original fix. Follow-up screen **70 · Main · Dismissible action error** in Light/Dark reuses shared danger tokens and close SF Symbol; Foundations **13 · Dismissible action errors** owns layout/lifetime/dismissal/keyboard/VoiceOver behavior. Native uses the existing Banner component; no global component styling changes. Saved/review evidence follows below.

## Acceptance and verification

- [x] Localized native menu sizing and full-text tooltip/accessibility regression pass.
- [x] Deadline, repeated failure, dismissal and persistent-error protection pass.
- [x] Builds 1.0.0 (22) and follow-up (23) app/DMG signing and image verification pass.
- [x] Shared dismissible banner designed/saved and native localized layout/recovery checks pass.
- [ ] Installed menu hover/VoiceOver and failed-window-action recovery verified.

## Next

Install the latest package identified in STATE (retaining this fix), then verify the banner with an unsupported window: read its full text, close it using the mouse/keyboard, confirm the menu notice also disappears, and trigger/reopen after 30 seconds. Check VoiceOver message/button order and full-text menu hover. Test injection does not prove a real window supports resizing.

## Software verification — 2026-10-27

`dev.sh test` selecting ActionErrorPresentationTests, MenuBarBatteryTests and AppModelStorageProtectionTests passes: **10 functions / 3 suites**, including six-language menu sizing/tooltip/accessibility checks and 15 protected-storage cases. Test bundle: `Test-rebind-2026.10.27_11-01-09-+0300.xcresult`. Deadline tests use injected monotonic instants; mailbox injection executes no real remapping. Initial sandboxed test could not write external SwiftPM caches; retry with normal cache access passes. Debug/Release build numbers incremented together from 21 to 22; marketing version remains 1.0.0.

Accessibility review: P2 full error text previously drove menu width; the patch keeps the native disabled menu item, abbreviates only the visible title and exposes the full accessible label/tooltip. Installed verification: open the menu using keyboard, navigate its normal actions with arrows, hover the abbreviated error and inspect/read it with VoiceOver (full text, no new focus trap). Close/reopen after 30 seconds: the action error must be absent. Regression risk is confined to error lifetime/presentation; capture/action execution and saved rules are unchanged. Manual hover/speech is still open.

## Package and final review

`apps/rebind/scripts/release.sh` succeeds: Release build, existing pinned Apple Development app/DMG signing, strict/deep app signature verification, strict DMG signature verification and `hdiutil verify`. App metadata confirms **1.0.0 (22)**. Current package: `apps/rebind/build/release/Rebind.dmg`; SHA-256 `330ef5b3303bea5d47020e4fe07202d338d21cfec2a95c87f2d1546a262ef726`. No installation/publication or permission changes. No notarization claim. Final diff/affected links reviewed; `git diff --check` passes. No commit or Sketch save.

## Dismissible banner follow-up — 2026-10-27

User-authorized design and implementation reuse the existing shared red Banner in BindingsView for every input category. Full text wraps; the existing localized Hide message button clears `model.error`, cancelling the deadline via its setter. The rules card stays inside its available viewport; clearing the notice restores its space. Six translations and the 30-second policy remain intact.

`dev.sh test` selecting ActionErrorBannerLayoutTests and ActionErrorPresentationTests passes: **8 functions / 2 suites**. Native full-window fixtures cover all six languages, Light/Dark, 880 × 600 and 1080 × 720, with a paused notice alongside the error, long scrolling rules and clearing/restored viewport checks. English Light and Russian Dark captures were inspected locally; the full message and xmark fit and the rounded rules surface remains bounded. Test bundle: `Test-rebind-2026.10.27_11-14-28-+0300.xcresult`. Disposable models never start capture/discovery or read real configuration. Test clearing changes the model; real mouse/keyboard button activation and VoiceOver remain installed checks. Both build settings now **1.0.0 (23)**; original build-22 evidence above is historical.

Accessibility review: native Button retains existing localized label/help, keyboard style and focus ring; error icon supplies a non-color cue and is hidden from speech, while text/button remain separate readable/actionable children. No new P0/P1 finding from code review. Verify Tab/Shift-Tab to Hide message, Space activation, reading message then close control in VoiceOver, and focus after removal. Regression risk is confined to added notice height; all language/theme/minimum-window layout checks pass.

Sketch follow-up saved successfully and re-resolved after save. Screen 70 Light/Dark and Foundations 13 screenshot-reviewed; both close prototype destinations are valid. Saved SHA-256: `a03d77d43aa412e9a1b747b3851b720c036fba7b05d917ffffe6bc62e93a482d`. New reusable Light/Dark Dismissible Error components preserve existing symbols/color variables; normal screens and unrelated sources are unchanged. No exports are committed.

Final follow-up package: `apps/rebind/scripts/release.sh` succeeds for **1.0.0 (23)**, including Release build, pinned existing app/DMG signing, strict/deep app verification, strict DMG signature verification and image verification. Package `apps/rebind/build/release/Rebind.dmg`, SHA-256 `4dfed0606c0253c445d68f57123a7860da00e44653db57323a4465736754c1e6`; Release metadata confirms build 23. No installation/publication or Git commit. Final diff/affected links reviewed and `git diff --check` passes. Ownership reopened for the independent-dismissal regression; installed keyboard/VoiceOver/real-window recovery remains open.

## Independent guidance dismissal — 2026-10-27

Tester reports closing the blue gesture-guidance banner also removed the action error. Source confirms `setPresencePreference` clears the shared error after every successful preference save, including hiding guidance. This is a second dismissal path independent of the 30-second deadline. Scope: make a successful UI-preference save clear only its own storage-write failure, preserving unrelated notices and their existing deadline. Use temporary configuration-store regression coverage; do not change real guidance preferences or execute remappings. No visual/Sketch change is required.

The regression test fails before the fix with three expectations across two functions: hiding guidance clears the action error immediately and also clears unrelated validation errors. Before-fix bundle: `Test-rebind-2026.10.27_11-20-30-+0300.xcresult`. The successful UI-preference path now clears only `.storageWriteFailed`, preserving unrelated errors and the original monotonic action deadline. New tests verify the hidden-guidance setting is persisted, the action error survives until its original 30-second expiry, storage-write recovery clears its own error and validation errors remain.

`dev.sh test` selecting ActionErrorPresentationTests and AppModelStorageProtectionTests passes: **10 functions / 2 suites** (including parameterized storage/validation and protected-file cases), bundle `Test-rebind-2026.10.27_11-20-56-+0300.xcresult`. Debug/Release are incremented together to **1.0.0 (24)**. No visual/Sketch/localization or capture changes; build-23 native layout evidence remains applicable. Installed separate-dismissal acceptance is still open; test injection uses disposable storage, not actual user preferences.

Build-24 `release.sh` succeeds: Release build, existing app/DMG signer, strict/deep app signature verification, strict DMG verification and image verification. Release metadata confirms **1.0.0 (24)**. Current DMG: `apps/rebind/build/release/Rebind.dmg`; SHA-256 `32832c6859af9ff820d56eaf28f98ec7a09453cb6b58f97141185c90f90794bd`. Affected links and final diff reviewed; `git diff --check` passes. No installation/publication or commit. Ownership released; next installed check: hide blue guidance while a fresh action error is visible, confirm the error remains and still expires on its original deadline.

## Regression-fixture isolation — 2026-10-27

The LIGHT-001 continuation's complete run exposed the native banner fixture changing global `AppLocalization` while unrelated Swift Testing suites run concurrently: 57 localized-label mismatches across seven suites. Suite-local `.serialized` did not isolate other suites. The fixture now uses XCTest, like the existing native window tests, and restores launch-time localization before the Swift Testing phase. Layout, dismissal assertions and production error behavior are preserved. The corrected native fixture passes; all **951 Swift Testing methods in 148 suites** subsequently pass. The preceding native phase's **28 XCTest methods (two skipped)** also passed on the same app source. [LIGHT-001](LIGHT-001-keyboard-lighting.md#experimental-rgb-and-connected-g915-continuation--2026-10-27) owns combined build-25 verification/package evidence. No additional FIX-003 production change.
