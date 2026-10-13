# Language settings — design delivery

Historical Sketch PNG copies were removed on 2026-10-11. Use live Rebind.sketch via [DESIGN](../DESIGN.md); dated checks below remain historical evidence, not a new review.
Date: **2026-10-11**. Task: [UI-005](../tasks/UI-005-language-settings.md). Agent-observed Sketch verification; native localization activation, persistence and accessibility remain open.

## Saved source and preservation

Editable source: **Rebind.sketch**, resolved through live MCP. Sketch **2026.3.1**, JavaScript API **2.0**. Successful public `Document.save` callback observed. Saved document ID **`C93BE2C5-55E6-4493-9B4B-FD998F2DE986`**; resolve again before dependent work. SHA-256 **`ac799cf544157aeb6efee53213eccd87eb2c848a40408b2479c4ffd818fee5d2`**. Source now contains **47 screen frames**.

Started on `main` / `acce2f4`; checkout HEAD advanced independently to `b453d8d` during the work. Final handoff/exports are uncommitted; this design task performed no Git commit, app-source edit, runtime launch, grant change or real preference/rule change. Concurrent native General implementation is preserved and owns its own verification.

The pre-edit saved ZIP had **2,047 local page/layer nodes**. All preceding nodes compare unchanged by ID and non-child-list attributes: none removed or modified; **276 added**, final **2,323**. Existing shared layer/text styles also compare unchanged; one scoped menu style was added. ZIP integrity passes. Parent `layers` lists are excluded because new owned frames/sources were appended. Existing frames, Brand and General/Input/Permissions sources are preserved.

Subsequent [native implementation/evidence](input-language-native.md) integrates this bounded behavior and four-language copy. The design-only checks below retain their original scope; production input/relaunch/accessibility acceptance remains open.

## Frames and evidence

| Frame | Stable ID | Size / PNG |
| --- | --- | --- |
| 40 · Language / System Default · Light | `EDEFA711-A6AB-47C6-8471-D0FA965F3F30` | 1040 × 640 · [40](../DESIGN.md#screen-index-and-implementation-status) |
| 41 · Language / Pending choice · Dark | `B220CDBD-0E6C-4FA5-9CA3-F3130DED7B1F` | 1040 × 640 · [41](../DESIGN.md#screen-index-and-implementation-status) |
| 42 · Language / Russian · Compact | `66C93F75-C555-4C77-AEFC-36D156237C62` | 880 × 600 · [42](../DESIGN.md#screen-index-and-implementation-status) |
| 43 · Language / German · Compact | `DCAC62FA-AE96-4392-A0A1-863B81C1F19C` | 880 × 600 · [43](../DESIGN.md#screen-index-and-implementation-status) |
| 44 · Language / French · Compact | `97197B9F-FE43-4923-9B3D-16FD5B2E387C` | 880 × 600 · [44](../DESIGN.md#screen-index-and-implementation-status) |
| 45 · Language / Choice menu · Light | `56A6D424-96E0-4918-BCF8-34402AD910EC` | 1040 × 640 · [45](../DESIGN.md#screen-index-and-implementation-status) |
| 46 · Language / Save failed · Light | `845196E3-BB2F-4B55-B352-B652F47EA7E2` | 1040 × 640 · [46](../DESIGN.md#screen-index-and-implementation-status) |
| 47 · Language / Reopen required · Light | `B707527F-B13D-40B7-BE14-C6C90D766264` | 1040 × 640 · [47](../DESIGN.md#screen-index-and-implementation-status) |

Additional evidence: [German 1280 × 800](../DESIGN.md#screen-index-and-implementation-status), [Dark 1280 × 800](../DESIGN.md#screen-index-and-implementation-status), [reopen feedback 880 × 600](../DESIGN.md#screen-index-and-implementation-status). All eight final states and these three views were inspected through MCP screenshots. Eleven PNG signatures, dimensions and non-empty file sizes checked. These are suitable mock content; no user configuration is included.

German compact and Dark preferred → 1280 × 800 → original; reopen preferred → 880 × 600 → original: **all 91 local screen-node frames restore exactly**. Deferred nested layout was settled by applying the owned body Stack before verification. Minimum feedback wraps without clipping, popup width stays 208, system controls/sidebar/footer keep intrinsic sizes and anchors. Native scrolling/text expansion remains to be checked.

## Reusable components and layout

Six new sources on **04 · Symbols**, using existing sources and Apple macOS 26 controls:

| Source | Stable layer ID |
| --- | --- |
| Rebind/Light/Language/Preference row | `1F75EBCC-BA80-488E-BAFC-E7A08225A96F` |
| Rebind/Dark/Language/Preference row | `E488245D-5806-45BC-8105-02DE876A365B` |
| Rebind/Control/Dark language popup | `01F48685-A430-4BCB-A463-6190909FB3F6` |
| Rebind/Light/Language/Feedback | `8773BD64-4518-4BF8-8FBD-370ACB26B25F` |
| Rebind/Light/Language/Choice menu | `82C38198-B69C-46CE-A367-941EFBE9C4F3` |
| Rebind/Light/Language/Choice item | `C397DE3C-769B-4175-B6C9-E37E0A969B9F` |

Preference/feedback Column Stacks use 16 pt padding and 12 pt internal gap. Flexible row label, fixed 208 × 24 popup, fit-height descriptions/current-language status and intrinsic Apply/Quit buttons. Apply collapses when no draft change exists; the Feedback source's optional Quit collapses for save errors. Feedback headings fill available width for translations. Existing 232 pt sidebar, 28 pt detail gutters, selected section pill, glass navigation and calm cards retained. Body must scroll rather than compress controls when available height/text size requires it.

The Light popup is the imported native medium popup. The Dark popup derives from the existing native-derived Dark control; its scoped label style/chevron sizing fixes contrast without altering the original source. Menu items derive from Apple native items, with the existing SF checkmark and reserved selection space. No symbol detached. `Rebind/Light/languageMenuGlass` (`8ECEAE6B-E3BA-4DB4-9A79-72E32203FAE5`) derives from existing menu glass with 10 pt corners and bounded shadow, confined to the new menu source. In native UI use a system popup/menu; optical Sketch styling does not justify a custom language picker.

**32 outbound routes valid** across eight screens: General, Permissions, Input and About. Existing inbound routes unchanged. Apply/Quit and menu selection are state/OS contracts, not simulated success links. Advanced is not connected to an invented destination.

## Selection, saving and activation contract

1. Use a native single-selection popup containing **System Default**, **English**, **Русский**, **Deutsch**, **Français**, in that order. Localize System Default; keep language names as autonyms. Exactly one choice is selected; active language is separately shown below. Region variants resolve to supported base languages; choose the first supported system-preferred language, with English fallback, per SPEC §11. Do not modify macOS language settings.
2. A popup selection edits the page draft. Show **Apply Language** only when the draft differs from the saved preference; leaving Settings without applying discards that draft. Choosing an already-saved value is a no-op. The active display label must describe the currently rendered language, including when the preference is saved but awaits reopen.
3. Apply performs a versioned atomic configuration update using existing persistence ownership/migration, preserving every other field. During a bounded save, disable the language popup/Apply, show localized **Saving language…** and retain the rest of the page. Do not restart capture, execute bindings, change the selected profile, unpause, or request grants as a language side effect.
4. Save failure keeps the previous preference and active UI unchanged, retains the selected draft, shows frame 46's feedback and leaves Apply available for retry when writable. No false success or partial locale switch. Corrupt/future configuration protection disables writing and uses existing recovery, with the supplied language-specific explanation; it must not overwrite the protected file.
5. After successful saving, activate one coherent locale across all app-owned visible text, native controls, menus, sheets and accessibility labels **only if that live path is verified**. If native correctness requires relaunch, leave the complete visible UI in its current language and show frame 47's inline **Reopen Rebind** guidance. The saved choice becomes active on next launch. This is conditional per SPEC, not a forced architecture choice before native verification.
6. **Quit Rebind** is an explicit ordinary quit action. Do not quit/relaunch automatically, restore windows by launching another process, or label the button “Restart” without a supported restart mechanism. Remapping stops while the app is closed. The passive inline card can be left on screen or revisited; quitting later requires no extra confirmation step introduced by this design.
7. System Default is a preference, not a synonym for English. Re-resolve the ordered system preferences on launch. Any live refresh after a macOS language change must follow the same coherent activation/reopen policy. A saved language resolving to the current display needs no reopen; pending manual or system preference remains distinct from the active result.
8. Preserve profile/rule names, user-entered strings, paths/file names, shortcut key glyphs and action identity. Translate the interface/catalog labels, not user content or stored shortcuts. Preferences must survive relaunch and migration; manual locale storage/activation is still absent from the inspected baseline and needs implementation.

## Copy, accessibility and native acceptance

Copy handoff: **16 new keys × EN/RU/DE/FR**, structurally checked, non-empty; subsequently integrated into `Localizable.xcstrings` in the native delivery. Existing Settings/navigation copy is reused. Applied language overview is visually reviewed in all four languages; pending Dark and error/reopen/menu are English references. Translated/Dark feedback, busy/protected-storage and accessibility variations are specified here but still require rendered native verification. Copy follows the `writing-for-interfaces` skill and established utility voice.

Receiving implementation must verify:

- Default resolution, English fallback, all five choices/autonyms, no-op/draft discard, atomic failure/retry, protected storage, migration and relaunch persistence on an identified bundle.
- Whether native menus/sheets/accessibility permit coherent live switching; use reopen guidance when necessary and verify its saved/active distinction and ordinary quit behavior.
- Light/Dark, EN/RU/DE/FR, minimum/preferred/expanded windows, longer failure/reopen strings and scrolling. Native menu may size beyond the 208 pt closed control for localized System Default; no truncation or fixed mobile-style menu rendering.
- Keyboard access, visible focus, popup label/selected state, focus restoration after menu dismissal and one meaningful announcement per status. Use native popup/menu semantics; announce save failure and pending-reopen status without duplicate labels. Reduce Transparency/Increase Contrast use semantic opaque materials; Reduce Motion must not introduce decorative transitions.

Affected documentation links/status reviewed; `git diff --check` passes. Curated exports/task/evidence are not excluded by Git ignore rules. No new app build, runtime/hardware test or grant in this design slice. Ready bounded handoff: **Language settings and localization activation**. Next design slice: **Settings → Advanced**; remaining design coverage is indexed in [DESIGN](../DESIGN.md#remaining-design-coverage).
