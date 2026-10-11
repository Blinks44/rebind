# UI-004 — Input settings and per-binding hold timing

- Updated: 2026-10-11.
- Stage: `ready_for_implementation`; bounded design delivered, native acceptance open.
- Owner: Unassigned; `/root` saved and released the design on 2026-10-11.
- Ownership checked: 2026-10-11, `main` / `acce2f4`; prior design owners released, concurrent trackpad engineering and UI-001 native implementation preserved.
- Owned surfaces: new Input frames, new local Input sources and new hold-editor variants in Rebind.sketch; this task/evidence/copy and affected shared index sections. Existing frames/styles/Brand and app source preserved.
- Requirements: SPEC §§3.1–3.4, 10–11; PLAN Phases 7–9.
- Code baseline: `main` / `acce2f4` plus pre-existing uncommitted engineering/design changes; no code ownership.

## Outcome and scope

Design Settings → Input as an honest overview of implemented timing: per-binding hold duration, system double-press interval and fixed pointer recognition. Add a focused hold-editor composition using the existing 100–5,000 ms range and 100 ms step. Experimental trackpad copy describes only the built-in unmodified four-finger tap → shortcut and retained native gestures. No global threshold override or unsupported recorder is introduced.

## Acceptance

- [x] Saved Input Light/Dark and compact EN/RU/DE/FR layouts.
- [x] Saved hold-editor layout, reusable sources, four-language copy and scoped behavior contracts.
- [x] MCP screenshot review, representative resize/restoration and saved-document preservation checks.
- [x] Task/evidence, DESIGN/STATE/index/history updated; native implementation acceptance kept separate.

## Saved design and verification

`Rebind.sketch`, saved 2026-10-11, document ID `E50CA3D9-82B1-44C0-AC97-39F1A9663700` (resolve again). SHA-256 `9d37daa77514e03e0160141ea7dec33c2e234d32973596bd01e96ba33758f774`.

[Delivery](../verification/input-settings.md) owns seven frames (33–39), four new sources, ten curated PNGs, behavior/native acceptance and 18-key four-language [copy](../verification/input-settings-copy.json). Input is screenshot-reviewed in EN/RU/DE/FR and Light/Dark; hold/editor failure layouts are reviewed in English, with translated rendered acceptance remaining native work. Three-frame resize restoration matches all 96 local screen-node frames; saved ZIP comparison preserves all 1,838 original local nodes and adds 209. Fifteen outbound routes valid. No app source change, new build/runtime/hardware check or Git commit.

Existing per-binding duration, macOS double-click interval and fixed recognition remain the behavior source. Global adjustable gesture thresholds are not introduced; remaining advanced tuning does not become complete through this bounded overview. Native accessibility, save transitions, editor locales/Dark and physical input acceptance remain open.

## Next handoff

- **Code — ready bounded handoff:** implement the prepared Input overview and per-binding hold timing design. Refresh live frames/copy and reuse existing models/Stepper/cancellation/atomic storage. Verify the delivery's native state, localization/accessibility and actual input checks on an identified artifact.
- **Design:** continue Settings → Language with System/EN/RU/DE/FR selection; Advanced follows separately. Preserve the delivered General/Permissions/Input sources and capability limits.
- User-facing handoff name: **Input settings and per-binding hold timing**. No task ID or previous chat is required to request implementation.
