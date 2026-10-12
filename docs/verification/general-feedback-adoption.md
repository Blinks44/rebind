# General feedback adoption — native and software evidence

Date: 2026-10-12. [UI-003](../tasks/UI-003-general-settings.md), `main` / `59f5754` plus uncommitted General changes and preserved editor/design work. Xcode 27.0 (27A266a), Swift 6.4, SDK 27; Apple Silicon macOS 27.0.1 (26A434). No agent commit.

## Source and scope

Fresh Sketch MCP discovery: Rebind.sketch, document `3D0EE4BC-3EE5-45C9-97A0-E4DCAF4414AE`, Sketch 2026.3.1/API 2.0.0. Read General recovery/approval trees, Light/Dark General Toggle sources, Foundations 04/14/15 and their native/accessibility annotations. Screenshot-reviewed Screens 24/25/26/28/32 and shared semantic examples. No Sketch edits or exports; [DESIGN](../DESIGN.md) locates the saved source.

General reuses EditorFeedback and EditorSecondaryButton: runtime failure and failed login operations are red; missing access, protected configuration and unavailable/approval login states are amber; busy login operations are information with native progress. Active/paused/starting/protected-session states keep their existing neutral presentation. Descriptions, actual-state models, cancellation, retry routes and all four translations are unchanged. Protected-file guidance appears once, rather than repeating the same error below it. No engine, permission, login-service, schema, package or production configuration change.

Native differences: the existing shared feedback places recovery actions below the message, including at wide sizes. General status now scrolls with its content, keeping expanded localized feedback reachable without recreating the pinned-text minimum-height regression. Existing Check Again remains available alongside failed-operation recovery. This bounded change does not certify full Settings/sidebar material fidelity.

## Final checks

- `scripts/dev.sh doctor` confirms toolchain/project. A sandbox-only build failed to load the Observation compiler macro; ordinary Xcode service access resolves it. Final `scripts/dev.sh build` passes with original target/scheme/module/bundle settings.
- `scripts/dev.sh test -only-testing:rebindTests/GeneralSettingsLayoutTests -only-testing:rebindTests/MainWindowLayoutTests/testSettingsDoesNotExpandNavigationBeyondTheWindow -only-testing:rebindTests/GeneralSettingsTests -only-testing:rebindTests/GeneralRuntimePresentationTests -only-testing:rebindTests/LoginItemModelTests -resultBundlePath build/GeneralFeedback-final-pass.xcresult`: **23 selected test functions, zero failures/skips**. Native matrices cover **312 General viewports** (13 states × four locales × two appearances × three sizes) and **416 full-main viewports**, including actual split/column bounds. Existing behavioral checks cover actual login transitions, overlapping operations, explicit retry, failed-resume rollback and immediate emergency pause/suppressed-release ownership after failed persistence. These are injected software checks, not hardware/login evidence.
- General fixtures now include protected configuration and save failure, each with an independent temporary store. The first expanded run correctly rejected reuse of the protected original by the following fixture; isolation was fixed and the full selected run repeated successfully. Attempts to inject accessibility Environment values did not compile because those SDK values are read-only; the unsupported overrides were removed. Actual adaptive-preference acceptance remains open.
- Final `codesign --verify --deep --strict build/DerivedData/Build/Products/Debug/Rebind.app` passes. Executable SHA-256 `109e2394f9223ecf6b0800fa44535ce5b75e45cb28e44436cb88a8816269193b`; implementation dylib SHA-256 `0003df5a58b1bab384d0a16a3faffb028ff4efbe1d053017151976a7b200aed1`.
- Test-host logs include system App Intents/autoShortcut service connection messages. No test assertion or final compilation failed. Cached images confirm opaque feedback surfaces but omit parts of accelerated window rendering; they are not whole-window visual evidence.
- Final scoped source diff, affected local links and `git diff --check` pass. Existing work is preserved; no staging/commit or new exclusion rule. Implementation ownership is released in UI-003.

## Isolated live review

A distinct local bundle `blinks44.rebind.verification.general` uses a UI-only entry point, temporary authored configuration, stub login/permission states and no language-default projection. It never starts capture. Current app sources/components are copied into the ignored fixture; only its entry point and bundled stub differ. The fixture was closed after review; the running production app was not operated.

Agent-observed through Computer Use: English Light runtime failure, German Dark compact login approval/failure, and compact save-failure scrolling. No overlapping feedback or clipped recovery text was observed in these states. Retry and Check Again retain the injected failed login state; AX exposes combined state text and separate named recovery buttons. Scrolling reaches the complete save-error block while Settings navigation remains visible. Four-language native test images additionally show readable French removal-failure and Russian protected-file/approval blocks. No actual registration, permissions, production rules, remapping, system language or accessibility preference was changed.

## Open acceptance / next step

Real login/approval/removal/relaunch, full Tab/Shift-Tab and spoken VoiceOver, Reduce Transparency/Increase Contrast/Reduce Motion and macOS 26/Intel remain unverified. Review Settings → General in the named ordinary build in the user's preferred language, resize it and check keyboard/VoiceOver traversal. Continue independent Settings → Permissions feedback/material adoption from live Sketch using the same components; keep actual permission-grant checks separate.
