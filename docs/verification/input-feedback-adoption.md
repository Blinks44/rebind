# Input Settings material and copy adoption

Date: 2026-10-12. [UI-004](../tasks/UI-004-input-settings.md). Started on `main` / `a6471db` with existing Advanced UI and Trackpad notes preserved; implementation was committed externally in `2bc4b97` during review. No agent commit. Xcode 27.0 / Swift 6.4 / SDK 27; Apple Silicon MacBook Air, macOS 27.0.1 (26A434).

## Source and result

Live Sketch MCP resolved Rebind.sketch `C7326969-08D8-4B1C-8899-AA9277A9763D`, Sketch 2026.3.1 / API 2.0.0. Inspected Input Light/Dark and RU/DE/FR compact compositions, paired shared Information rows, Hold duration source and Foundations 04/14/15. Screenshot-reviewed Light/Dark Input, compact German and Hold source. Sketch remained read-only.

Input reuses raised PermissionCard and adaptive PermissionStatusLabel instead of duplicating their surfaces/status layout. Existing 16 pt section gaps, 12 pt card gaps, 16 pt card insets and wrapping descriptions remain. Nine scoped EN/RU/DE/FR catalog entries adopt prepared plain-language copy and explicitly identify fixed mouse sensitivity. Catalog comparison confirms all unrelated entries remain unchanged and all affected translations are complete.

The final Sketch touch row depicts Trackpad and Magic Mouse. Current native behavior supports only the experimental built-in Trackpad tap pool, so its heading/status retain that scope. The stale four-finger-only description now explains choosing single/double taps with three/four fingers to send a shortcut and retains simultaneous macOS gesture guidance. This is a documented capability difference, not new support or suppression. Hold Stepper, save/retry, storage, engine, language activation and permissions are unchanged.

## Checks and artifact

- `scripts/dev.sh doctor`: existing targets/scheme and toolchain confirmed.
- `scripts/dev.sh build`: final Debug passes. Initial sandbox build failed because Swift macro plugin services were unavailable; service-enabled build passed. No product workaround was introduced.
- `scripts/dev.sh test -only-testing:rebindTests/InputLanguageLayoutTests -only-testing:rebindTests/InputHoldSettingsTests -only-testing:rebindTests/LanguageSettingsTests -only-testing:rebindTests/TrackpadBindingEditorTests -only-testing:rebindTests/MainWindowLayoutTests/testSettingsDoesNotExpandNavigationBeyondTheWindow -resultBundlePath build/InputAdoption-final.xcresult`: **20 functions / 74 executions, zero failures/skips**. Final xcresult summary reviewed; no full-suite rerun claimed.
- Native bounds matrices cover **608 viewports**: 32 standalone Input/Language, 64 Language-failure/Hold-editor, 512 full-main Settings with actual split/column bounds. Behavioral tests retain failed Hold draft/retry, language storage/reopen and preset selection/conflict constraints. Injected checks do not establish physical timing.
- `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` passes. Executable SHA-256 `89d38774b5dc9dec27bb08816c80938c0da775541cac516aa1373a2f3aa719dd`; implementation dylib `93daf435dc3ca1b6a16191b80eac3960b465d58ce0e2120207c316d4db6ef793`.
- Current production source/catalog matches the snapshot used for isolated native review, apart from the review entry point and existing login-service stub. Source changes were preserved across the external commit. Final links and `git diff --check` reviewed; local fixture remains under the existing narrow ignore rule.

## Native review and limits

Computer Use reviewed a separate local `blinks44.rebind.verification.input` bundle using authored temporary configuration, stub login service and an entry point that never starts capture or projects language defaults. Observed English component Light/Dark, English full-main Light and compact German full-main Light/Dark: raised materials, readable status lanes and wrapped descriptions match the scoped source roles without clipping. Native semantic typography renders the reused headings heavier than drawn Sketch specimens; the existing full-main toolbar/sidebar and vertical origin remain outside this slice. AX exposes each title/status together as a heading. Spoken VoiceOver is not claimed.

The fixture's first build attempted to inject read-only system accessibility environment values; removing those local-only controls fixed the fixture build. No adaptive-preference test is claimed. Computer Use reconnection and stale-state guards interrupted the additional Russian live selection; RU/FR are covered by the automated native layout matrix, not a completed live walkthrough. The review fixture was quit afterward. No real rules, grants or remappings were operated.

Bounded implementation is complete. UI-004 remains `awaiting_verification` for physical Hold timing/cancellation, spoken VoiceOver, focus and actual Reduce Transparency/Increase Contrast/Reduce Motion, macOS 26 and Intel. Next verification: open the named Debug bundle's Input at 880×600 in the preferred language, read the three headings/statuses/descriptions with VoiceOver and review the same cards under accessibility preferences. Next implementation: remaining main/profile/action materials and reviewed copy from live Sketch.
