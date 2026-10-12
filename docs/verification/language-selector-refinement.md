# Language selector refinement — native evidence

Date: 2026-10-12. [UI-019](../tasks/UI-019-language-selector-contrast.md), `main` / `7921b98` plus this uncommitted slice (EditorGlassSurface, EditorMenuSelector, LanguageSettingsView and three CompactSelector color assets). Xcode 27.0 / Swift 6.4 / SDK 27; Apple Silicon macOS 27.0.1 (26A434), deployment target macOS 26. No agent commit. Concurrent UI-020 profile-selector edits appeared after the named final build; they were preserved and are outside this evidence.

## Source and implementation

Fresh live MCP discovery: Rebind.sketch `C7326969-08D8-4B1C-8899-AA9277A9763D`, Sketch 2026.3.1/API 2.0.0. Read Foundations 14 native annotations, compact Light/Dark symbol geometry/styles, Language menu/reopen trees and Light/Dark/default/French/failure screenshots. The released source specifies a 24 pt capsule, cool surface tint, 1 pt neutral edge and soft Light shadow. No Sketch edits or exports.

EditorGlassSurface/EditorMenuSelector add an opt-in `distinctSurface`, enabled only by LanguageSettingsView. Three adaptive asset pairs use source colors: surface F0F1F5/343640, edge 8996AA, Light shadow 19263B at 14% (Dark clear). Native Clear glass supplies interaction; the scoped surface remains opaque with Reduce Transparency and the edge uses primary text contrast under Increase Contrast. The edge is separate from native keyboard focus. Unchanged shared defaults preserve editor and narrow Settings menus. Existing draft/apply/storage/reopen semantics, autonyms, localization and native menu/focus implementation are reused.

Native rendering is not an exact reproduction of Sketch's custom optical model; its inner lighting remains system-owned. No custom blur/dependency. Availability/reference reviewed against [Apple Glass](https://developer.apple.com/documentation/swiftui/glass) and the installed macOS SDK; minimum OS unchanged.

## Final checks

- `scripts/dev.sh doctor`: Xcode/Swift/SDK/host/project confirmed. Initial sandbox build could not export AppIcon.icon; the same standard build succeeded after approved execution with Xcode's required service access.
- `scripts/dev.sh test -only-testing:rebindTests/MainWindowLayoutTests/testSettingsDoesNotExpandNavigationBeyondTheWindow -only-testing:rebindTests/InputLanguageLayoutTests -only-testing:rebindTests/LanguageSettingsTests -resultBundlePath build/LanguageSelectorRefinement.xcresult`: **12 functions / 49 expanded executions**, zero failures/skips/xcresult runtime warnings. Native layout matrices exercise **608 viewports**: 512 full-main and 96 standalone Input/Language/failure/Hold-editor views across EN/RU/DE/FR, Light/Dark and multiple sizes. Existing tests also cover language resolution/migrations, no-op/discard, failed-save retry, protected storage and reopen activation. These are injected/native layout checks, not hardware or VoiceOver evidence; no new tests/framework.
- Final ordinary `scripts/dev.sh build` (12:56 local) and `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` pass. Executable SHA-256 `62bdca3e2cfca2459d6eee4a41b760c93a5115cf7e576a04a28f7c1b3b1604fd`; implementation dylib `d56aa456399445508089817565a687ad6f03344829b188185a50426a17723afd`. The shared Debug output was subsequently replaced by the concurrent UI-020 build; these hashes identify this verification's earlier artifact, not the current shared bundle. Build reports the existing no-AppIntents metadata-extraction notice; no compile failure. Logs/results/fixtures remain local and ignored.
- Affected links/statuses and `git diff --check` pass; adaptive assets remain visible to Git.

## Isolated live review and limits

An ignored separately built fixture (`blinks44.rebind.verification.language`) uses temporary authored disabled configuration, stub permissions/login service and a no-op language-default projection. Its entry point never starts capture. Agent-observed AX state shows Language selected, the selector's label/value (`App language` / `System Default`) and existing help/active-language text. The native Light screenshot shows a distinct cool compact surface, neutral edge and soft shadow against its raised card, without clipping.

The fixture remains at `.local/agent-context/verification/language-selector-review/build/DerivedData/Build/Products/Debug/Rebind.app`; its signature verifies. It is separate from concurrent changes to the shared Debug output and can support the remaining scoped user review.

The automated approval service intermittently rejected operations with `429 Too Many Requests` / exhausted retries. The initial test request was not executed; a subsequent properly reviewed retry passed after the service recovered. Further computer-use requests, including the menu-opening click and a later read-only state refresh, remained rejected. No bypass and no inference that those actions occurred. The fixture may remain open for review.

Native Dark, open-menu pixels, keyboard Escape/Down/Return and focus restoration, disabled interaction, VoiceOver and actual Reduce Transparency/Increase Contrast/Reduce Motion preferences remain open. Light/Dark bounds tests do not establish material fidelity. macOS 26/Intel and production language relaunch remain unverified. No production rules/preferences, permissions, login registration or remapping were changed.

Next: use the isolated Language fixture's Dark/Compact controls to review both appearances, open/cancel the menu and verify keyboard focus. Disabled/VoiceOver/adaptive preferences remain separate checks. Identify a fresh production artifact before broader acceptance; the shared output can change during UI-020's concurrent profile-selector work. Further adoption must inspect the current source and ownership.
