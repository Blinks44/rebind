# UI-022: Soft design system and screen coverage

- Updated: 2026-10-16 (documentation reconciliation; no new Sketch review)
- Stage: in_design
- Owner: Unassigned; saved design released for implementation
- Requirements: SPEC §§3.4–3.5, 4, 8, 10–11
- Source/baseline: current source/save/digest is in DESIGN; original direction change started at `ca02747`. Integrated native adoption is tracked in UI-023, not pending initial implementation.

## Current outcome and acceptance

The soft, opaque-first direction is established and was accepted after the user ran the new main window on 2026-10-13. Reusable Light/Dark variables, styles, components, SF Symbols, keycap triggers and brand artwork are saved in Rebind.sketch. [DESIGN](../DESIGN.md) is the current locator/readiness index; its current coverage includes core lists/editors, Settings, onboarding, profiles, About and newer input/device states.

- [x] Reusable foundations/components and core screens saved and reviewed in both themes.
- [x] Direction accepted; English-only Sketch and six-language app contract recorded.
- [x] Real SF Symbols outlines and one raised-keycap trigger style adopted in Sketch/app; whole-app native adoption implemented in [UI-023](UI-023-main-window-soft-adoption.md).
- [ ] Magic Mouse editors after hardware research determines the presets.
- [ ] Reconcile newer local device names/keyboard/multi-vendor/Bluetooth states and per-app/editor changes from DEVICE-002/003 and INPUT-011 against live Sketch.
- [ ] Native focus, VoiceOver, localized widths and adaptive preferences; these are app checks rather than Sketch proof.

## Retained decisions and dated evidence

Controls/content are opaque; only sidebar/menus may use system material. Sketch uses separate Light/Dark variables and components because it has no variable modes. The original hand-drawn frames remain in its archive. Shared colors/geometry must be reconciled with code tokens when changed; no mirrored component inventory is maintained here.

2026-10-12: original 12-screen-per-theme core set and foundations were inspected through live MCP, save/review completed; no native/hardware claim. 2026-10-13: real SF Symbols replaced stand-ins; remaining Settings/profile/setup/About screens and brand were added. Screens are English only; other languages are checked in the app.

2026-10-14 artifact audit: 38 screens × Light/Dark reviewed for clipping, theme drift and geometry. Fixed wrapping, hints, action icons, Magic Mouse selection, About alignment and submenu chevrons. Later one-trigger-style change made non-keyboard triggers raised keycaps with a leading input-type symbol; code/website followed it, and the user confirmed the app result. These observations retain their original scope; later additions are not silently included in that audit.

## Next handoff

Design: inspect current live Sketch and the newer feature tasks, then draw/reconcile the missing Devices/Input/editor states using existing components. Magic Mouse presets still depend on its hardware probe. Implementation agents consume ready bounded states directly; initial main-window/system adoption and user direction approval are already complete.
