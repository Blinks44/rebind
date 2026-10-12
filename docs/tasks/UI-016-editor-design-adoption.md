# UI-016 — Shared binding-editor design adoption

- Updated: 2026-10-12.
- Stage: `awaiting_verification`; shared editor fidelity correction integrated; broader native acceptance open.
- Owner: Unassigned; `/root` released the corrected implementation on 2026-10-12.
- Ownership checked: `main` / `59f5754`, 2026-10-12; design UI-015 saved/released. Existing documentation changes are preserved.
- Owned surfaces: shared editor selector/capture/feedback views and scoped assets, Mouse/Trackpad editor composition, native editor verification and this task/affected status sections. No Sketch or input-engine edits.
- Requirements: SPEC §§4, 10–11; PLAN Phase 8; released UI-011/UI-012/UI-015.

## Outcome and scope

Adopt the final shared glass selectors, capture/control alignment, shortcut keycaps, section rhythm and semantic failure/conflict surfaces in existing Mouse and Trackpad editors. Reuse native Menu/Picker/Button semantics and preserve draft, recording, validation, persistence and current engine-backed preset/action limits. The shared action selector and feedback also serve the existing Keyboard editor; its complete layout and the wider Settings/main-screen adoption remain separate.

## Acceptance

- [x] Inspect current saved Sketch sources/annotations/screenshots directly through MCP.
- [x] Native selectors, aligned recording/clear controls, raised capture surfaces, one shortcut summary and pinned Cancel/Save implemented; live direct-menu checks pass.
- [x] Error/warning icon, title and opaque feedback; Light/Dark assets and opaque/contrast fallbacks implemented with four-language copy reconciled to the live source.
- [x] Debug build, existing recording/editor regressions, native compact/localized editor checks and scoped visual review.
- [x] Record runtime/accessibility limits and release ownership with one next step.
- [ ] Active-window record/cancel/focus, full keyboard/VoiceOver, adaptive preferences and macOS 26 acceptance.

## Source

Live Rebind.sketch, document `3D0EE4BC-3EE5-45C9-97A0-E4DCAF4414AE`, Sketch 2026.3.1/API 2.0.0. All five pages surveyed; all five Components boards read and screenshot-reviewed, with affected Foundations 4/12/13/14/15/22, editor compositions and shared Light/Dark symbols inspected directly. This is not a fresh visual review of all 125 screens. Saved revision is indexed in DESIGN/UI-015; no design edits.

## Implementation and verification

Shared selector/material, stable equal activation segments, capture/keycaps and semantic feedback are integrated. The fidelity follow-up adds scoped typography/metrics, exact source text/accent assets, authored secondary wash/inner lighting, 58 pt capture rhythm and UI-only Light/Dark/disabled previews. Editor labels follow Sketch in EN/RU/DE/FR; short recorder text retains complete accessible names, and the binding-specific Save label leaves profile naming unchanged.

The user accepts native color variation in inactive windows. No forced active-appearance environment remains; system focus rings and normal native material adaptation are preserved. The secondary wash is explicitly not a replica of Sketch's custom glass shader. [Seven-library and additional-skill audit](../research/liquid-glass-library-audit.md) records the native/component decision; no package, shader or skill installed. No input-engine, draft/persistence/schema, production configuration or Sketch change. Shared selector/track impact includes UI-017.

[Final evidence](../verification/editor-design-adoption.md#shared-components-and-sketch-fidelity--2026-10-12): 34 functions / 94 expanded executions, 848 native viewports, ordinary Debug build and strict/deep signature pass. Agent-observed final Light/Dark wheel controls and authored labels reviewed; live recording/full keyboard/VoiceOver/preferences/macOS 26 remain open. Earlier popup/activation verification is retained in the evidence, not relabeled as a fresh pass. No agent commit.

## Next step

Open the named ordinary build and review Mouse Button/Wheel/Pointer and Trackpad editors in the chosen app language. Verify pointer menu dismissal, keyboard focus/restoration, active recording/cancellation and VoiceOver/adaptive preferences; native inactive color variation is expected. Continue remaining Settings/main/profile adoption from live Sketch using these shared components. Magic Mouse remains deferred until hardware is available.
