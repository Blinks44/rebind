# Rebind: design direction and live source index

Updated 2026-10-13. [SPEC](SPEC.md) owns required behavior. **Sketch owns the visual design, components, states, product copy and interaction annotations.** This file is a short locator and readiness index; implementation agents inspect the live source directly through MCP.

Design the final planned release, including Trackpad and Magic Mouse. User clarification on 2026-10-11: temporary implementation gaps (such as four-finger-only or not-yet-implemented placeholders) are not target product states. Remove or replace those specimens under UI-013. Keep genuine device compatibility, permissions, conflicts and recovery states. Target design does not claim current implementation or hardware verification; those facts remain in CAPABILITIES and verification.

## Direction: soft, opaque-first macOS 26+ (2026-10-12)

User decision 2026-10-12: the calm look of the current **Rebind.sketch** replaces the Liquid Glass direction. Surfaces are opaque-first with soft shadows and 1 pt hairlines; controls are 36 pt capsules (28 pt small); lists sit on one raised card with 72 pt rows; raised SF Pro Rounded keycaps are the brand motif; one blue accent, and other color only for state. Only the sidebar and menus may use a system material. Light and Dark share geometry, type and spacing. Preserve native SwiftUI/AppKit semantics, SF Pro/SF Symbols, system menus/focus and desktop density.

## Current source: Rebind.sketch

Open **Rebind.sketch** (renamed from "Rebind - new.sketch" on 2026-10-14) through Sketch MCP (load `mcp`, then `use`; resolve the open document by name). Last save/review **2026-10-14**, SHA-256 `2f2604b77e980d55139c864b582997adcd57114cb0f180802037cc67ec2f90c6`; IDs change after reopening, so resolve them live. [UI-022](tasks/UI-022-soft-design-system.md) records scope and limits.

| Page | Content |
| --- | --- |
| 01 · Screens | 45 screens, each Light and Dark, built only from components |
| 02 · Foundations | Color variables, typography, shape/spacing/elevation, component overviews, principles and native mapping |
| 03 · Components | Symbol sources named `Theme/Group/Variant`, plus theme-neutral `Icon/<SF Symbol name>` |
| 04 · Brand | App icon artwork as scale-safe paths (also used as the in-app logo), Menu Bar template |
| 99 · Archive | The two original hand-drawn Keyboard frames |

Screens are drawn **in English only** (user decision 2026-10-13): other languages are translated and checked in the app, not duplicated in Sketch. Icons are real SF Symbols outlines exported with `apps/rebind/tools/sf-symbol-svg.swift`; each `Icon/<name>` component is named after the symbol used in code, so add a symbol by exporting it rather than drawing it.

The code mirrors the variables in `apps/rebind/rebind/UI/DesignSystem/Theme.swift`; on 2026-10-13 all 43 colors used by the app matched Sketch exactly. Change a token in both places.

Every color is a `Light/…` or `Dark/…` Color Variable; layer and text styles reference those variables. Sketch has no variable modes, so each component exists once per theme. Reuse these sources; do not draw raw layers or hex colors on screens.

Covered screens (45): Keyboard, Mouse, Trackpad and Magic Trackpad lists with empty, no-results, permission-needed and paused states; the Magic Mouse empty state; Keyboard, Mouse and Trackpad editors (recording, conflict, action picker and parameters, hold, wheel, held key, note); all Settings tabs including Devices (39–41: mice, Options+ warning, empty) and the Mouse page with a companion-app warning (42) and the gesture-button trigger (43, implemented 2026-10-15; the frame can drop its "Future" mark); Input with smooth scrolling (44) and excluded apps with Bindings / Smooth scrolling switches (45); profile management, naming, export and import; first-run setup; diagnostics; licenses; About. Not drawn: Magic Mouse editors (the presets are undecided, see [PLAN](PLAN.md)) and compact-width variants, which are checked in the app.

## Rules that apply to every screen

- Trackpad and Magic Mouse use one selector of complete, curated gesture presets followed by the shared action editor: no touch trigger recording and no separate type/finger/direction controls. Keyboard and conventional Mouse keep their trigger recorders; output-shortcut recording is available to every category. SPEC carries the behavioral rule.
- Every rule trigger is a raised keycap. Keyboard keys show only their label; any other trigger (mouse button, gesture, wheel, touch) adds a leading SF Symbol naming the input type.
- Feedback colors: failures red, prerequisites and conflicts amber, completed operations green, information and progress blue. Deliberate pause, empty and disabled states stay neutral.
- Increase Contrast strengthens text and edges; Reduce Motion removes decorative transitions. Keyboard focus, VoiceOver, resizing and localized expansion are accepted in the app, not in Sketch.
- Sketch is saved separately from Git. If it is unavailable, ask for the document and continue independent engineering; do not substitute an old PNG. Verification screenshots stay local under [WORKFLOW](WORKFLOW.md#repository-content-and-language).

The earlier 125-frame Liquid Glass document, which used the same file name, is fully superseded and no longer a reference; task and verification records dated before 2026-10-12 that cite "Rebind.sketch" mean that old document; its history is in the [design tasks](tasks/README.md) and [history](history/2026-10.md).

## Brand

The app icon is itself a full-bleed blue keycap with two opposing white arrows, following the macOS 26 icon grid (no inner margin). Editable geometry lives on page `04 · Brand`. [AppIcon.icon](../apps/rebind/rebind/AppIcon.icon/) is the sole app-icon input (deep-blue fill plus `Key` and `Glyph` SVG layers composed by Icon Composer); [RebindMenuBar.imageset](../apps/rebind/rebind/Assets.xcassets/RebindMenuBar.imageset/) is the monochrome template; the sidebar shows the running app's own icon. For revisions, edit the geometry in Sketch, update the two SVG layers, rebuild and inspect `Rebind.app/Contents/Resources/AppIcon.icns`; do not bake a corner mask, shadow or background into the layers, the system adds them. `docs/images/app-icon.png` is the README preview exported from a build. Earlier Dock/tint checks in [BRAND-001](tasks/BRAND-001-icon-runtime.md) apply to the previous artwork and must be repeated.

## Updating this design contract

Save and review changes in Sketch; keep states, copy and annotations there. Update only this short locator/readiness index and a concise task/status note. The receiving agent reads Sketch directly. Record changed behavioral requirements in SPEC and native test results in verification; do not duplicate the visual source in Git.

Device-name/keyboard follow-up (2026-10-15): [DEVICE-002](tasks/DEVICE-002-device-names-discovery.md) reuses the live Devices card and profile naming-sheet components in code. Rename and keyboard-only states are not yet drawn/reconciled in Sketch; no document edit was made.

Multi-vendor battery follow-up (2026-10-16): [DEVICE-003](tasks/DEVICE-003-multi-vendor-battery.md) reuses the Devices header, caption and secondary button for optional Bluetooth access (allow / open privacy settings / restricted). The live Devices frames were re-inspected; this permission state and generic keyboard/trackpad inventory need Sketch reconciliation. No Sketch content was changed.
