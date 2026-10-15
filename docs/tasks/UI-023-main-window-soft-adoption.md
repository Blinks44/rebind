# UI-023: Main window in the soft design system

- Updated: 2026-10-16 (context reconciliation; no new native verification)
- Stage: awaiting_verification
- Owner: Unassigned; implementation integrated, documentation-maintenance claim released after cleanup
- Requirements: SPEC §§4, 10–11; current source in DESIGN
- Code baseline: original adoption started at `ca02747`; integrated code is present in `1a0801b`. Later device work is separate. Earlier checks below identify their original scope.

## Integrated scope

The soft design system is implemented across the main lists/sidebar, binding editors/action picker, Settings, hold-duration card, profiles/naming, first-run setup and About. The shared implementation lives in `apps/rebind/rebind/UI/DesignSystem`; Keyboard, Mouse and both trackpad categories reuse it. These surfaces no longer need initial restyling.

The 2026-10-13 user review accepted the direction. [DESIGN](../DESIGN.md) locates current English Light/Dark Sketch components and brand; inspect it live before a new visual change. Historical four-language/editor-only snapshots are superseded by the integrated six-language app, without implying six-language native acceptance.

Retained implementation decisions:

- Lists preserve add/edit/delete, enabled state, search, manual profiles, pause and permission recovery. Non-press activation stays visible in row captions.
- Status controls use actual runtime/grant/pause state. Trackpad coexistence guidance remains visible; neutral pause uses a neutral banner. Diagnostics stays in Advanced.
- macOS owns traffic-light placement through the unified toolbar. Earlier asynchronous/manual pinning attempts were removed because they fought native layout. Default window is 1080 × 720; minimum is 880 × 600.
- The sidebar uses the running app's icon and a 44 pt brand mark/22 pt title. App icon and Menu Bar delivery are separate in [BRAND-001](BRAND-001-icon-runtime.md).
- Shared native buttons/menu controls retain semantics while adopting tokens. The action picker has search, categories and Return selection; profile/name sheets reuse themed controls.
- Focus borders are shown for keyboard-driven focus. The final measured 1x outline fix snaps the 1.5 pt accent stroke to device pixels (2 px at 1x, 3 px at 2x); circular capsules and earlier border/toolbar changes alone did not resolve it. Do not restore discarded clipping/traffic-light workarounds.

## Acceptance and retained verification

- [x] Main window and shared surfaces implemented; existing behavior retained.
- [x] Direction accepted in the running app by the user on 2026-10-13.
- [x] Original build/layout/behavior checks passed on their dated artifacts.
- [ ] Running-app keyboard focus, hover/pressed states, native menus and VoiceOver.
- [ ] Increase Contrast, Reduce Motion/Transparency and six-language expansion at minimum width.
- [ ] Current icon Dock/Menu Bar/tint acceptance in BRAND-001; review shadow direction/keycap ledge/glow in the actual app.

Agent-observed 2026-10-13, macOS 27.0.1 / Xcode 27: `apps/rebind/scripts/dev.sh build` passed; original Sketch-size Light/Dark render and compact localized editor checks passed. After Settings/profile/setup/About integration, an uninterrupted full run passed 15 XCTest layout tests and 663 Swift Testing tests. Earlier host exits coincided with the test host being closed; they are not additional passes. Offscreen `cacheDisplay` shadow direction was unreliable and excluded from visual acceptance.

Final outline repair that day: build and full suite passed (699 Swift Testing tests; XCTest host succeeded); an on-screen 1x fixture showed even 2 px edges. The user confirmed the outline was even in their running app. A 2x capture, active/inactive edge swap and complete focus/accessibility acceptance were not established. PLAN retains broader focus review; this result is narrower than closing every focus defect.

These are historical results, not tests rerun by the 2026-10-16 cleanup. Original iterative detail is in Git at `1a0801b`; meaningful decisions and remaining gates are retained here.

## Next handoff

- **Verification:** review current focus, VoiceOver, adaptive preferences, localized widths and visual effects on an explicitly identified current bundle; record exact states/OS/languages and remaining limits.
- **Design/code:** handle new Devices/Input/per-app/editor states in their current feature tasks from fresh Sketch; initial whole-app soft-system adoption is already integrated.
