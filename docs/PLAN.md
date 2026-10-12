# Rebind — roadmap

Updated 2026-10-12. Read [STATE](STATE.md) first for current facts and next tasks; [WORKFLOW](WORKFLOW.md) defines how to work. Product requirements remain in [SPEC](SPEC.md). No whole product phase is declared complete by these bounded deliveries.

## Immediate priorities

1. [INPUT-001](tasks/INPUT-001-four-finger-tap.md): delivery/click recovery/lifecycle subsets user-confirmed; post-repair walkthrough reports 10/10 taps, no delayed pause outputs and 5/5 fresh recovery. [Buffer safety](verification/trackpad-buffer-safety.md) and [callback guards](verification/trackpad-callback-generation.md) have injected recovery evidence. Controlled busy-consumer latency, quantified stress and full T1/T2 safety remain open. Preserve confirmed scenarios; do not substitute polish or blind threshold changes for remaining acceptance.
2. [UI-001](tasks/UI-001-permissions-onboarding.md): main-window clipping repaired; native layout/navigation/deferral and schema 23 pass. [Settings feedback adoption](verification/permissions-feedback-adoption.md) passes bounded software/native checks. Actual grant/revocation/accessibility and remaining setup/main material adoption stay open.
3. [BRAND-001](tasks/BRAND-001-icon-runtime.md): finish Dock/live Menu Bar/minimum-OS/tint acceptance. The icon and Menu Bar asset already exist; recreation is not the next step.

These are recommended next items, not authorization to run hardware actions or start other agents. The user's next task may select a different slice. Independent design and input work can proceed with explicit ownership.

Target-release clarification, 2026-10-11: complete the planned product functionality, including Trackpad/Magic Mouse, before release. Sketch designs the final product; temporary implementation gaps are not release-interface states. [UI-013](tasks/UI-013-design-coverage-completion.md) removes such placeholders and closes remaining design coverage. Native implementation and verification gates below remain open.

## Phase status and exit gates

The checked items below describe only the stated software/artifact milestone. An unchecked phase gate may have substantial existing implementation. Read [capability evidence](CAPABILITIES.md) and relevant verification before adding code.

### Phase 0 — Inventory, feasibility, dependencies

- [x] Existing Xcode project/toolchain inspected; native-first baseline and reviewed skills prepared.
- [ ] Finish input/action feasibility and actual hardware/performance/suppression evidence for supported claims. Physical-device routing is withdrawn, not a remaining gate.

### Phase 1 — First global remapping slice

- [x] Category-wide ordinary key/middle-extra mouse matching, bounded active tap, tagged one-shot shortcut output, editor, persistence and software tests exist.
- [x] User confirms G603 Control + Button 4 → Command+A in TextEdit and plain Button 4 passthrough.
- [ ] Verify physical keyboard delivery and the full release/suppression/permission/background safety walkthrough. [Evidence](verification/phase-1.md).

### Phase 2 — Robust keyboard/mouse

- [x] Software slices: discrete four-direction wheel, exclusive double/long press, four cardinal button-held pointer gestures, capture lifecycle, bounded opt-in mouse diagnostics.
- [x] Configured G603 hold/left gesture and basic pause/sleep/diagnostics happy paths are user-confirmed subsets.
- [ ] Finish hardware timing, other directions/modifiers, rapid events, cancellation/release/overflow, Secure Input/revocation and callback profiling. Caps Lock, Fn, left/right modifiers, held/repeating output remain deferred. [Capability evidence](CAPABILITIES.md).

### Phase 3 — Manual profiles

- [x] Independent rule sets, selection, CRUD/copy, atomic rollback/migrations and Menu Bar/main pickers; selected-profile output user-confirmed.
- [ ] Verify both selection routes, held-input switching, relaunch/paused state and other-language/accessibility checks. [Walkthrough](verification/profiles.md).
- Physical-device inventory, sender attribution and automatic profile activation remain outside scope.

### Phase 4 — Shared action catalog and system actions

- [x] Shared searchable catalog and real dispatch: shortcuts, audio/media/mouse output, AX windows/apps, selected app/web/file opening, Apple Shortcuts, Spaces and system operations. Specific happy paths are user-confirmed; private Dock/lock paths remain Experimental.
- [ ] Complete each advertised action's failure/cancellation, modifier/focus/player/display, protected-session, latency and macOS 26/Intel checks. Add remaining system actions only after their own capability research. [Evidence matrix](CAPABILITIES.md).

### Phase 5 — Compact trackpad scope

- [x] Pinned standalone acquisition probe, software recognition/sequencing tests and experimental integrated built-in four-finger tap → shortcut subset exist.
- [x] Rebuilt built-in four-finger tap → configured shortcut delivery user-confirmed with 25 queued/posted outputs; click-only exclusion and subsequent tap also user-confirmed in this setup.
- [ ] Finish measured timing/mixed-input click exclusion and lifecycle/stop/native conflicts before production claims. [INPUT-001](tasks/INPUT-001-four-finger-tap.md).
- [x] Bounded [three-finger single-tap engine/storage](tasks/INPUT-002-three-finger-tap.md) integrated alongside four fingers, with distinct shortcut routing and schema 25; engine software checks pass. Physical verification remains open.
- [x] [Three/four-finger double-tap engine/storage](tasks/INPUT-003-double-tap-engine.md) integrated with single/double arbitration and schema 26; engine software checks pass. Native/hardware acceptance remains open.
- [x] Bounded [tap preset editor](tasks/UI-014-trackpad-presets.md) adopts live UI-013 selection/independent output recording and conditional conflict guidance for four engine-backed presets. [Software/native evidence](verification/trackpad-preset-editor.md); physical/coexistence/accessibility acceptance and broader final UI remain open.
- [ ] Implement and verify remaining SPEC §3.4 scope: single 3/4, double 2/3/4, physical click 2/3/4, one-finger corners, deliberately curated modifier variants/actions and preset editing/conflict UX. Two-finger doubles and corners still require native integration.
- [ ] Verify external Magic Trackpad separately; raw contacts do not prove suppression. Swipes/pinch/rotation/five-finger gestures remain out of scope.

### Phase 6 — Magic Mouse

- [ ] Research/acquire on real hardware, establish touch/click/scroll coexistence, implement and verify only supported gestures. No current implementation or hardware claim.

### Phase 7 — Settings, storage, permissions, background

- [x] Versioned atomic storage, corruption/future-file protection, actual permission checks and window-independent runtime foundation exist.
- [x] Bounded first-run/recovery and Settings → Permissions integrated; actual-grant and full native acceptance remain open in [UI-001](tasks/UI-001-permissions-onboarding.md).
- [x] Bounded [General/background](tasks/UI-003-general-settings.md) with actual runtime, global pause and SMAppService integration; software/native fixture checks and [full-main overflow repair](verification/general-main-window-repair.md) pass; [General shared feedback](verification/general-feedback-adoption.md) also has software/native checks; actual login/relaunch/accessibility acceptance remains open.
- [x] Bounded [Input/hold](tasks/UI-004-input-settings.md) and [Language](tasks/UI-005-language-settings.md) native integration, schema 24 and software/full-window/live fixture checks pass; actual input/relaunch/accessibility acceptance remains open in [native evidence](verification/input-language-native.md).
- [x] Bounded [Advanced backup foundation](tasks/UI-008-advanced-storage.md): shared validated codec, in-memory legacy migration and size-bounded regular-file read; 553 tests / zero failures. Native flows remain separate.
- [x] Bounded [Advanced native integration](tasks/UI-007-advanced-settings.md): import/export, safe confirmation, paused atomic replacement/reset, protected-original export and diagnostics; 570 tests / zero failures, Debug/native cancellation/layout checks pass. Restored-binding/runtime/accessibility acceptance remains open in [evidence](verification/advanced-settings-native.md).
- [x] Bounded [About and licenses](tasks/UI-010-about.md) integrated with actual bundle identity and local native Find; software/native checks pass in [evidence](verification/about-native.md). Full keyboard/VoiceOver/accessibility preferences remain open.
- [ ] Implement justified future gesture tuning; complete Advanced SPEC §15.12 and broader About/Settings accessibility/runtime acceptance.
- [ ] Verify window reopening/single engine, relaunch/login, revoked access, lock/sleep/recovery and deliberate paused state. [Permissions](verification/permissions.md), [UI-001](tasks/UI-001-permissions-onboarding.md).

### Phase 8 — Complete modern native UI and brand

- [x] Bounded [Settings navigation/Language control adoption](tasks/UI-017-settings-control-adoption.md): stable inset track, compact menu and semantic feedback; [software/native checks](verification/settings-control-adoption.md) pass. Remaining Settings/main materials and full accessibility/platform acceptance remain open.
- [x] Bounded [Language selector refinement](tasks/UI-019-language-selector-contrast.md): opt-in source surface/edge/shadow integrated into shared controls; [49 runs/608 viewports, Debug/signature and Light review](verification/language-selector-refinement.md) pass. Dark/menu/focus/preferences acceptance remains open.

- [x] Bounded [shared editor design adoption](tasks/UI-016-editor-design-adoption.md): Mouse/Trackpad glass selectors, capture/keycaps, native activation and semantic feedback integrated; [software/native sizing and scoped live evidence](verification/editor-design-adoption.md) pass. Full Keyboard/Settings/main adoption and active-recording/accessibility/preferences/platform acceptance remain open.
- [x] Bounded [Mouse list/conditional editor](tasks/UI-009-mouse-design.md) integrated using existing capture/matching; draft/conflict/search and four-language size/live editor checks pass in [evidence](verification/mouse-native.md). Physical capture, accessibility and UI-011 material reconciliation remain open.

- [x] Live Sketch foundations/components and main/editor/profiles/About/first-launch designs exist; app icon and Menu Bar template are integrated artifacts; native `.icon` is the sole app-icon input after removal of superseded PNG sets.
- [x] [Final design coverage](tasks/UI-013-design-coverage-completion.md) saved/reviewed: curated Trackpad/Magic Mouse selectors, action parameters/recovery, profile/category states and four-language copy. Temporary implementation placeholders removed; native implementation remains open.
- [x] [Production design review](tasks/UI-015-production-design-review.md) covers all 125 screens and 28 source boards; reusable geometry, menu, Dark-appearance and state corrections saved/reviewed. Native adoption and acceptance remain open.
- [ ] Implement current Sketch desktop hierarchy and purposeful macOS 26+ Liquid Glass/elevation/gradients per [DESIGN](DESIGN.md), including all functional states and window resizing. The saved [glass controls](tasks/UI-011-control-unification.md) and [semantic feedback](tasks/UI-012-semantic-feedback.md) refine the earlier material review; use their shared roles in all further design. Native adoption remains open.
- [ ] Finish keyboard/VoiceOver, Light/Dark, Reduce Transparency/Motion, Increase Contrast and usability acceptance.
- [ ] Finish icon runtime checks. [BRAND-001](tasks/BRAND-001-icon-runtime.md).

### Phase 9 — Four-language UX

- [x] Current app slice has EN/RU/DE/FR String Catalog translations; 53-key onboarding/permission handoff is integrated; four-language native fixtures reviewed.
- [x] System/EN/RU/DE/FR manual preference, atomic failure/retry and launch/reopen activation path integrated; software/native fixture checks pass in [UI-005](tasks/UI-005-language-settings.md).
- [ ] Verify actual language relaunch/native contexts and complete remaining screen copy/layouts/errors/tooltips/accessibility in all languages.

### Phase 10 — Reliability and distribution

- [ ] Execute SPEC §15 acceptance with named OS/device evidence; measure input/action/UI performance, verify long-run safety and regression coverage.
- [ ] Complete macOS 26 and Intel execution where claimed, stable signing/TCC tests and distribution signing/notarization with real credentials. Universal compilation does not prove either runtime.

## Evidence and decision routing

- [CAPABILITIES](CAPABILITIES.md): detailed implemented/experimental/user-verified subsets and remaining checks.
- [research](research/README.md), [dependency register](research/DEPENDENCIES.md): current decisions and pinned sources/licenses.
- [tasks](tasks/README.md): owners, state, design/code revisions, handoffs and next action.
- [verification](verification/): behavior contracts, commands, manual walkthroughs and screenshots.
- [history](history/README.md): concise technical outcomes, research decisions and scoped earlier evidence. Historical scope/status claims can be superseded; raw local backups are not part of repository documentation.

Update a milestone only when its stated evidence exists. Keep this roadmap short; put execution detail in the relevant task, not a growing session log here.
