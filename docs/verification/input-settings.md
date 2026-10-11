# Input settings and per-binding hold timing — design delivery

Date: **2026-10-11**. Task: [UI-004](../tasks/UI-004-input-settings.md). Agent-observed Sketch artifact verification; native UI/runtime/accessibility acceptance remains open.

## Saved source

Editable source: **Rebind.sketch**, resolved from the open document by name through Sketch MCP. Sketch **2026.3.1**, JavaScript API **2.0**. Saved document ID **`E50CA3D9-82B1-44C0-AC97-39F1A9663700`**; resolve again before dependent work. SHA-256 **`9d37daa77514e03e0160141ea7dec33c2e234d32973596bd01e96ba33758f774`**. Successful public `Document.save` callback observed. Git baseline `main` / `acce2f4`; records/exports remain uncommitted. No app source, rules or permissions changed by this design task.

The saved source has **39 screen frames**. The pre-edit ZIP snapshot had 1,838 local page/layer nodes; all compare unchanged by ID and non-child-list attributes. No original node removed, **209 new local nodes** added, final **2,047** nodes. Existing General/Permissions/editor/shared styles/Brand remain intact; native Stepper imported from the already available Apple macOS 26 UI Kit. ZIP integrity passes. The comparison excludes parent `layers` lists because new owned frames/sources were appended.

## Frames and curated evidence

| Frame | Stable ID | Size / PNG |
| --- | --- | --- |
| 33 · Settings / Input · Light | `F121172C-AC90-4D1F-9A0E-5E467E3E07F4` | 1040 × 640 · [33](input-settings/33.png) |
| 34 · Settings / Input · Dark | `95BC21C9-2B67-4B55-B09C-11C2BEFAFABC` | 1040 × 640 · [34](input-settings/34.png) |
| 35 · Settings / Input · Russian | `F9CF0786-1007-474E-9B03-1F4A2AC7BA4E` | 880 × 600 · [35](input-settings/35.png) |
| 36 · Settings / Input · German | `E71C9EC6-2F72-4DA9-A8A6-AAADA548EC40` | 880 × 600 · [36](input-settings/36.png) |
| 37 · Settings / Input · French | `CA520624-1683-434F-B654-86F07878F896` | 880 × 600 · [37](input-settings/37.png) |
| 38 · Edit Binding / Hold | `57339F81-811A-43DB-B920-02525FC5B3BD` | 512 × 570 · [38](input-settings/38.png) |
| 39 · Edit Binding / Hold / Save failed | `EDAE6F9E-A2E5-4942-BAE0-500059DF5145` | 512 × 700 · [39](input-settings/39.png) |

Additional resize evidence: [Light 1280 × 800](input-settings/input-light-expanded.png), [Dark 1280 × 800](input-settings/input-dark-expanded.png), [Russian 850 × 560](input-settings/input-ru-minimum.png). All ten PNG signatures/dimensions/non-empty sizes checked from the final export files. All seven final frame compositions, the three exported resize views and English 880 × 600 were inspected through MCP screenshots after relevant edits. No clipping remains in the reviewed final sizes.

## Reusable sources and layout

New sources on existing **04 · Symbols** page:

| Source | Stable layer ID |
| --- | --- |
| Rebind/Light/Input/Information row | `072CBBD6-6B06-47BE-815E-AB101EB4AA02` |
| Rebind/Dark/Input/Information row | `0E92B3FF-EA3D-4AC9-8B64-7F26257FF088` |
| Rebind/Light/Input/Hold duration row | `CEDD484F-F934-4201-95CD-E618340A6FF1` |
| Rebind/Light/Input/Binding save failure | `DFCE2CBB-2A52-4915-A9BB-C8B64C6C9971` |

Information rows reuse existing status-row structure: Column Stack, padding 16, gap 12, heading Row with title and right-aligned secondary status. Descriptions fit their content height; instances fill the available width. Shared semantic typography and existing calm raised surfaces retained. Dark status alignment explicitly corrected after applying the shared text style. Hold heading uses a flexible title, intrinsic value and fixed-size native Stepper with gap 12. No editable numeric text field is proposed.

Main shell: 232 pt sidebar, 28 pt detail gutters, existing section buttons and tinted selected pill. Content starts at y=220. Card gaps: 16 at regular width, 12 in compact layouts; maintain the hierarchy rather than proportionally scaling controls. The native body must be a ScrollView for smaller available height/accessibility text expansion; sidebar/footer anchors and system controls retain intrinsic sizes. Editor content remains a ScrollView with its existing footer semantics. Native editor currently defaults to 540 pt width; reconcile the 512 pt optical reference without forcing a toolchain/window architecture change.

Final resize checks: English Light additionally checked at 880 × 600 with compact 12 pt card gaps; Light/Dark 1040 × 640 → 1280 × 800 → original, Russian 880 × 600 → 850 × 560 → original. **All 96 local screen-node frames restore exactly** against the relevant baseline. Sketch deferred nested layout initially retained previous widths; applying the owned Stack after a temporary gap change settled the layout. Minimum-size introductory/helper copy and compact gaps were then refined and rechecked; final evidence supersedes the clipped intermediate screenshot. A failed read-only ancestor-method probe made no mutation; the documented frame-scoped `find` query passed instead.

Fifteen outbound prototype routes from the five Input screens are valid: General, Permissions and About. Existing screens' inbound routes were preserved. Category navigation and real OS/runtime transitions are implementation contracts, not simulated success links. Input does not choose an arbitrary binding or jump straight to the hold example.

## Behavior and capability contract

### Input overview

- This bounded design exposes existing behavior rather than adding global timing preferences. Settings → Input explains where hold timing is edited, the system double-press interval, fixed cardinal pointer recognition and the experimental trackpad limit. Future meaningful adjustable thresholds remain a separate research/implementation decision under SPEC; this delivery does not close every Input requirement.
- `Binding.holdDurationMilliseconds` is per binding, defaults to 500, and validates 100...5000. `BindingEditor` already has a 100 ms Stepper when Hold is selected. Navigate through Keyboard or Mouse, then edit the relevant binding in the currently selected profile. No physical-device picker or automatic profile change.
- `AppModel.configureEngine` reads `NSEvent.doubleClickInterval` and passes a validated interval to the matcher. Do not render an independent Rebind double-press slider or claim a static 500 ms user preference. Follow the existing engine refresh lifecycle; changes to that lifecycle require their own engineering checks.
- Mouse gestures use middle/numeric extra buttons with the four cardinal directions. Current thresholds are fixed; relative Quartz movement is not physical millimeters or display points. No sensitivity slider, fake distance unit or arbitrary button-count ceiling.
- Trackpad card describes only **built-in unmodified four-finger tap → shortcut**. Native gestures remain active and may respond simultaneously. Other gestures, external Magic Trackpad and broader action/modifier support are not selectable from this handoff. No recorder or experimental tolerance controls.
- Overview is informative and remains readable while remapping is paused or required permissions are missing. Editing saved configuration is distinct from running/capturing input. Permission/runtime recovery belongs to UI-001/UI-003; no fake readiness badge.
- No user-data-dependent overview rows or asynchronous lookup: the same composition handles profiles with zero rules or no Hold bindings. Do not invent empty/loading errors for static information.

### Hold editor and save failure

- Show duration only for supported keyboard/mouse-button Hold activation, using the existing activation constraints. Hide it for Press, Double Press, scroll, pointer gestures and trackpad presets; preserve the draft when switching where existing behavior permits.
- Native bounded Stepper changes by 100 ms with 100 and 5,000 inclusive limits. Stop decrement/increment at the appropriate boundary. Retain valid migrated values that are not exact multiples of 100; do not silently round existing configuration or force a schema change. Format value/range and VoiceOver increment/decrement announcements in the selected locale.
- A press must last at least the configured duration to qualify, subject to current safety/cancellation/lateness guards. Early release cancels; action is one-shot. The visual copy does not prove deadline accuracy or hardware delivery.
- Save commits only this binding, preserving ID/profile/other rules and global pause. Draft edits are not live changes; use existing cancellation/recording/persistence ownership. Cancel dismisses without saving. Recording remains disabled when capture cannot safely start; missing grants do not disable explanatory text or erase configured duration.
- Frame 39 is **Edit Binding** storage failure: leave the previous saved binding unchanged and retain the complete editor draft. Keep Save Binding available for retry when storage is writable, retain Cancel, and do not dismiss or show false success. Locked corrupt/future storage instead disables saving and uses existing recovery; conflict/unsupported-input messages remain their existing specific errors, not the generic storage-failure copy.
- No input action, engine start or system preference was executed to validate these designs.

## Copy, accessibility and remaining checks

[Copy handoff](input-settings-copy.json): **18 new keys × EN/RU/DE/FR**, all locale entries non-empty and structurally checked. Settings shell/category/editor labels reuse earlier handoffs/current catalog. Copy uses the established calm, direct utility voice and the `writing-for-interfaces` skill. Input overview is visually reviewed in all four languages. Hold/error editor translations are authored but their native/Dark/localized rendered compositions remain to be verified during integration; do not claim all editor locale layouts passed.

Native acceptance for the receiving implementation:

1. Integrate the overview and new conditional hold composition using current models; verify selected-profile routing, live system interval source and read-only experimental limits.
2. Check 100/500/5,000 ms and migrated non-step values, early release, one-shot output and recording cancellation on supported physical input. Verify actual atomic save failure/retry/Cancel and unchanged prior configuration.
3. Review Light/Dark and EN/RU/DE/FR at supported minimum/preferred/expanded sizes, including editor/error translations and scroll behavior. Verify Reduce Transparency, Increase Contrast and Reduce Motion with native semantic materials.
4. Verify full keyboard navigation, labeled native Stepper/value/units, one announcement per label, visible focus and VoiceOver order. Information status labels must not be announced as disabled controls. Capture/permission/runtime effects require identified native artifact evidence.

No new build, app launch, hardware test or permission grant in this design slice. Existing engineering results remain attributed to their own verification records. Next design slice: **Settings → Language**, then Advanced.
