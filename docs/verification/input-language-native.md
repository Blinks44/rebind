# Input/hold and Language: native implementation

Routine capture files were moved to ignored local storage during repository cleanup on 2026-10-11. The dated observations, commands and acceptance limits below are preserved; these images are not automated test baselines.

Updated **2026-10-11**. Scope: [Input/hold](../tasks/UI-004-input-settings.md), [Language](../tasks/UI-005-language-settings.md). Baseline `main` / `b453d8d` plus existing uncommitted General/permission work; implementation and evidence remain uncommitted. Independent Sketch work is preserved; no design edit/save by this code task.

## Source and delivered behavior

Live Sketch frames 33, 38 and 41 were reread through MCP at document `1640CE3E-1622-4D01-BCDE-499A8F1C2C18`, then the concurrent consistency handoff was refreshed at `DC0FF6E0-6CDB-4A87-82C5-BB8FCAEFEDEB` (same stable frame IDs). Current visual source/digest is owned by materials/consistency evidence. Behavior/copy contracts remain [Input](input-settings.md) / [Language](language-settings.md). Native implementation reuses the existing Settings shell, semantic PermissionCard and system controls. Full custom navigation/material adoption is separate; native popup intrinsic width is retained within a 208 pt trailing control lane.

- Settings → Input explains per-binding timing, the macOS double-click interval, fixed cardinal pointer recognition and the existing experimental built-in four-finger tap. No new engine thresholds, recorder, hardware attribution or gesture claims.
- Hold-only keyboard/middle-extra-button editing retains the existing **100…5,000 ms / 100 ms** Stepper and valid off-grid stored values. New localized duration/range/one-shot copy is integrated. Existing consumption/cancellation warning remains visible. Save failure retains the complete draft, with Save/Cancel available; only the intended binding is committed on retry. Other activation/capture constraints remain unchanged.
- Settings → Language has native System Default / English / Русский / Deutsch / Français selection, page-local unapplied draft, Apply, atomic failure/retry and protected-storage feedback. Leaving/recreating the page discards an unapplied draft. Saved and active language are distinct; matching resolved choices need no reopen.
- Configuration schema **24** adds a strict `languagePreference` enum. Versions 1–23 migrate in memory to System Default without rewriting source bytes; version 23 preserves its actual setup flag. Malformed/missing current language values and future/corrupt files are rejected/protected.
- Language saving updates only the configuration preference. It does not call engine configuration, clear recording, change profiles/rules/pause, request access or execute an action. Held-source ownership/action revision preservation is software-tested.

All 18 Input and 16 Language handoff strings are integrated in EN/RU/DE/FR; the Input heading uses scoped `inputBuiltInTrackpad` to preserve the older category key's English capitalization. The legacy key and other catalog entries remain unchanged.

## Activation and platform decision

Use a launch-time display-language snapshot for SwiftUI scenes and Foundation strings already resolved outside their environment (input/action/profile labels, search and diagnostic column titles). Explicit locale resolution is supported by Apple's [LocalizedStringResource](https://developer.apple.com/documentation/foundation/localizedstringresource) API; native SwiftUI preview locale and existing catalog/resource behavior were checked rather than replacing Bundle methods.

Native menus from an existing test process remained in its launch language after changing only a SwiftUI view's environment. Therefore this slice uses the handoff's conditional **quit and reopen** path. A successful JSON write projects the manual choice into **the application's** Cocoa `AppleLanguages` default; System Default removes that app override. Failed/no-op/protected saves do not project a new language. The global language order is read separately so System Default does not accidentally resolve this app's manual override. The valid JSON preference is authoritative and reconciled at launch; unreadable configuration does not authorize overwriting defaults/configuration. No system language is written, no automatic quit/relaunch and no Bundle swizzle/package.

Apple documents the app/global domain separation, precedence and language key in [About the User Defaults System](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/AboutPreferenceDomains/AboutPreferenceDomains.html). Projection is tested in an isolated suite, not the real app domain. JSON and Cocoa defaults are separate stores: actual relaunch/native-menu acceptance, including interrupted projection repair and externally changed system order, remains open. Compilation or a language-configured test host does not establish that whole production path.

## Software/native geometry evidence

Environment: Apple Silicon macOS 27.0.1, Xcode 27.0 / Swift 6.4 / SDK 27; macOS 26 target and strict concurrency retained.

- `apps/rebind/scripts/dev.sh test -resultBundlePath build/InputLanguageFinal.xcresult`: **539 Swift Testing tests / 73 suites + five native XCTest tests, 544 total; zero failures; TEST SUCCEEDED**.
- Full main Settings checks now cover **352 combinations** (11 states × four locales × Light/Dark × four sizes), including Input, Language, pending reopen and protected storage. Native split and both columns must fit the viewport. Earlier 72 rules and 264 General combinations remain.
- Additional permanent native coverage: **32** Input/Language standard Settings combinations (600 × 480 and 760 × 600); **16** language failure and **48** Hold-editor combinations (100/575/5,000 ms, EN/RU/DE/FR, Light/Dark, two sizes). Checks include actual scroll bounds/document width and requested window size.
- After final popup alignment and duplicate AX-name repair, `apps/rebind/scripts/dev.sh test -only-testing:apps/rebind/rebindTests/MainWindowLayoutTests -only-testing:apps/rebind/rebindTests/InputLanguageLayoutTests -only-testing:apps/rebind/rebindTests/LanguageSettingsTests -resultBundlePath build/InputLanguageCleanFinal.xcresult`: **four XCTest tests + nine Language test functions, zero failures; TEST SUCCEEDED**. This uses the normal product/bundle identifier, with temporary helpers/guard removed.

The initial build exposed a catalog-name/Int32 placeholder mismatch, corrected before successful tests. A duplicate derivedDataPath inspection command and a missing return in the temporary identity guard also failed; neither is acceptance evidence. The final normal build/tests use the corrected production source.

## Live isolated inspection

Only authored temporary configurations were changed. Fixtures never started the engine. An ambiguous tool selection showed an ordinary Rebind window once; no controls/actions were used there and it was left alone. Subsequent inspection used a separate output directory and temporary `blinks44.rebind.verification.Rebind` identifier, with an explicit guard preventing real configuration loading/runtime startup even if the UI tool launched that verification bundle. Production project settings were unchanged. The helper and guard were removed afterward; build/result output is ignored.

Inspection commands used `apps/rebind/scripts/dev.sh test CONFIGURATION_BUILD_DIR=<repo>/build/InputLanguageVerificationProducts/Debug 'PRODUCT_BUNDLE_IDENTIFIER=blinks44.rebind.verification.$(PRODUCT_NAME:rfc1034identifier)' 'INFOPLIST_KEY_CFBundleDisplayName=Rebind Verification' -testLanguage fr|ru -test-timeouts-enabled YES -default-test-execution-time-allowance 360 -maximum-test-execution-time-allowance 360 -only-testing:apps/rebind/rebindTests/InputLanguageVisibleInspectionTests/<method> -resultBundlePath <bundle>`; stop flags ended the bounded manual holds. Passing results: `build/InputHoldDistinctFrench2.xcresult`, `build/InputLanguageDistinctRussian.xcresult`, `build/InputLanguageFinalAccessibility.xcresult`. Earlier short visible holds also passed but missed parts of the interaction; they are not substituted for the checks below.

Agent-observed:

- French Hold editor: named Stepper with value/hint, **575 → 675 ms** via native Increment; Save failed against an intentionally unwritable fixture, retaining 675 ms and both footer actions. After making only that test store writable, retry saved 675 ms and dismissed the editor. File readback confirmed French preference and pause unchanged. French native menu titles were observed in a French-language test-host launch; actual production projection/relaunch remains separate.
- Russian Dark full main: Input → Language, all five popup choices/autonyms, Français draft, explicit Apply, saved French/current Russian/reopen feedback. File readback and fixture result confirm `saved=fr active=ru reopen=true`; no real preference/grant/rule change. Interactive resize **1040 × 640 → 880 × 600** retained the header, sidebar, popup and guidance.
- Final native popup AX description is exactly one **“Язык приложения”**, selected value separate. The earlier explicit accessibility label duplicated the inherent name; it was removed and the duplicate visible-label AX node hidden. Spoken VoiceOver/focus acceptance is not inferred from AX output.

Reviewed live capture states: Input Dark RU, Language Dark RU, reopen Dark RU, compact reopen, French editor failure/retained 675 ms. Screens include title-bar chrome and may show inactive-window dimming. Partial offscreen editor/failure caches are excluded from visual acceptance.

## Artifact and remaining acceptance

- `apps/rebind/scripts/dev.sh release`: **BUILD SUCCEEDED**, universal `x86_64 arm64`. Debug/Release pass `codesign --verify --deep --strict`. Final normal bundle ID `blinks44.rebind`; target/scheme/module/product unchanged. Temporary helper, identity guard and build-setting overrides are absent from production source/project.
- Executable SHA-256: Debug `dc9a13230d1a5376fbe9d3f58df881f2d0dacac66d2fa7c450b2c203a74e027b`; Release `f899d208e72f0888989d43627ba1ae334b2cee97bc310106e597e849e247b341`.
- Live main transitions/resizing still emitted AppKit negative-size warnings (62 occurrences in each inspected Russian run); no observed overflow. Static final geometry tests did not emit that warning. Cause isolation remains open, rather than declaring all runtime geometry warning-free.

Still open: actual quit/relaunch across main/standard Settings/Menu Bar and native panels; production Cocoa projection/repair; full keyboard/focus/spoken VoiceOver and accessibility preferences; remaining native Dark/editor/error states; physical hold timing/safety matrix; macOS 26/Intel execution and stable signing/TCC. General real login and its AppKit transition warnings remain independently open. Current Sketch materials/full desktop hierarchy are not certified by this functional slice.

Next: verify the saved language through an actual user-controlled quit/reopen on the identified normal bundle; independently implement the ready Advanced behavior once its design handoff is released. Preserve the full-main geometry coverage for every added Settings section.

### AppKit diagnostic follow-up: 2026-10-11

The previously open negative-geometry warning is now [isolated to AppKit’s window-sharing indicator during Computer Use inspection](appkit-sharing-indicator.md). No production layout change follows from that diagnostic. Existing geometry/visual evidence remains scoped as recorded; actual restart and accessibility checks remain open.
