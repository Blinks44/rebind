# Settings control adoption — native and software evidence

Date: 2026-10-12. [UI-017](../tasks/UI-017-settings-control-adoption.md), `main` / `59f5754` plus this uncommitted slice and preserved editor/design work. Xcode 27.0 / Swift 6.4 / SDK 27; Apple Silicon macOS 27.0.1 (26A434). macOS 26/Intel runtime remains unverified.

## Source and implementation

Fresh live Rebind.sketch discovery retained document `3D0EE4BC-3EE5-45C9-97A0-E4DCAF4414AE`. Read Foundations 14 annotations, Light/Dark Language Screens 40/41 and failure/reopen Screens 46/47 trees, native Settings-track geometry and selected component. Screenshots reviewed live; no Sketch edit/export. [DESIGN](../DESIGN.md) locates the saved revision.

SettingsSectionPicker replaces incidental native segmented artwork with the released single passive glass track: 35 pt height, 4 pt inset, 27 pt targets, quiet accent selection and no implicit transition. Section-specific minimum widths preserve source proportions; localized text can expand. ViewThatFits retains a complete compact native menu when the track cannot fit. Native Buttons, focus/arrow handling with disabled guard and a public radio-group accessibilityRepresentation preserve value semantics on macOS 26; no macOS 27-only tabs API.

EditorMenuSelector/EditorSelectorLabel add an opt-in compact size (24 pt, 12 pt side inset); existing editor defaults remain 36/16. Language uses the anchored native menu with five existing choices and unchanged autonyms, draft/apply/storage/reopen model. Apply uses the shared secondary button. Storage/save errors and reopen information use existing shared semantic feedback and translations. General, Permissions, Input and Advanced behavior/body styling remain outside this bounded correction; all five share navigation. No engine, package, schema, catalog, login behavior or production setting change.

## Final checks

- `scripts/dev.sh doctor`: actual toolchain/project confirmed. Ordinary Debug build with `scripts/dev.sh build` succeeds; minimum macOS 26, Swift 6 complete checking and production identity retained.
- `scripts/dev.sh test -only-testing:rebindTests/MainWindowLayoutTests/testSettingsDoesNotExpandNavigationBeyondTheWindow -only-testing:rebindTests/InputLanguageLayoutTests -only-testing:rebindTests/LanguageSettingsTests -only-testing:rebindTests/MouseBindingEditorTests -only-testing:rebindTests/TrackpadBindingEditorTests -resultBundlePath build/SettingsControlAdoption.xcresult`: **29 functions / 89 expanded executions**, zero failures/skips/runtime warnings. Native matrices cover **416 full-main viewports** (13 Settings states × four locales × two appearances × four sizes), plus **128 standalone Settings/failure/Hold-editor viewports**. Assertions check actual split/native columns and scroll bounds, not full accessibility. Existing tests cover draft discard/no-op/failure retry, protected storage, language activation/projection and editor validation. No new framework or implementation-mirroring tests.
- Final ordinary Debug and `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` pass. Executable SHA-256 `014ae08ccd56316b73b4e1836c693f177c63111fd0e12a8b71bc3aecb17da38d`; implementation dylib SHA-256 `0646c205fc10cc89a3c863448f3283b195da0d9bcff658f230ed7118ac64d2f0`. No agent commit. Logs/results/review bundle remain ignored.
- Affected relative links and `git diff --check` pass. Shared defaults reviewed against existing editor call sites; no copied third-party source or assets.

## Isolated live review

A distinct bundle `blinks44.rebind.verification.settings` uses authored temporary storage, stub login service/permissions, a no-op language-default projection and an entry point that never starts input capture. General remapping toggle was never enabled. Old fixture was explicitly closed/relaunched after a sizing-fixture correction: compact mode now resizes the actual NSWindow rather than fixing the root SwiftUI frame. The earlier clipped fixture is not a product-layout failure or accepted compact evidence.

Agent-observed final review:

- All five sections open, selected AX radio value follows the visible page and track position remains stable across navigation.
- Light standard and Dark actual compact 880-wide windows reviewed, including German labels and Language content. No truncated tab labels/overlapping feedback in this setup.
- Native Language menu exposes System/English/Russian/German/French. Selecting Français changes only the draft; active language remains English. Leaving Language discards the unapplied draft. Applying in temporary storage shows the saved-language/reopen information.
- Injected write failure retains selected draft, current active language and retry Apply control; Dark German error title/body/icon are readable in the compact viewport.
- Escape dismisses the menu without changing value and returns AX focus to the selector. Down opens the focused selector; two subsequent Down presses and Return select English and leave focus on the selector. Floating menu rendering was omitted by the screenshot bridge, so menu pixel alignment is not newly certified here; prior anchor evidence and current AX/keyboard behavior are distinct.

No actual input, production rules/configuration, login registration, permissions, system language/accessibility settings or reset/import/export were changed. No real production relaunch was performed.

## Open acceptance and user checks

Full tab/activation Tab/Shift-Tab/arrow focus, held-click transient behavior, VoiceOver spoken selected/disabled state, accessibility preferences and macOS 26 remain open. Source implements opaque/contrast fallbacks and removes decorative selection animation, but code/build do not certify those runtime checks. The narrow Settings fallback is covered by native sizing tests; live fallback-menu traversal remains open.

On the named ordinary build, first quit the older Rebind instance and open the freshly built bundle. Check all five Settings sections and resizing; open Language and cancel with Escape; check keyboard focus/arrow selection when macOS Keyboard Navigation is enabled; review editor activation/popup alignment. Report any shifted control, clipped label or lost focus and the language/appearance/window size. Keep physical-input acceptance separate; Magic Mouse acquisition/coexistence is deferred until hardware is available, then follow the [source audit](../research/touch-library-audit.md).

Next independent implementation: continue remaining Settings feedback/recovery and main/profile navigation materials from current live Sketch; preserve current models and full-main sizing.

## Shared material/focus follow-up

The final [shared-component fidelity artifact](editor-design-adoption.md#shared-components-and-sketch-fidelity--2026-10-12) uses the quieter Light tint/source text colors and preserves native active/inactive adaptation. Its combined 94 runs/848 viewports and Debug/signature pass cover the shared Settings impact; final live review focused on editors. Earlier Settings/menu live checks remain evidence for their earlier artifact, not a newly repeated runtime pass.

[Latest UI-016 evidence](editor-design-adoption.md#shared-components-and-sketch-fidelity--2026-10-12) supersedes the shared regular material and unconditional menu-focus restoration above. Native Clear/tint on the opaque canvas now follows the lighter source; pointer activation no longer forces a keyboard ring. Final combined 94 runs / 848 viewports, Debug/signature and scoped Light/Dark live checks pass on the named latest artifact. Final keyboard restoration/VoiceOver/preferences remain open; the earlier language-menu keyboard pass covers its earlier artifact only.
