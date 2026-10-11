# Rebind — design direction and live source index

Updated 2026-10-11. Owns the design direction and pointers to current artifacts; [SPEC §10](SPEC.md#10-interface-and-design-core) owns required screens/behavior. Read [WORKFLOW](WORKFLOW.md) for handoff. The 39-screen source includes first-run/permissions (now integrated, native acceptance open) and General/background/Input handoffs ready for implementation.

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

Current editable source: **Rebind.sketch**. Resolve it by name/current open document through Sketch MCP. Optional workstation access hints can live in ignored `.local/agent-context/`; they are not a dependency for another contributor. Input delivery saved document ID **`E50CA3D9-82B1-44C0-AC97-39F1A9663700`** on 2026-10-11; current digest is in [Input verification](verification/input-settings.md). All 1,838 preceding local nodes compare unchanged. Earlier document IDs are stale; never hardcode them as permanent identity.

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
| 03 · Keyboard · Work / Compact 880 × 600 | `877C8EE5-487B-4313-926A-DB77B2CFB4B2` | Saved resize reference; native minimum now 880 × 600; full main visual implementation/acceptance remains open |
| 04 · Add Binding / Keyboard · Empty | `D4E121AF-CC02-4AD9-8B14-E76624067E9E` | Saved editor reference; existing functional `UI/BindingEditor.swift` differs visually |
| 05 · Edit Binding / Keyboard · Populated | `16F3C025-CF09-4AA1-8490-4E159EDEFBA6` | Saved populated editor reference |
| 06 · Manage Profiles / Work selected | `5E8DB648-096F-4B6D-9B8E-2663D2B15394` | Saved reference; functional `UI/ProfileManagerView.swift` exists |
| 07 · About / Rebind | `FCD17D45-D89C-44AF-842A-2095BFB50986` | Saved reference; native About surface not implemented |
| 08 · First Launch / Accessibility required · Light | `EDA6F1D6-D17F-4ABB-8A72-1DECF5EDE4F4` | Native setup/recovery integrated; fixtures reviewed, actual grants/window/accessibility acceptance open |
| 09 · First Launch / Accessibility required · Dark | `F0F88FE5-F6A1-4402-965E-96B83A27B732` | Native setup/recovery integrated; fixtures reviewed, actual grants/window/accessibility acceptance open |
| 10 · First Launch / Event sending required · Light | `18E3BEB1-9333-4C8E-97F1-F8233CAB8A95` | Native setup/recovery integrated; fixtures reviewed, actual grants/window/accessibility acceptance open |
| 11 · First Launch / Ready · Light | `B01D939A-7E79-4E5A-9385-3F494EF9CF80` | Native setup/recovery integrated; fixtures reviewed, actual grants/window/accessibility acceptance open |
| 12 · Permissions / Access revoked · Light | `A2F08C1D-327C-4108-8C14-6AD6E320918F` | Native setup/recovery integrated; fixtures reviewed, actual grants/window/accessibility acceptance open |
| 13 · First Launch / German text expansion | `E207327E-5664-496C-999A-2B7A69B61335` | Native setup/recovery integrated; fixtures reviewed, actual grants/window/accessibility acceptance open |
| 14 · Keyboard / Accessibility missing · Light | `C7666697-D667-433D-87E7-2ED3AEE66AB0` | Native recovery banner integrated; full main visual/runtime acceptance open |
| 15 · Keyboard / Accessibility missing · Dark | `ED7548FC-E890-4446-9B9A-49EAD9FF3013` | Native recovery banner integrated; full main visual/runtime acceptance open |
| 16 · Keyboard / Event sending missing · Light | `4BE17A75-C9D5-4DA0-BADD-252CA3D63ABF` | Native recovery banner integrated; full main visual/runtime acceptance open |
| 17 · Settings / Permissions missing · Light | `9E3ECBEB-6D9B-4A8A-AA74-7F088874B71C` | Native permission content integrated; four-language fixtures reviewed, actual window/grant/accessibility checks open |
| 18 · Settings / Event sending missing · Light | `FDAE5B1D-7817-4E57-B2DE-4F6A4A78F544` | Native permission content integrated; four-language fixtures reviewed, actual window/grant/accessibility checks open |
| 19 · Settings / Required access enabled · Light | `1019A6B3-431F-43F7-A828-8A137FAD66B2` | Native permission content integrated; four-language fixtures reviewed, actual window/grant/accessibility checks open |
| 20 · Settings / Permissions missing · Dark | `74084012-59AC-4A15-A060-CF5800B0EDD0` | Native permission content integrated; four-language fixtures reviewed, actual window/grant/accessibility checks open |
| 21 · Keyboard / Permission recovery · Compact | `33F9EC25-8B4E-4620-99C7-C2FD1F22BD73` | Native recovery banner integrated; full main visual/runtime acceptance open |
| 22 · Settings / Permissions · German | `46BD4DAA-B7FB-41B6-B6FC-BFD2A1E18AC2` | Native permission content integrated; four-language fixtures reviewed, actual window/grant/accessibility checks open |
| 23 · Settings / General · Enabled · Light | `2C9A6A68-F839-46C2-BF15-E672107FB024` | Delivered in UI-003; login off, native implementation pending |
| 24 · Settings / General · Paused · Dark | `410A654D-4DF2-4810-9EA2-79242185FEC3` | Delivered; login on, native implementation pending |
| 25 · Settings / General · Login approval required | `067A6C10-7A7D-406A-B26F-FABEDC1DA9DD` | Delivered; explicit system-review/check/cancel actions |
| 26 · Settings / General · Login enable failed | `4788D158-8D0B-4FF1-9606-CAA460194EFF` | Delivered; actual Off state and bounded retry |
| 27 · Settings / General · Required access missing | `10363873-FAC1-4DCA-9180-0315D7C493F9` | Delivered; global enabled intent retained |
| 28 · Settings / General · German · Compact | `53A0F080-03E7-4FE8-A05E-8EB1AF8DF7AF` | Delivered and checked at 880 × 600 |
| 29 · Settings / General · Russian · Compact | `94510528-E1B3-403B-97AA-943B664B5D8D` | Delivered; 880 × 600 and 850 × 560 checks |
| 30 · Settings / General · French · Compact | `72D357F2-458E-432D-B344-DE9310F27F6C` | Delivered and checked at 880 × 600 |
| 31 · Settings / General · Login removal failed | `C9407364-ECD6-4C46-B051-EECF9BB7A031` | Delivered; actual On state and bounded retry |
| 32 · Settings / General · Remapping could not start | `2BDAD1BE-0E66-42EB-82EC-EDFED6974A84` | Delivered; engine error distinct from missing grants |
| 33 · Settings / Input · Light | `F121172C-AC90-4D1F-9A0E-5E467E3E07F4` | Delivered in UI-004; existing timing/threshold overview |
| 34 · Settings / Input · Dark | `95BC21C9-2B67-4B55-B09C-11C2BEFAFABC` | Delivered; native implementation pending |
| 35 · Settings / Input · Russian | `F9CF0786-1007-474E-9B03-1F4A2AC7BA4E` | Delivered; 880 × 600 and 850 × 560 checked |
| 36 · Settings / Input · German | `E71C9EC6-2F72-4DA9-A8A6-AAADA548EC40` | Delivered; 880 × 600 checked |
| 37 · Settings / Input · French | `CA520624-1683-434F-B654-86F07878F896` | Delivered; 880 × 600 checked |
| 38 · Edit Binding / Hold | `57339F81-811A-43DB-B920-02525FC5B3BD` | Delivered; bounded native Stepper, English layout |
| 39 · Edit Binding / Hold / Save failed | `EDAE6F9E-A2E5-4942-BAE0-500059DF5145` | Delivered; retained draft and retry, native acceptance open |

The Work mockup contains Caps Lock, Magic Mouse and action examples that are not all implemented. Use it for hierarchy/material direction; use source/CAPABILITIES for selectable inputs/actions. Do not turn placeholder rows into capability claims. Keep a compact profile picker/management above category rules; Settings/About separated below navigation, no extra Profiles/Workflows/Actions sidebars.

Permissions design/copy contract: [UI-001](tasks/UI-001-permissions-onboarding.md), [review record](verification/menu-bar-onboarding.md), [53-key EN/RU/DE/FR handoff](verification/permissions-onboarding-copy.json). All 53 keys are now integrated into `Localizable.xcstrings`. [Native implementation/evidence](verification/permissions-native.md) records software/fixture checks, bounded differences and remaining real-grant/full-window/accessibility acceptance. Frames 14–22 now deliver those compositions. [Recovery handoff](verification/permission-recovery.md) records six reusable Light/Dark sources, navigation, actual-grant/pause semantics and compact/DE sizing. Native and full accessibility/localization checks remain open.

Frames 08–13 and their Light/Dark introduction/other-permissions sources were repaired after a canvas clipping report. All six states are now checked at preferred 560 × 580, compact 520 × 560 and expanded 720 × 680, with successful resize roundtrips. Text origins remain inside clipping containers, the 48 pt icon remains square, controls retain intrinsic dimensions and the footer follows the bottom edge. [Repair evidence and sizing handoff](verification/menu-bar-onboarding.md#onboarding-layout-repair--2026-10-10) supersede the initial visual review; native/accessibility/RU/FR checks remain open.

Latest [alignment review](verification/alignment-review.md) covers all 22 frames and repairs 01–03/14–22: centered brand/footer rows, search/profile geometry, visible compact connectors and aligned columns, Settings subtitle/privacy spacing, fixed control sizes and window-edge anchors. Twenty-four transparent Stacks preserve existing IDs, content and materials. Representative expanded Light/Dark/compact/DE views and resize restoration passed; native runtime/accessibility/localization gates remain separate. UI-001 consumes this revision.

General/background contract: [UI-003](tasks/UI-003-general-settings.md), [delivery and source IDs](verification/general-settings.md), [25-key EN/RU/DE/FR copy](verification/general-settings-copy.json). Frames 23–32 add four reusable Light/Dark row sources, actual-state login recovery, global pause/runtime distinctions and window/Menu Bar/quit guidance. Expanded Light/Dark and compact DE/RU/FR checks passed; the final three-frame roundtrip restores 96 nodes exactly. Existing sources/Brand remain unchanged. Native integration/accessibility/login and rendered recovery translations remain open. Input is delivered below; Language/Advanced remain separate design slices.

Input/hold timing contract: [UI-004](tasks/UI-004-input-settings.md), [delivery and four source IDs](verification/input-settings.md), [18-key EN/RU/DE/FR copy](verification/input-settings-copy.json). Frames 33–39 cover read-only Input explanation and conditional per-binding duration/save failure. Double press follows macOS; pointer thresholds remain fixed; trackpad advertises only the existing experimental preset and retained native gestures. No global tuning preference introduced. Final Light/Dark expanded and Russian minimum sizing passed; 96 local node frames restore exactly. Input overview is reviewed in four languages; native/Dark/localized hold-editor acceptance remains open. Next design slice: Settings → Language, then Advanced.

## Brand: existing source and delivered assets

| Artifact | Source / delivery | Status |
| --- | --- | --- |
| App-icon Frosted geometry | Symbol `AA064C59-AD8E-40E1-A7DF-DF7F6949C136` on 04 · Symbols | Refined editable vector source |
| Small optical geometry | Symbol `5E88F8C5-D3D4-40EB-AD5B-D459FFECFD54` | Wider counters/optical treatment; static reference |
| App-icon review board | `0C9B719F-193A-4298-85E1-05576002F92E` on 05 · Brand | Current review placement |
| Dock/Finder delivery | [rebind/AppIcon.icon](../rebind/AppIcon.icon/) | Integrated native Composer package, Debug/Release/Finder evidence |
| Menu Bar source | Symbol `0F0BD265-F8D6-4405-8425-247D8DA43C06`; board `EBAC2CD7-4F7F-4756-8BC4-AC1D43192933` | Separate monochrome optical vector |
| Menu Bar delivery | [RebindMenuBar.imageset](../rebind/Assets.xcassets/RebindMenuBar.imageset/) | Integrated named template, 18 pt/native resource checks |

Screen icons retain live Brand Symbols: Small at 32 pt in the three sidebars, Frosted at 48 pt in Light/Dark Setup and 80 pt in About. Shared `White face / UI <size> pt` and `Frosted rim / UI <size> pt` style overrides compensate for fixed-width borders when shrinking Symbols; original Brand styles/geometry remain unchanged. Use the corresponding size-specific styles for future instances rather than shrinking the original unscaled border. [Review and exact widths](verification/menu-bar-onboarding.md#screen-icon-consistency-repair--2026-10-10).

Sketch owns editable geometry/visual source. Icon Composer owns delivery materials, system masking and native appearances; export clean foreground/background layers rather than decorating them twice. Menu Bar uses a transparent monochrome template with system coloring, independent of the raised/gradient Dock artwork.

Detailed sources/material settings/revision workflow: [brand README](../assets/brand/README.md). Verification: [Composer](verification/app-icon-composer.md), [Menu Bar](verification/menu-bar-onboarding.md), [BRAND-001 remaining runtime checks](tasks/BRAND-001-icon-runtime.md). Superseded PNG catalog/reference exports were removed; the native `.icon` package is the sole app-icon input. The icon is already delivered; remaining Dock/tint/minimum-OS acceptance does not mean it needs creating again.

## Updating this design contract

After authorized design work, save and visually verify affected frames, then update this index and the task handoff with source IDs, version/date, reusable components, states/copy, changed scope, acceptance evidence and next action. Change SPEC only if behavior requirements changed. Track implementation/verification separately; an agent must not label design-ready as implemented.

This direction records the user's instruction of 2026-10-10. Future visual work should develop it within live Sketch's current design system. It authorizes the direction, not an unsolicited rewrite of every screen or an automatic Sketch edit.
