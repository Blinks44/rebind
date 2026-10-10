# Menu Bar template and first-launch design

Reviewed 2026-10-10. Scope: SPEC §§6–8, 10–11, S2, Phase 8. The Menu Bar asset is integrated; the onboarding screens are design artifacts, not implemented native onboarding.

## Live Sketch source

Saved `Rebind.sketch` through Sketch MCP 2026.3.1 / API 2.0.0. Post-save document ID: `5E7440F8-E8FE-4C5B-9691-D1A211777C77`. Layer IDs remain stable. Pre-edit disk backup: `/tmp/rebind-menubar/Rebind-before.sketch`. Existing screens, brand sources, engine changes, rules, permissions and app settings were preserved.

- **04 · Symbols → Rebind/Brand/Menu Bar Template**, `0F0BD265-F8D6-4405-8425-247D8DA43C06`.
- **05 · Brand → 02 · Rebind / Menu Bar Template**, `EBAC2CD7-4F7F-4756-8BC4-AC1D43192933`.
- Reusable setup introduction / other-permissions components have Light/Dark sources on **04 · Symbols**. Shared SF Pro styles, semantic Color Variables and Apple macOS 26 button sources are retained. No library detachment or bitmap replacement.

New frames on **01 · Screens**, all 560 × 580 pt:

| Frame | ID | Review export |
| --- | --- | --- |
| 08 · First Launch / Accessibility required · Light | `EDA6F1D6-D17F-4ABB-8A72-1DECF5EDE4F4` | [Light](onboarding/first-launch-light.png) |
| 09 · First Launch / Accessibility required · Dark | `F0F88FE5-F6A1-4402-965E-96B83A27B732` | [Dark](onboarding/first-launch-dark.png) |
| 10 · First Launch / Event sending required · Light | `18E3BEB1-9333-4C8E-97F1-F8233CAB8A95` | [Event sending](onboarding/event-sending-required.png) |
| 11 · First Launch / Ready · Light | `B01D939A-7E79-4E5A-9385-3F494EF9CF80` | [Ready](onboarding/ready.png) |
| 12 · Permissions / Access revoked · Light | `A2F08C1D-327C-4108-8C14-6AD6E320918F` | [Recovery](onboarding/access-revoked.png) |
| 13 · First Launch / German text expansion | `E207327E-5664-496C-999A-2B7A69B61335` | [German](onboarding/german-expansion.png) |

The current Sketch document remains authoritative; exports are review aids. Screens are not an interactive simulation of macOS permission prompts. No prototype links fabricate a successful grant or modify System Settings.

## Menu Bar asset

Derived the Small optical source's compound face, including enlarged counters, into an 18 × 18 pt transparent canvas with a 16 pt black silhouette and 1 pt inset. Removed shared material fills, borders, shadows and lighting. The black source is reused with white tint in the Dark preview; the app uses one template asset, with system coloring for appearance/selection.

- Editable SVG: `assets/brand/Rebind-MenuBar.svg`.
- Delivery PDF: `rebind/Assets.xcassets/RebindMenuBar.imageset/RebindMenuBar.pdf`.
- Image Set: mac idiom, `template-rendering-intent: template`, `preserves-vector-representation: true`.
- `rebindApp.swift`: `MenuBarExtra("Rebind", image: "RebindMenuBar")`; app-name semantics and existing menu behavior preserved.
- Preview: [actual-size Light/Dark and enlarged geometry](../../assets/brand/Rebind-MenuBar-preview.png).

Native implementation uses [Apple MenuBarExtra's named-image initializer](https://developer.apple.com/documentation/swiftui/menubarextra/init(_:image:content:)) and [template-image behavior](https://developer.apple.com/documentation/appkit/nsimage/istemplate). The 18 pt canvas is the selected optical design size, not a claimed mandatory HIG dimension. No dependencies or custom status-item implementation added.

## Permission behavior for implementation

Inspected `InputPermissions`, `InputPermissionRequirement`, `PermissionView`, and `AppModel` before composing these states. Keep their actual preflight checks and request/open-settings routes:

1. Missing Accessibility (`AXIsProcessTrusted == false`): explain purpose, open Privacy & Security → Accessibility, offer refresh and setup-later. Continue stays disabled.
2. Accessibility granted but posting unavailable (`CGPreflightPostEventAccess == false`): show that distinction, offer the explicit event-posting request and refresh. Do not request from polling or treat a click as a grant.
3. Permissions ready: both checks succeed. Continue becomes available. This state does not prove tap creation or running-engine success; tap errors must remain visible in the native app.
4. Input Monitoring is not separately required by the current active tap. Automation remains action-specific; never request unrelated Full Disk Access or Screen Recording. Re-evaluate this explanation if capture changes.
5. Revoked access: stop safely, preserve rules, retain normal input, offer settings/refresh/close. Keep global pause unchanged; recovery must never override an intentional pause.
6. Setup-later should enter the ordinary app with a missing-permission status and disabled recording/remapping. Designing that main-window empty/permission state is a next slice; the existing Work list is not used as a fake successful destination.

Copy is concise and uses existing localized permission terminology. [Copy handoff](permissions-onboarding-copy.json) contains **28 keys × EN/RU/DE/FR**, all nonempty. It is not integrated into `Localizable.xcstrings`. German expansion is visually checked, including native button widths and the full “Nicht erforderlich” status; RU/FR layout and all runtime localization remain open.

## Verification

- `scripts/dev.sh build` in the restricted environment failed because Xcode's macro plugin sandbox/asset renderer could not run. The approved ordinary build outside that sandbox succeeds; no project/security settings changed.
- `scripts/dev.sh build` and `scripts/dev.sh release`: **BUILD SUCCEEDED**. Logs `/tmp/rebind-menubar/build-approved.log`, `/tmp/rebind-menubar/release.log`. Only the expected AppIntents metadata-skipped warning.
- Native AppKit resource assertion `/tmp/rebind-menubar/check-asset.swift`: Debug and Release each load `RebindMenuBar` at **18 × 18 pt**, **isTemplate = true**, six representations. Used a temporary module cache. No app launch or remapping run.
- `codesign --verify --deep --strict`: Debug/Release pass.
- All new appearance batches screenshot-reviewed. Latest captures confirm readable Light/Dark text, intact mark/counters, correct native labels, permission-dependent continuation, recovery state and German expansion. Post-save capture confirms the saved first-launch frame.
- Saved Sketch ZIP CRC passes; all eight required new asset/board/screen IDs exist. **1,137 local layers, zero duplicate layer IDs, zero nonfinite frames, zero missing Symbol references**. Six PNG exports each measure 560 × 580.
- `git diff --check` passes. No behavioral engine/persistence code changed by this task, so no additional matcher tests were added or claimed. Other uncommitted engine work is outside this task's verification scope.

Live Menu Bar rendering after user relaunch, macOS 26 runtime, selection/high-contrast/accessibility settings, keyboard/VoiceOver, native permission transitions and RU/FR layouts remain manual or implementation checks. The design is not evidence of a hardware/permission acceptance pass.

Next: design the first empty bindings window with permission guidance and the permission section in Settings, then implement the approved onboarding using actual state checks. Menu contents/remaining Dark states can be composed from the existing native components without changing the engine.
