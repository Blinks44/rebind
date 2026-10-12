# Advanced Settings feedback adoption

Date: 2026-10-12. [UI-007](../tasks/UI-007-advanced-settings.md), `main` / `a6471db` plus uncommitted Advanced view, SettingsActionCard, shared success severity/asset and layout-fixture changes. Xcode 27.0 (27A266a), Swift 6.4, SDK 27; Apple Silicon MacBook Air, macOS 27.0.1 (26A434). No agent commit.

## Source and implementation

Live Sketch MCP resolved Rebind.sketch document `C7326969-08D8-4B1C-8899-AA9277A9763D`, API 2.0.0. Inspected Advanced overview/error/protected trees, the paired Advanced action-card sources and Foundations 05/15 behavior/accessibility annotations. Screenshot-reviewed Light overview/import completion/validation, Dark invalid backup and shared semantic specimens. Read the current success swatches/styles directly. Sketch was read-only; no exports or saves.

Advanced composes existing PermissionCard raised surfaces, EditorSecondaryButton and EditorFeedback. SettingsActionCard centralizes its repeated neutral cards with the source's 8 pt spacing and 16 pt inset. Failures are red, protected-original guidance amber, successful import/reset/export green, and validation/reopen guidance blue. The additive success case reuses PermissionSuccess icon color and adds the source's opaque Light/Dark success surface. Titles and native icons communicate state independently of color; recovery controls retain the accent.

Feedback sits after the affected operation: backup results precede reset; reset completion/write failure follows reset. Protected-original export results follow protected recovery. Validation uses native indeterminate progress; transfer controls are hidden during validation and reset remains disabled with its existing explanation. Existing dialogs, cancellation/retry, storage protection, language reopen, engine, permissions and all four translations are unchanged.

Native differences: operation cards stay available beside feedback rather than being replaced by it, preserving the existing routes without adding dismissal/model behavior. Shared native circle symbols and semantic typography replace drawn source specimens. Reviewed plain-language catalog adoption remains separate in UI-018; current Advanced labels still use the existing translated keys. This slice does not certify sidebar/main or whole Settings fidelity.

## Final software and artifact checks

- `scripts/dev.sh doctor`: original scheme/targets and toolchain confirmed. The first sandboxed build failed at Icon Studio export because macOS build services were unavailable; the ordinary service-enabled `scripts/dev.sh build` passed. A local review fixture initially lacked LoginItemServiceStub; adding its existing test stub fixed that fixture build.
- `scripts/dev.sh test -only-testing:rebindTests/AdvancedSettingsLayoutTests -only-testing:rebindTests/AdvancedSettingsTests -only-testing:rebindTests/MainWindowLayoutTests/testSettingsDoesNotExpandNavigationBeyondTheWindow -resultBundlePath build/AdvancedFeedback-final.xcresult`: **14 test functions / 34 executions, zero failures/skips**, finalized xcresult summary reviewed. No full-suite rerun claimed.
- Native matrices cover **192 Advanced viewports** (12 states × four languages × Light/Dark × two sizes), **16 Settings/diagnostics viewports**, and **512 full-main Settings viewports** including actual split/column bounds. New fixtures exercise exported, incompatible backup, failed import write, stale review and reopen guidance using authored temporary stores and no language-default projection.
- Existing behavioral tests preserve atomic paused replacement, rollback/retry, cancelled/stale review rejection, exact protected-original export, safe alert default, count localization and pending-output/release ownership. These are injected checks, not physical remapping or production import/login evidence.
- `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` passes. Executable SHA-256 `7c29c6b3660efc35d64c3c5d192d0f079cb28464e2425be79d3b9b10dd9625ec`; implementation dylib SHA-256 `e2c1f3774349625c5f4838a6937b695afe6a820828bcaa1853cf744881af8862`.
- Final source/asset diff and local links reviewed; `git diff --check` passes. Local fixture output is covered by the existing narrow ignore rule; new app assets/source/evidence remain visible to Git. Independent Trackpad completion and subsequent focus-confirmation records were preserved.

## Isolated live review

Computer Use reviewed a separate local bundle `blinks44.rebind.verification.advanced`, built from the current app sources. Its UI-only entry point uses authored temporary data, the existing stub login service, injected feedback/validation and an injected editor model; it never starts capture or projects language defaults. Only the local copied entry point/model-injection wiring differs from app code. Review controls affect that specimen only. The fixture was terminated after review; the production app was not operated.

Agent-observed: English Light overview/error, German compact Dark error/progress/protected-original/import success, and German compact Light success. Source materials, readable wrapping, distinct state icons and accent recovery controls were observed. AX exposes combined result text, independently named recovery buttons, native busy status and disabled reset during validation. Import success retains the explicit paused-state guidance. A transient capture error recovered after reconnecting to the same fixture. These injected screenshots do not prove actual operation timing, focus restoration, spoken VoiceOver or system adaptive preferences.

## Open acceptance and next step

UI-007 remains `awaiting_verification`; prior user-reported restoration/navigation happy paths remain valid within their recorded limits. Detailed production §15.12, keyboard traversal/focus restoration, spoken VoiceOver, Reduce Transparency/Increase Contrast/Reduce Motion, macOS 26 and Intel remain open. No new accessibility blocker was demonstrated in the scoped source/AX review; complete assistive-technology acceptance is not claimed. Shared component reuse limits styling risk; changed content height/order still needs focused native acceptance.

On the named Debug bundle, review Settings → Advanced at 880×600 and a larger size in the preferred language. Use Tab/Shift-Tab to reach diagnostics/transfer/reset/recovery, cancel a file panel and verify focus returns. With VoiceOver, read feedback once and reach its separately named recovery button; verify progress and disabled reset are understandable. Check the same surfaces with the three accessibility preferences. Use disposable authored profiles for any destructive restore/reset walkthrough.

Next implementation: adopt the remaining Input/settings surfaces and reviewed copy from live Sketch, preserving these common components and keeping hardware/runtime acceptance separate.

## User verification follow-up — 2026-10-12

The tester reports that the requested Advanced checks work. The preceding handoff named Tab/Shift-Tab traversal, focus return after cancelling a file panel and VoiceOver. Record this as bounded user-reported acceptance of that walkthrough. Individual control/state results, language, accessibility preferences and the running artifact digest were not restated; do not infer exhaustive coverage or relabel it as an agent-observed audit.

Preserve this confirmation rather than repeating the same broad check without a new concern. System adaptive preferences, minimum-OS/Intel and detailed artifact-specific §15.12 remain separate. No code change, new build/test, production operation or Git commit was performed for this follow-up. Next implementation: remaining Input/settings surfaces and reviewed copy from live Sketch.
