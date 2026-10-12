# UI-020 — Profile material comparison completed; shared Rebind selector retained

- Updated: 2026-10-12
- Stage: done (bounded comparison and cleanup)
- Owner: Unassigned; released by `/root`
- Ownership checked: 2026-10-12, main `7921b98`; unrelated Language refinement preserved.
- Owned surfaces: Keyboard profile row, `ProfilePicker.swift`, opt-in symbol/single-line configuration in `EditorMenuSelector.swift` and `EditorSelectorLabel.swift`; scoped task/status/history records.
- Requirements: SPEC §§3.3, 10–11, acceptance D2; PLAN phase 8.
- Code baseline: main `7921b988a9274b3fc1efc141e3c1d328f7a97a5a`; uncommitted work, no agent commit.

## Outcome and acceptance

The user accepted the Paper/Rebind comparison as successful and selected the existing Rebind Liquid Glass component. The compared build/version was not explicitly identified; this is a visual/material choice, not hardware or accessibility acceptance.

The Keyboard screen retains one `EditorMenuSelector` using the existing `EditorGlassSurface`. Its optional house symbol and single-line label keep profile names within the 192 pt capsule. Other callers retain their defaults. Profile selection still uses `AppModel.selectProfile` and protected-storage disabling. The labeled management button is restored; Mouse/Trackpad keep their existing pickers.

`PaperProfileSelector.swift` and `PaperProfileSurface.swift` were deleted. Comparison labels, duplicate selector, style flags and Paper gradient/rim/shadow code were removed. No production engine, configuration, dependencies, permissions or translations changed. No active Paper source exception remains.

- [x] User comparison choice recorded within its evidence limits.
- [x] Existing shared control retained; duplicate/custom Paper implementation removed.
- [x] Final Debug build, signature and scoped profile/layout checks pass.
- [x] Current records updated; broader native/runtime gates remain in existing tasks.

## Historical experiment

Live [Paper Rebind / Page 1](https://app.paper.design/file/01M4KM1NZ1KBAW19C5FNYVPJM0/p-1-0), artboard `01 · Keyboard · Work / Light`, component `Profile selector · Work / Liquid Glass`, was inspected through MCP on 2026-10-12. JSX/computed values supplied the initial native adaptation; screenshots were only for review. Neither Paper nor Sketch was edited or saved.

Initial single-Paper Debug/signature, six tests/72 viewports and scoped no-engine Light/menu-opening review passed. A subsequent side-by-side experiment had identical content/menu/geometry with Paper left and existing Rebind material right; Debug/signature, 72 viewports and live AX checks passed. Further automated screenshots/menu selection/Dark review were not executed because approval service returned `429 Too Many Requests`. Those limits are not converted into manual accessibility or runtime passes by the user's visual choice. The experimental sources/artifacts are superseded by the final shared-control implementation below.

## Final cleanup verification — 2026-10-12

Agent-observed on Apple Silicon macOS 27.0.1 (26A434), Xcode 27 / Swift 6.4 / SDK 27:

- `scripts/dev.sh build`: passed.
- `scripts/dev.sh test -only-testing:rebindTests/AppModelProfileTests -only-testing:rebindTests/MainWindowLayoutTests/testPermissionNoticeDoesNotExpandNavigationBeyondTheWindow -resultBundlePath /tmp/rebind-shared-profile-final.xcresult`: six functions, zero failures; 72 native window viewports across EN/RU/DE/FR, three sizes, injected permission states and empty/populated rules. Profile software checks cover failed-save rollback, pause preservation, stale-editor/recording cancellation and corrupt-file protection.
- `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app`: passed. Final Debug implementation dylib SHA-256 `65e05cd955b57a4442b5068db9c98f2ef7c5ca220651f5dcee65744adae0d64d`.
- Repository source scan has no remaining Paper selector/surface/comparison-style references. `git diff --check` passes; links/current status reviewed. No new live UI/hardware/accessibility check claimed for cleanup; earlier experiment captures are not final-artifact evidence.

## Next step

Continue normal shared-control adoption and broader native menu/focus/VoiceOver/adaptive verification through UI-011/UI-016. The Paper experiment is closed; no comparison or custom material needs implementation. Historical local review bundles are superseded and must not be used as the current production build.
