# REVIEW-001: Production review and paired design walkthrough

- Updated: 2026-10-16
- Stage: awaiting_verification
- Owner: Unassigned; /root review and additional verification released 2026-10-16
- Baseline: clean main `fdaef8f`; review changes are uncommitted
- Owned surfaces: app/local HIDPP review, regression tests, Rebind.sketch Screens/components and affected records
- Requirements: SPEC §§2–13, 15–16; existing release gates remain applicable

## Result and acceptance

- [x] Review across capture/matching/trackpad lifecycle, action dispatch, storage/import, device protocols/concurrency, SwiftUI/AppKit, localization/accessibility, project settings and local HIDPP. Concrete defects repaired within the existing architecture; no new dependency/toolchain.
- [x] Debug/Release builds, full behavior/native-layout regression, final localized-copy check and signature verification pass.
- [x] Additional review of the original patch, further regression fixes, full rerun and repeated Thread Sanitizer checks complete.
- [x] Live Sketch saved/reviewed: 52 numbered Light/Dark pairs, one vertical walkthrough; current missing Devices/Bluetooth/name, General battery and Language Apply states reconciled.
- [x] Exact battery-menu row checked against native APIs, then shipped (2026-10-16): the Menu Bar menu is an AppKit `NSStatusItem`/`NSMenu` with the four-part row. User-confirmed look on macOS 27; keyboard selection, VoiceOver and macOS 26 remain open.
- [ ] Real-device safety/runtime, VoiceOver/keyboard and macOS 26 acceptance remain open. The whole product is not declared production-ready by this review.

## Repaired findings

1. **Held outputs/quit:** shared keys/modifiers remain pressed while another trigger owns them; releases preserve other synthetic/physical modifiers. Step cleanup no longer interrupts the final held-key drain. Quit serializes release with in-flight worker presses before waiting on device shutdown. Quick-tap fallback respects the pending queue bound.
2. **Smooth scrolling:** sender/settings/revision travel with a glide. The posting thread rechecks that lease, Secure Input and actual posting access. Pause, editing/recording, suspend/stop, app/exclusion changes and settings changes invalidate old work, including A→B→A. Fractional carry resets between generations; nonfinite/oversized deltas are bounded before integer conversion. Pointer ownership updates when windows move under a stationary pointer.
3. **Device concurrency:** HID++ settings/battery/receiver completions check the current I/O session. Probes and battery reads coalesce; slider writes keep only the latest pending setting. Fresh companion-app authorization is checked between writes. Revision invalidation prevents a queued write regaining authorization after refresh or companion start/stop; shutdown/removal revoke it first.
4. **Battery/protocols:** a reading unavailable initially can appear later; failed/invalid refreshes retain the last valid sample. System percentages outside 0–100 are ignored. ADC charging uses its own connected/charging bits, rather than BATTERY_VOLTAGE flags. Receiver notification setup requires its SET acknowledgement. Report buffer/receive lengths are bounded.
5. **Editing/lifecycle:** a held named shortcut reopens as an editable shortcut with Repeat available. Profile reads follow sheet-task cancellation and reject results started before whole-document replacement. Menu Bar running state uses actual capture/runtime status.
6. **Text/accessibility/copy:** Quartz chunks respect 20 UTF-16 units even for oversized graphemes, without splitting a Unicode scalar; 10,000 units bounds pathological combining sequences. New messages support all six languages. App scope exposes an accessibility value; capture clear has visible keyboard focus. Bluetooth restricted and battery descriptions match behavior/categories.

Capture callbacks remain synchronous and bounded; hardware I/O stays outside them. Tools changed no real configuration, remapping, device setting, permission, login registration or system preference.

## First review software evidence

Agent-run 2026-10-16, Apple Silicon macOS 27.0.1 / Xcode 27 / Swift 6.4, baseline plus review diff:

- Baseline `apps/rebind/scripts/dev.sh test`: **803 Swift Testing tests / 124 suites + 17 native XCTest tests**, pass.
- Targeted repairs: **29 tests / 5 suites**, then **32 tests / 6 suites**, pass.
- Full repaired `dev.sh test`: **818 Swift Testing tests / 126 suites + 17 native XCTest tests**, zero failures. Includes semaphore-controlled press/quit ordering, shared ownership, queue bounds, nine glide invalidations, Unicode reconstruction/bounds, battery/protocol/auth and stale import regressions.
- After the battery-description-only change in six languages: `dev.sh build`, `dev.sh release` and `dev.sh test -only-testing:rebindTests/GeneralSettingsLayoutTests -only-testing:rebindTests/LocalizationTests` pass. The selected run executes **one GeneralSettingsLayoutTests method**, then covering EN/RU/DE/FR and both appearances; no suite named LocalizationTests was selected. The additional review below corrects the earlier overstatement of six-language General fixture coverage.
- First-pass Debug `Rebind.debug.dylib` SHA-256 `f1ce44515465961fc56e82618441b61547897c77932fdd3719177598d02a51e8`; first-pass Release executable SHA-256 `76c5328957ba7dd6fe04ee147fb40f0be9d325e8fd26e091c0e8ef2390811cf2`.
- Both bundles pass `codesign --verify --deep --strict --verbose=2` with normal trust-service access. Sandboxed cache/signature checks initially lacked Xcode cache/trust-service access; approved reruns pass. No trust setting changed.
- Existing warnings: unused mutable test fixture, AppIntents extraction without that dependency and one native test QoS diagnostic. No final compiler/test failure. Logs/prototypes stay outside Git.
- Final whitespace, affected links, six-language catalog completeness and kept/ignored new paths reviewed at completion.

## Additional review, 2026-10-16

The second review re-examines the entire original patch and reruns the complete suite before and after further corrections. Saved Sketch content is preserved.

- Long Insert Text batches now recheck cancellation before each chunk and finish an already-accepted down/up pair. A new injected regression failed before this correction with two assertions: the old implementation returned performed and posted every remaining pair after cancellation.
- Gesture-button diversion ownership now belongs to the HID++ connection/receiver slot, surviving replacement of feature adapters. A late write through an older adapter remains visible to cleanup, including an adapter not yet published to MainActor or already destroyed. The acknowledged protocol handle is retained for queue-bound cleanup; native I/O stays outside the ownership lock. Failed releases retain ownership for retry; other slots/connections do not inherit it. Mock-device regressions exercise the real LogitechDevice apply/divert/cleanup path without hardware commands.
- Gesture-button notifications combine active presses across receiver slots/connections. Refresh preserves a held source while replacing its handler generation; obsolete handlers, removed routes and post-stop reports cannot release or resurrect another source. A wireless link-down notice releases that slot even while its receiver remains attached. Concurrent report streams have a balanced-delivery stress regression.
- A settings completion invalidated by a newer authorization/refresh revision no longer overwrites the newer displayed state.
- General layout checks use AppLanguage.allCases rather than the previous four-entry list: 13 states × six languages × two appearances × three sizes, **468 combinations**, including Spanish and Simplified Chinese.
- Explicit MainActor/Sendable toggle setters retain UI isolation across SwiftUI bindings; unnecessary unsafe isolation on immutable C function pointers and an unused mutable test fixture are removed after the sanitizer rebuild exposed those warnings.
- HID++ long feature reports at index 0x41 no longer masquerade as receiver connection notices. The receiver parser requires the short-report identity, with a packet-level regression; Linux HID++ independently uses the same protocol distinction. No GPL source was copied.

Verification on the same Apple Silicon host/toolchain, baseline plus the final review diff:

- Initial additional full run: **818 Swift Testing + 17 native XCTest tests pass**. The new text-cancellation regression fails before repair; focused repaired run passes **36 tests / 6 suites**. Intermediate full runs pass **824 + 17**, then **826 + 17**.
- Final `apps/rebind/scripts/dev.sh test`, after the wireless link-down correction: **827 Swift Testing tests / 128 suites + 17 native XCTest tests**, zero failures; `TEST SUCCEEDED`. This includes the 468 General layout combinations.
- Dedicated local library check, `xcrun swift test --package-path apps/rebind/Packages/HIDPP --scratch-path <temporary directory>` with the same Xcode toolchain: **32 HIDPP XCTest tests**, zero failures.
- `dev.sh test -enableThreadSanitizer YES -test-iterations 10`, selecting CatalogActionTests, GestureButtonOwnershipTests, GestureButtonInputTests, LogitechMouseTests, HeldOutputTests, ModifierHoldTests and HIDPPReviewTests: **41 tests / 7 suites repeated ten times**, pass, no data-race report. An earlier sanitizer pass covered 38 tests / 6 suites. These runs cover concurrent report streams and queue cleanup; physical-device behavior is separate.
- Final `dev.sh build`, `dev.sh release` and both `codesign --verify --deep --strict --verbose=2` checks pass. Release contains arm64 and x86_64. Debug was regenerated from the same sources to remove a stale embedded sanitizer runtime from the earlier test output; neither final bundle contains a test module/sanitizer runtime or links Thread Sanitizer.
- Final Debug `Rebind.debug.dylib` SHA-256 `e14bd02c2603feb53dbd6846dde3b87f63589175f97a79dc8c0a3c2e21836bb0`; final Release executable SHA-256 `5818d3788f608b67b70c79daabc8b5ce0a6e32cdf7975967a240a1e77e817e1a`.
- Compiler isolation/unused-variable warnings described above are absent from the final recompilation. Remaining diagnostics: unused AppIntents metadata extraction, sanitizer-build duplicate instrumentation rpath and the existing About fixture AppKit QoS warning. No final build/test/signature failure. All three changed copy keys have translated nonempty values in all six languages; affected local links, tracked/new-file whitespace and ignored/kept paths pass review.

Saved Sketch was rechecked live without edits: all 104 frames still form the intended 52 Light/Dark pairs; fresh Keyboard Light and per-mouse Devices Dark screenshots match the saved source, whose digest is unchanged. Existing hardware/VoiceOver/minimum-OS and native menu gates remain open.

## Third review, 2026-10-16

Independent re-read of the uncommitted review diff plus commits `1a0801b` and `fdaef8f` (battery menu, device names, multi-vendor/Bluetooth battery, HID report map, vendor protocols). The repairs above are accepted as-is; no regression or overreach found in held output, glide invalidation, gesture ownership, write-access revisions, receiver parsing, ADC flags or text chunking.

- Fixed: two held triggers sharing one output key sent two autorepeat streams (double rate). Only the earliest owner now repeats; when it is released, the remaining owner inherits its press/repeat timing, so the stream continues in step. New regression `aSharedOutputKeyRepeatsAtTheNormalRate`.
- Verification: full `dev.sh test` before the fix: **827 Swift Testing / 128 suites + 17 native XCTest**, pass. After it: HeldOutputTests + ModifierHoldTests **21 tests**, pass; full `dev.sh test` **828 Swift Testing / 128 suites + 17 native XCTest**, pass. Hardware behavior of shared holds is not exercised.

## Saved design and battery menu

Live **Rebind.sketch**, saved 2026-10-16, SHA-256 `fdd823443e23b7ffc8be91c6c528e27172bdbdc017c150d7b265c68adbbad30f`; resolve through MCP, as IDs change on save. All 104 Screens frames match planned positions/dimensions, Light left/Dark right, sequential 01–52. First pair fitted to canvas with the public API. Original and superseded global-scroll/duplicate Input/older Devices specimens remain in Archive; a pre-edit live backup stays local.

New identity/Bluetooth components reuse theme variables/styles. Unknown charge is hidden; charging and six battery symbols use exported SF Symbols. Keyboard/trackpad/USB inventory, Rename, Bluetooth allow/denied/restricted and menu charging/local names are drawn. General includes Battery in menu; every Settings frame has six tabs. Language distinguishes draft Apply from saved/reopen. Caps Lock examples became F6. Changed frames were MCP screenshot-reviewed in both themes with representative full-frame rechecks after ordering. Native compact/accessibility acceptance is separate.

**Four-part menu row is feasible:** standard `NSMenuItem.image` plus `attributedTitle`, tab stops and an `NSTextAttachment` battery symbol retain native menu-item behavior and a complete accessibility label. No custom menu view is required. An isolated four-row AppKit prototype with charging compiles against the current SDK. SDK 27 requires opting into leading images with availability-gated `preferredImageVisibility = .visible`; preserve macOS 26 behavior. [Apple attributedTitle](https://developer.apple.com/documentation/appkit/nsmenuitem/attributedtitle) and the local NSMenuItem header support this mechanism.

**Implemented 2026-10-16.** A SwiftUI probe in `MenuBarExtra` showed the limits: a `Text` with an interpolated `Image` keeps the battery symbol inline, but tabs become spaces, `.badge` drops images and SDK 27 hides leading item images. A SwiftUI menu has no trailing column, so the whole Menu Bar menu moved to AppKit ([MenuBarController](../../apps/rebind/rebind/UI/MenuBarController.swift)). Its items match the former SwiftUI menu. The menu is rebuilt in `menuNeedsUpdate`, and the icon follows `rulesAreRunning`/`showsMenuBarIcon` through Observation; Command-drag removal writes the preference back. A zero-size SwiftUI `SceneActions` view in the status button hands `openWindow`/`openSettings` to AppKit; the Settings tab moved to `AppModel.settingsSection`. Battery rows: device symbol (`preferredImageVisibility = .visible` on 27, availability-gated), local alias, then one right-aligned tab stop shared by every row after the longest name. The trailing part is the percentage (secondary; red at ≤15 % when not charging, matching Devices) and an `NSTextAttachment` battery symbol (`battery.100.bolt` while charging). Accessibility label is "name, charge" using the Devices charge copy. The unused `batteryMenuCharging` string was removed.

Evidence: a debug build in test mode (no configuration load/engine start) with sample batteries (charging, 45 %, 10 %, a 58-character Russian alias). Window actions opened Settings and the main window at launch with the window suppressed. The user opened the menu and confirmed the look on macOS 27 (RU): icons, aligned column, red 10 %, long alias. **Known difference from Sketch:** the battery column ends at AppKit's reserved key-equivalent/submenu column (left of `⌘Q`), not at the menu edge. Only a custom `item.view` could reach the edge, at the cost of native highlight/keyboard/accessibility, so it was not done. `MenuBarBatteryTests` cover the shared tab stop, title/attachment, visible image and accessibility label in all six languages. Full `dev.sh test`: **830 Swift Testing / 129 suites + 17 native XCTest**, pass; `dev.sh build` and `dev.sh release` pass. Open: arrow-key selection and highlighted-row contrast, VoiceOver speech of the label, macOS 26 rendering, real devices/aliases in the installed app. Also open: whether `SceneActions` appears while the Menu Bar icon is hidden at launch (Dock reopen with a suppressed window relies on it; the former `MenuBarExtra` label had the same dependency).

## Research and next actions

Refreshed [Apple menu API](https://developer.apple.com/documentation/appkit/nsmenuitem/attributedtitle), [Logitech protocol docs](https://github.com/Logitech/cpg-docs/blob/master/hidpp20/README.rst), [Solaar HID++](https://github.com/pwr-Solaar/Solaar/blob/master/lib/logitech_receiver/hidpp20.py) and [Linux HID++](https://github.com/torvalds/linux/blob/master/drivers/hid/hid-logitech-hidpp.c). Solaar/Linux are protocol comparisons only; no GPL code copied. Existing native APIs/local MIT HIDPP suffice; no dependency install. Prior maintenance/licenses remain in [the register](../research/DEPENDENCIES.md) and [battery audit](../research/multi-vendor-batteries.md).

Runtime next: verify overlapping holds/quit/sleep/pause release, glide cancellation, multiple gesture-button mice, reprobe and mouse power-off while held, receiver reconnect and companion start/stop on this build; record OS/model/transport and actual grants. DEVICE-001–003 and INPUT-009–011 retain broader hardware checklists. Magic Mouse presets/editors still need its probe; PLAN retains private-API, latency, VoiceOver, minimum-OS and distribution gates.

Implementation next: on the installed build, check arrow-key selection/highlight and VoiceOver on the Menu Bar battery rows, then macOS 26. Sketch is saved; Git review changes remain uncommitted. Baseline `fdaef8f` already contains DEVICE-003, correcting its previously stale current-status claim.
