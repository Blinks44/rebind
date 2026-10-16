# Rebind: current state

Updated **2026-10-16**. Baseline `fdaef8f` includes [DEVICE-003](tasks/DEVICE-003-multi-vendor-battery.md); [review fixes](tasks/REVIEW-001-production-review.md) are uncommitted. Runtime/accessibility/safety/Dock acceptance remains open.

## Product and baseline

Native macOS **26+**, SwiftUI/AppKit, local-only category-wide rules, one manually selected profile; physical attribution only for mouse settings. Scheme/module `rebind`, product `Rebind.app`, bundle `blinks44.rebind`. Xcode 27 / Swift 6.4 / SDK 27, Apple Silicon macOS 27.0.1; minimum-OS/Intel unverified.

Contracts/evidence: [WORKFLOW](WORKFLOW.md), [PLAN](PLAN.md), [SPEC](SPEC.md), [CAPABILITIES](CAPABILITIES.md).

## What already exists

Keyboard/mouse capture, manual profiles/atomic storage (schema **41**, migrations 1–40), the shared action catalog and twelve built-in/external trackpad presets are implemented. Held outputs, per-app rules/exclusions, per-mouse smooth scrolling and Devices settings are present. Whole-app soft styling and EN/RU/DE/FR/ES/Simplified Chinese are integrated. Named happy-path subsets are confirmed; full runtime, safety, timing, external-hardware, accessibility and minimum-OS gates remain open. [CAPABILITIES](CAPABILITIES.md) owns the detailed matrix; it is not repeated here.

The website is prepared for Cloudflare at `rebind.moduix.dev`, not published; download awaits `site.githubRepo` and advertised Magic-device support. Brand Dock/Menu Bar/tint acceptance must use the current artwork.

## Design source and recent changes

- **2026-10-16:** [Production review](tasks/REVIEW-001-production-review.md): third pass accepted the diff and last two commits; fixed double autorepeat for a shared held key; 828 + 17 tests pass. Earlier two passes: 827 Swift Testing + 17 native + 32 HIDPP pass; 41 TSan tests × 10. Builds/signatures pass. Sketch: 52 vertical Light/Dark pairs saved/rechecked. Exact battery row remains open.
- **2026-10-16:** [Context maintenance](tasks/DOC-003-context-maintenance.md): contracts/handoffs reconciled; workflow skill 1.4.0 adds incremental maintenance and simplicity priorities.
- **2026-10-16:** [Multi-vendor battery](tasks/DEVICE-003-multi-vendor-battery.md): generic inventory, native/HID data, opt-in Bluetooth BAS and known USB reads implemented/software-tested; named hardware/grant/reconnect checks pending.

Source: **Rebind.sketch** (English, Light/Dark) is the design source; [DESIGN](DESIGN.md) locates it. The earlier Liquid Glass document of the same name is fully superseded. Older entries: [history](history/2026-10.md).

## Open work / next steps

- **Next:** run `apps/rebind/tools/magic-mouse-probe.swift` with the Magic Mouse switched on (paired, was not connected on 2026-10-13); its contact counts decide which Magic Mouse presets are feasible and whether the sidebar section becomes real.
- **Open from review:** running-app checks of keyboard focus, VoiceOver and all six languages at minimum width; Dock/tint acceptance of the new icon.

| Task | Stage | Owner | Concrete next step |
| --- | --- | --- | --- |
| [REVIEW-001](tasks/REVIEW-001-production-review.md) | awaiting_verification | Unassigned | Verify holds/quit, gesture disconnect, glide and companion changes; implement/check the exact battery row. |
| [DEVICE-003](tasks/DEVICE-003-multi-vendor-battery.md) | awaiting_verification | Unassigned | Verify named USB models, Bluetooth access/BAS, reconnect and Logitech regression; Sketch reconciliation saved. |
| [DEVICE-002](tasks/DEVICE-002-device-names-discovery.md) | awaiting_verification | Unassigned | Check Rename/save/cancel/reset, battery menu and G915 after relaunch/reconnect, keyboard and VoiceOver. |
| [INPUT-011](tasks/INPUT-011-apps-mice-gesture-button.md) | awaiting_verification | Unassigned | User checks gesture button, per-app rules and per-mouse smooth scrolling; current designs reconciled. |
| [INPUT-010](tasks/INPUT-010-smooth-scrolling.md) | awaiting_verification | Unassigned | User checklist: glide feel per length, wheel bindings, Cmd/Ctrl/Shift and trackpad unchanged, per-app toggles, × on the warning, Light/Dark. |
| [DEVICE-001](tasks/DEVICE-001-mouse-devices.md) | awaiting_verification | Unassigned | User checklist: Devices on the MX Master 2S, persistence, banner, wheel reverse/speed ("Passed on, changed" in diagnostics), trackpad unaffected, Light/Dark. |
| [UI-023](tasks/UI-023-main-window-soft-adoption.md) | awaiting_verification | Unassigned; integrated | Running-app review of focus, VoiceOver, localized widths. |
| [INPUT-009](tasks/INPUT-009-held-output-exclusions-catalog.md) | awaiting_verification | Unassigned | Walk the physical checklist for held output, modifiers, wheel, excluded apps, trackpad keys and the new actions. |
| [UI-022](tasks/UI-022-soft-design-system.md) | in_design | Released | Current surfaces saved as 52 Light/Dark pairs; Magic Mouse editors await feasible presets. |
| [UI-014](tasks/UI-014-trackpad-presets.md) | awaiting_verification | Unassigned; tap editor released | Verify physical taps/coexistence, capture, keyboard/VoiceOver/preferences. |
| [INPUT-008](tasks/INPUT-008-magic-trackpad.md) | awaiting_verification | Unassigned | Connect a Magic Trackpad: discovery, gestures, reconnection; regression-check the built-in trackpad. |
| [INPUT-007](tasks/INPUT-007-trackpad-action-catalog.md) | awaiting_verification | Unassigned | Run non-shortcut actions from trackpad rules and the brightness actions on hardware. |
| [INPUT-006](tasks/INPUT-006-trackpad-clicks.md) | awaiting_verification | Unassigned; engine/editor released | Verify physical 2/3/4-finger clicks, resting-finger false positives and secondary-click settings. |
| [INPUT-005](tasks/INPUT-005-corner-taps.md) | awaiting_verification | Unassigned; engine/editor released | Verify physical corner taps with Tap to click off/on and accidental palm contact. |
| [INPUT-004](tasks/INPUT-004-two-finger-double-tap.md) | awaiting_verification | Unassigned; engine/data released | Preset exposed 2026-10-13; verify physical pairs/lone taps and Smart Zoom/secondary-click coexistence on a named build. |
| [INPUT-003](tasks/INPUT-003-double-tap-engine.md) | awaiting_verification | Unassigned; engine/data released | Verify physical single/double timing, click exclusion and native conflicts through UI-014. |
| [INPUT-002](tasks/INPUT-002-three-finger-tap.md) | awaiting_verification | Unassigned; engine/data released | Verify physical three/four taps and Look Up coexistence through UI-014. |
| [INPUT-001](tasks/INPUT-001-four-finger-tap.md) | awaiting_verification | Unassigned; focus walkthrough confirmed | Collect physical timing; preserve confirmed scenarios. |
| [UI-001](tasks/UI-001-permissions-onboarding.md) | awaiting_verification | Unassigned | Verify grants/revocation, keyboard/VoiceOver/preferences; build/layout pass. |
| [UI-003](tasks/UI-003-general-settings.md) | awaiting_verification | Unassigned | Review General on the named build; actual login/relaunch, VoiceOver/preferences remain open. |
| [UI-004](tasks/UI-004-input-settings.md) | awaiting_verification | Unassigned; materials/copy integrated | Verify physical Hold timing/cancellation, spoken VoiceOver/focus/preferences; scoped native checks pass. |
| [UI-005](tasks/UI-005-language-settings.md) | awaiting_verification | Unassigned | Apply/storage/compact/AX checked; verify actual production relaunch, Cocoa projection repair and accessibility. |
| [UI-007](tasks/UI-007-advanced-settings.md) | awaiting_verification | Unassigned | Requested Advanced checks user-confirmed; retain adaptive/platform/detailed §15.12 gates. |
| [UI-010](tasks/UI-010-about.md) | awaiting_verification | Unassigned | Verify VoiceOver/license reading, full keyboard traversal and accessibility preferences; native entry/search/closing checks pass. |
| [UI-009](tasks/UI-009-mouse-design.md) | awaiting_verification | Unassigned | List/editor soft styling integrated; verify capture, timing and native accessibility. |
| [BRAND-001](tasks/BRAND-001-icon-runtime.md) | awaiting_verification | Unassigned; scoped refresh saved | Check Dock/live Menu Bar from the explicitly identified fresh bundle; actual tint and macOS 26 remain separate. |

Release gates are listed in [PLAN](PLAN.md).
