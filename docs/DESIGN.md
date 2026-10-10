# Rebind — design direction and live source index

Updated 2026-10-10. Owns the design direction and pointers to current artifacts; [SPEC §10](SPEC.md#10-interface-and-design-core) owns required screens/behavior. Read [WORKFLOW](WORKFLOW.md) for handoff. Latest scoped review repaired onboarding layout in Sketch; native implementation remains pending.

## Direction: modern macOS 26+

Rebind is designed for **macOS 26 and later**, using the material language of recent macOS releases. The user's explicit direction is a distinctive, contemporary native utility, rather than a legacy flat Settings presentation of plain gray backgrounds and generic blue buttons.

Use **Liquid Glass, raised/elevated surfaces, subtle lighting, depth and intentional gradients** where they clarify hierarchy, interaction or brand. These are positive design tools, not effects to prohibit by default. Apply them selectively: navigation/sidebar, meaningful toolbar or profile controls, relevant overlays and branded artwork can benefit; every row, field and background does not need glass. Dense rule content stays calm, readable and stable.

Native control semantics and modern visual treatment coexist. Preserve native NavigationSplitView/List/Table/Form where appropriate, SF Symbols, semantic SF Pro typography, system focus/menu/button behavior and desktop density. A Form is a structure, not a requirement to reproduce an old Settings appearance. Do not flatten an agreed raised/glass design solely because default styling is easier.

Avoid indiscriminate blur, glass-on-glass stacks, giant decorative cards, arbitrary radii, unrelated gradients or ornamental animation. Effects need a purpose and must not obscure status, text or controls. Prefer native macOS material APIs; interpret Sketch's optical styles as design intent, not a demand to recreate every shadow with a custom renderer. Check APIs against the **macOS 26 floor** and installed SDK; an iOS availability guard is insufficient.

### Accessibility and adaptive behavior

- Light/Dark preserve hierarchy and contrast; do not simply invert colors.
- Reduce Transparency uses opaque semantic surfaces while retaining shape, hierarchy and distinctive layout.
- Increase Contrast keeps readable text, visible edges and status beyond color alone.
- Reduce Motion removes decorative morphs/zooms/sweeps; preserve meaningful state feedback.
- Keyboard/focus/VoiceOver, resizable windows and EN/RU/DE/FR expansion remain acceptance requirements. Native label semantics should not produce duplicate announcements.
- Current style/token values are in live Sketch. Do not force upstream iOS/widget pixel grids, monospaced fonts, fixed mobile rows or navigation scaffolds onto Rebind.

## Resolve the current document

Current editable source: **Rebind.sketch**. Resolve it by name/current open document through Sketch MCP. Optional workstation access hints can live in ignored `.local/agent-context/`; they are not a dependency for another contributor. Latest layout repair saved document ID **`A2DE362A-E026-47F5-8F3E-FBC3AF4353DD`** on 2026-10-10; revision digest is in [UI-001](tasks/UI-001-permissions-onboarding.md). Earlier document IDs are stale; never hardcode them as permanent identity.

Load Sketch `get_guide` topics `mcp`, then `use`. Resolve the user's document using open-document path/name, refresh the document ID, then inspect document info, relevant layer trees/styles and screenshots. For authorized edits, follow guides and visually verify the changed frames; reading this file does not authorize editing Sketch. If the document is inaccessible or ambiguous, explain and request the missing target/connection; continue independent work without inventing a visual source.

Optional `docs/references/` assets and review PNGs are supplementary/historical; superseded icon PNG sets were removed. Screenshots do not replace current live frames. Sketch lives outside this repository: record its saved state/version separately from Git. Future handoffs must name date/revision or available digest and stable frame/source IDs, not only “latest design”.

## Live structure and reuse

| Page | ID | Role |
| --- | --- | --- |
| 01 · Screens | `8C2F841A-D889-42D3-B7A7-5137DB78C7D3` | Main/editor/profiles/About and permission flows |
| 02 · Foundations | `FDC80B2B-C028-4DB7-A43B-794D4BF78A5A` | Typography, semantic Light/Dark colors, spacing/material/accessibility contract, symbols |
| 03 · Components | `B7EE0411-C9DF-4DFC-9F7F-57E802FEF79D` | Apple macOS 26 controls and Rebind state patterns |
| 04 · Symbols | `2C466EB2-3B92-4E99-9ABC-909A50A3F9E7` | Reusable Light/Dark components and brand sources |
| 05 · Brand | `6A22BD00-EAE5-4069-9128-D2BDAEA784B1` | App-icon/Menu Bar review boards |

Materials/accessibility board: **`527B677E-7D69-4228-8D41-7AB5CA863372`**, “04 · Layout / Materials / Accessibility”. Inspected live hierarchy/screenshot on 2026-10-10. It establishes raised tinted regular glass sidebar, small regular glass profile control, opaque accessibility variant and glass reserved for navigation/controls.

Observed reusable styles include `Rebind/Light/sidebarGlass`, `Rebind/Dark/sidebarGlass`, `Liquid Glass/Light/Regular - Small`, `Liquid Glass/Dark/Regular - Small`, `Rebind/Light/formGlass`, Light/Dark `menuGlass`, and shared Brand Frosted base/Blue light/White face/Frosted rim. Resolve current shared styles/Color Variables and libraries before adding equivalents; do not duplicate or detach existing sources.

## Screen index and implementation status

The entries below are saved design artifacts inspected through MCP, not evidence of native completion or user approval of every example. A functional baseline UI already exists in code; the full visual design is not yet implemented.

| Surface / frame | Stable ID | Delivery status / code |
| --- | --- | --- |
| 01 · Keyboard · Work / Light | `4C347E0A-C4C1-4479-B9CE-4363581BD48F` | Live screenshot inspected; main visual implementation pending, baseline `ContentView.swift` exists |
| 02 · Keyboard · Work / Dark | `7AF536A2-CC26-46FD-B353-C57B730EEF28` | Saved Dark reference; implementation pending |
| 03 · Keyboard · Work / Compact 880 × 600 | `877C8EE5-487B-4313-926A-DB77B2CFB4B2` | Saved resize reference; baseline code minimum is currently 850 × 560, discrepancy to reconcile in UI work |
| 04 · Add Binding / Keyboard · Empty | `D4E121AF-CC02-4AD9-8B14-E76624067E9E` | Saved editor reference; existing functional `UI/BindingEditor.swift` differs visually |
| 05 · Edit Binding / Keyboard · Populated | `16F3C025-CF09-4AA1-8490-4E159EDEFBA6` | Saved populated editor reference |
| 06 · Manage Profiles / Work selected | `5E8DB648-096F-4B6D-9B8E-2663D2B15394` | Saved reference; functional `UI/ProfileManagerView.swift` exists |
| 07 · About / Rebind | `FCD17D45-D89C-44AF-842A-2095BFB50986` | Saved reference; native About surface not implemented |
| 08 · First Launch / Accessibility required · Light | `EDA6F1D6-D17F-4ABB-8A72-1DECF5EDE4F4` | Saved/reviewed; native onboarding pending |
| 09 · First Launch / Accessibility required · Dark | `F0F88FE5-F6A1-4402-965E-96B83A27B732` | Saved/reviewed; native onboarding pending |
| 10 · First Launch / Event sending required · Light | `18E3BEB1-9333-4C8E-97F1-F8233CAB8A95` | Saved/reviewed; actual AX/posting distinction must be retained |
| 11 · First Launch / Ready · Light | `B01D939A-7E79-4E5A-9385-3F494EF9CF80` | Saved/reviewed; real grants required, no fake success |
| 12 · Permissions / Access revoked · Light | `A2F08C1D-327C-4108-8C14-6AD6E320918F` | Saved/reviewed; preserve rules and intentional pause |
| 13 · First Launch / German text expansion | `E207327E-5664-496C-999A-2B7A69B61335` | Saved/reviewed; RU/FR/native runtime layouts remain open |

The Work mockup contains Caps Lock, Magic Mouse and action examples that are not all implemented. Use it for hierarchy/material direction; use source/CAPABILITIES for selectable inputs/actions. Do not turn placeholder rows into capability claims. Keep a compact profile picker/management above category rules; Settings/About separated below navigation, no extra Profiles/Workflows/Actions sidebars.

Permissions design/copy contract: [UI-001](tasks/UI-001-permissions-onboarding.md), [review record](verification/menu-bar-onboarding.md), [28-key EN/RU/DE/FR handoff](verification/permissions-onboarding-copy.json). The JSON handoff is **not** integrated into `Localizable.xcstrings`. Missing-permission main-window and Settings → Permissions composition are the next design slice, not invented current frames.

Frames 08–13 and their Light/Dark introduction/other-permissions sources were repaired after a canvas clipping report. All six states are now checked at preferred 560 × 580, compact 520 × 560 and expanded 720 × 680, with successful resize roundtrips. Text origins remain inside clipping containers, the 48 pt icon remains square, controls retain intrinsic dimensions and the footer follows the bottom edge. [Repair evidence and sizing handoff](verification/menu-bar-onboarding.md#onboarding-layout-repair--2026-10-10) supersede the initial visual review; native/accessibility/RU/FR checks remain open.

## Brand: existing source and delivered assets

| Artifact | Source / delivery | Status |
| --- | --- | --- |
| App-icon Frosted geometry | Symbol `AA064C59-AD8E-40E1-A7DF-DF7F6949C136` on 04 · Symbols | Refined editable vector source |
| Small optical geometry | Symbol `5E88F8C5-D3D4-40EB-AD5B-D459FFECFD54` | Wider counters/optical treatment; static reference |
| App-icon review board | `0C9B719F-193A-4298-85E1-05576002F92E` on 05 · Brand | Current review placement |
| Dock/Finder delivery | [rebind/AppIcon.icon](../rebind/AppIcon.icon/) | Integrated native Composer package, Debug/Release/Finder evidence |
| Menu Bar source | Symbol `0F0BD265-F8D6-4405-8425-247D8DA43C06`; board `EBAC2CD7-4F7F-4756-8BC4-AC1D43192933` | Separate monochrome optical vector |
| Menu Bar delivery | [RebindMenuBar.imageset](../rebind/Assets.xcassets/RebindMenuBar.imageset/) | Integrated named template, 18 pt/native resource checks |

Sketch owns editable geometry/visual source. Icon Composer owns delivery materials, system masking and native appearances; export clean foreground/background layers rather than decorating them twice. Menu Bar uses a transparent monochrome template with system coloring, independent of the raised/gradient Dock artwork.

Detailed sources/material settings/revision workflow: [brand README](../assets/brand/README.md). Verification: [Composer](verification/app-icon-composer.md), [Menu Bar](verification/menu-bar-onboarding.md), [BRAND-001 remaining runtime checks](tasks/BRAND-001-icon-runtime.md). Superseded PNG catalog/reference exports were removed; the native `.icon` package is the sole app-icon input. The icon is already delivered; remaining Dock/tint/minimum-OS acceptance does not mean it needs creating again.

## Updating this design contract

After authorized design work, save and visually verify affected frames, then update this index and the task handoff with source IDs, version/date, reusable components, states/copy, changed scope, acceptance evidence and next action. Change SPEC only if behavior requirements changed. Track implementation/verification separately; an agent must not label design-ready as implemented.

This direction records the user's instruction of 2026-10-10. Future visual work should develop it within live Sketch's current design system. It authorizes the direction, not an unsolicited rewrite of every screen or an automatic Sketch edit.
