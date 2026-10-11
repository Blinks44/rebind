# General settings — design delivery

Historical Sketch PNG copies were removed on 2026-10-11. Use live Rebind.sketch via [DESIGN](../DESIGN.md); dated checks below remain historical evidence, not a new review.
Saved and reviewed 2026-10-11. Scope: UI-003, SPEC §§6, 8, 10–11 / S1, design only. Git baseline `main` / `acce2f4`; prior permission/alignment work and concurrent trackpad engineering are preserved. `rebindApp.swift` and `AppModel` were inspected for window lifetime, Menu Bar, quit and enabled-state behavior. No app source, real configuration, login item or permissions changed.

## Saved source and preservation

`Rebind.sketch`, Sketch **2026.3.1**, public API **2.0.0**. Final document ID **`56ED9B64-CF2D-4FE8-AB0E-4EA4E3501214`**; resolve again before work. SHA-256 **`7ba3c8b345ae4b38eb1f8a7114d7cd8c9f7bdecdbe6491bb711f011f33868063`**. Explicit save callback succeeds and saved ZIP CRC passes.

Saved-model comparison with the preceding alignment revision (`50859f5…`) retains all **1,494 original page/local nodes unchanged**, removes none and adds **344**. Existing screens, navigation, shared styles, Brand, Foundations and Components remain unchanged. New frames and four Symbol Sources reuse existing semantic typography/materials and live Apple macOS 26 controls; no Symbol detached or external library source edited.

## Frames on 01 · Screens

| Frame | Stable ID | Size | Evidence |
| --- | --- | --- | --- |
| 23 · General / Enabled · Light, login off | `2C9A6A68-F839-46C2-BF15-E672107FB024` | 1040 × 640 | [Light](../DESIGN.md#screen-index-and-implementation-status) |
| 24 · General / Paused · Dark, login on | `410A654D-4DF2-4810-9EA2-79242185FEC3` | 1040 × 640 | [Dark](../DESIGN.md#screen-index-and-implementation-status) |
| 25 · Login approval required | `067A6C10-7A7D-406A-B26F-FABEDC1DA9DD` | 1040 × 640 | [Approval](../DESIGN.md#screen-index-and-implementation-status) |
| 26 · Login enable failed | `4788D158-8D0B-4FF1-9606-CAA460194EFF` | 1040 × 640 | [Enable error](../DESIGN.md#screen-index-and-implementation-status) |
| 27 · Required access missing, enabled intent retained | `10363873-FAC1-4DCA-9180-0315D7C493F9` | 1040 × 640 | [Missing access](../DESIGN.md#screen-index-and-implementation-status) |
| 28 · General / German | `53A0F080-03E7-4FE8-A05E-8EB1AF8DF7AF` | 880 × 600 | [German](../DESIGN.md#screen-index-and-implementation-status) |
| 29 · General / Russian | `94510528-E1B3-403B-97AA-943B664B5D8D` | 880 × 600 | [Russian](../DESIGN.md#screen-index-and-implementation-status) |
| 30 · General / French | `72D357F2-458E-432D-B344-DE9310F27F6C` | 880 × 600 | [French](../DESIGN.md#screen-index-and-implementation-status) |
| 31 · Login removal failed | `C9407364-ECD6-4C46-B051-EECF9BB7A031` | 1040 × 640 | [Removal error](../DESIGN.md#screen-index-and-implementation-status) |
| 32 · Remapping could not start, enabled intent retained | `2BDAD1BE-0E66-42EB-82EC-EDFED6974A84` | 1040 × 640 | [Engine error](../DESIGN.md#screen-index-and-implementation-status) |

All ten states inspected with explicit-ID MCP screenshots after their relevant edits. Ten final 1× PNG exports have matching header dimensions. New Permissions/About prototype links and missing-access CTA: **21 valid connections**, none launch System Settings or change actual login state. Existing frames' inbound navigation is unchanged. Prototype permissions destinations are design references; the native app must retain actual grants and current locale.

## Reusable sources on 04 · Symbols

| Source | Stable layer ID |
| --- | --- |
| Rebind/Light/General/Toggle row | `2382D47F-31B3-44FC-84C2-A1F3B5069935` |
| Rebind/Dark/General/Toggle row | `90048979-85B9-42B4-B994-CDB836E96B7A` |
| Rebind/Light/General/Background behavior | `35469E6F-607D-4F70-A738-928B3BA20DF4` |
| Rebind/Dark/General/Background behavior | `1927C308-28C4-4603-B6A4-77D86544BB59` |

Toggle rows use a horizontal Stack with a filling text column, 16 pt padding, 24 pt text/control gap, 8 pt text gap and a fixed **54 × 24** Apple medium toggle. Row height follows wrapped text: default 69 pt, Russian remapping 83 pt. Background row is 73 pt in English and 87 pt in compact DE/RU/FR. Recovery buttons are live native instances in a wrapping Stack; their action group is hidden without reserved space in ordinary rows. Login approval/error rows hide the toggle and state the actual condition in text.

Glass stays on navigation/profile controls. Calm semantic content surfaces reuse the permission-page treatment. No extra dock visibility/menu-bar-only preference is introduced: closing the window and quitting are distinct existing behaviors.

## Behavior and implementation handoff

- **Global enabled:** bind to the existing persisted global enabled state, using its safe cancellation/passthrough path. Pausing retains rules/profile. Failed resume retains paused state; explicit pause cancels output immediately and remains paused in memory even if saving fails, exposing the save error. A failed write does not establish durable pause after relaunch. Respect configuration locking. Reuse the existing Menu Bar pause/resume control and keep all surfaces synchronized.
- **Actual runtime:** display Active only while runtime state reports running. Enabled intent can coexist with missing grants, a starting state or an engine error. Show permission recovery or bounded retry accordingly; never label the checkbox itself as proof of a running tap. Background/login changes must preserve deliberate pause.
- **Login off/on:** use actual `SMAppService.mainApp.status`. `notRegistered` displays Off; `enabled` displays On. Register/unregister only following the corresponding explicit user action, then refresh real status. Do not overwrite OS state with a stale JSON boolean or change remapping enabled state when registering.
- **Approval:** `requiresApproval` uses frame 25: explain approval, Open Login Items, Check Again, Turn Off. Open the public Login Items panel; re-check on focus/return and explicit Check Again. Turn Off cancels registration. Clicking Open Login Items is not approval evidence.
- **Failure:** frame 26 covers a failed enable with confirmed Off state; frame 31 covers a failed removal with confirmed On state. Try Again retries the failed operation. Open Login Items offers system review. Choose copy from the refreshed status; do not assume a thrown operation leaves any particular status. If status cannot be established, use unavailable copy instead of claiming On/Off.
- **Unavailable and busy:** `notFound`/unknown availability uses the same inline recovery composition with unavailable copy and Open Login Items. Pending register/unregister disables only affected login actions and exposes the localized progress message; it does not block global pause, navigation or editing. Busy/not-found compositions are specified here, rather than additional saved frames. Never add automatic retries or repeated approval prompts.
- **Window and Menu Bar:** closing the window keeps the existing single model/runtime alive. Open Rebind reopens that window; Settings opens its existing section; Quit Rebind stops the app through its existing termination path. Do not create a second engine or a redundant background-process toggle. Start at login restores enabled/profile state and resumes only when actual grants allow it; intentional pause survives.
- **Sizing:** preserve the 232 pt sidebar, 28 pt detail margins, fixed native controls and 16 pt row gaps. Use a native scroll container below the Settings/status chrome when content exceeds the window; wrap labels/descriptions/actions instead of scaling typography or clipping switches. Preferred 1040 × 640; compact references 880 × 600; minimum 850 × 560 checked on Russian General. Compact Sketch chrome reserves space for a two-line status explanation; native layout should follow actual text height with consistent gaps, rather than hardcode per-locale coordinates.
- **Accessibility:** keyboard order follows Settings sections, global enabled, login toggle or recovery buttons, then navigation. Use each row title as the toggle label and associate its description; decorative glyphs do not produce duplicate announcements. Inline status changes need restrained announcements. Native focus, VoiceOver, disabled/busy semantics and opaque/high-contrast materials require implementation checks.

API basis refreshed 2026-10-11: Apple's [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice) documents main-app login registration/status and [openSystemSettingsLoginItems](https://developer.apple.com/documentation/servicemanagement/smappservice/opensystemsettingsloginitems()). No new capture/action mechanism or dependency is selected by this design task.

## Copy and verification limits

[Copy handoff](general-settings-copy.json): **25 new keys × EN/RU/DE/FR**, plus existing Settings/common copy from [permissions handoff](permissions-onboarding-copy.json) and navigation/Quit Rebind from the app catalog. All four keys sets are complete and nonempty; all 25 keys are now integrated exactly in the app catalog; [native evidence](general-settings-native.md) records the subsequent implementation. German/Russian/French ordinary General layouts were inspected at 880 × 600. Recovery/error/progress translations are authored; subsequent native fixtures cover all four locales. Actual login and assistive-technology acceptance remains open.

Expanded Light/Dark at **1280 × 800** preserve sidebar/footer anchors and control size. Russian at **850 × 560** retains readable controls and wrapping. Early minimum captures exposed deferred nested layout clipping; row edge anchors and explicit settled Stack recalculation corrected it. After final restoration, all **96 local screen-node frames** in Light/Dark/Russian match the pre-roundtrip geometry exactly. Sketch deferred recalculation required a fresh call/settling and gap invalidation before accepting restored nested widths; do not accept the first stale capture or serialize entire library-rich trees. This scoped check does not prove every possible size or native scrolling.

Saved ZIP/digest/model preservation, export sizes, prototype targets, copy JSON, affected links/status and `git diff --check` were checked. No app build, launch, real login registration, grants, remapping, hardware or native accessibility checks in this design-only task. No Git commit made. Runtime/minimum-OS/locale/accessibility acceptance remains open for implementation.

**Current native handoff:** General is implemented/software-tested; [native evidence](general-settings-native.md) owns final artifacts, fixture checks and remaining actual login/relaunch/accessibility acceptance. Next independent code slice: Input overview and per-binding Hold timing.

**Current design handoff:** Input and Language are delivered in UI-004/UI-005; next Settings slice is Advanced. Preserve unsupported categories and the experimental trackpad boundary.
