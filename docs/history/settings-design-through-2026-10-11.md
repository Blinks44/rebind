# Settings design evidence through 2026-10-11

Condensed on 2026-10-16 from four superseded design-delivery records. These are **dated agent-observed Sketch checks of the former Liquid Glass document**, not current visual instructions or new native/hardware verification. [DESIGN](../DESIGN.md) locates the replacement soft design system; inspect its live source for new work.

The original detailed records remain in Git at `1a0801b` under `docs/verification/{permission-recovery,general-settings,input-settings,language-settings}.md`. Removed detail was obsolete frame/component inventories, pixel geometry, repeated copy and completed next steps. Current behavior belongs to SPEC and the linked tasks; native evidence retains separate runtime/accessibility limits.

## Source and evidence scope

All four deliveries used Sketch 2026.3.1 / public API 2.0 through MCP. Save callbacks, saved archive integrity and model-preservation checks were observed. Existing artwork was preserved within each scoped edit; no app launch, real rules/grants/login change or remapping was performed by these design slices. Earlier screenshots were temporary and are not required to continue work.

| Slice / save | Saved SHA-256 | Original observed checks |
| --- | --- | --- |
| Permissions, 2026-10-10, alignment revision | `50859f5bfbe9d4bc031431e526ca03f65a3af3fd29e6e554cd867484c28a6f58` | Nine recovery states, compact/German repairs, six navigation edges, 53 four-language keys; 1,143 original nodes retained and 327 added in initial delivery |
| General, 2026-10-11 | `7ba3c8b345ae4b38eb1f8a7114d7cd8c9f7bdecdbe6491bb711f011f33868063` | Ten states, 21 navigation edges; 96 resize-node frames restored; 1,494 original nodes retained and 344 added |
| Input, 2026-10-11 | `9d37daa77514e03e0160141ea7dec33c2e234d32973596bd01e96ba33758f774` | Seven states and three resize views, 15 navigation edges, 18 four-language keys; 96 resize-node frames restored; 1,838 original nodes retained and 209 added |
| Language, 2026-10-11 | `ac799cf544157aeb6efee53213eccd87eb2c848a40408b2479c4ffd818fee5d2` | Eight states and three resize views, 32 navigation edges, 16 four-language keys; 91 resize-node frames restored; 2,047 original nodes retained and 276 added |

These hashes identify historical source artifacts, not today's Sketch file. Session-specific document/layer IDs are intentionally omitted. Passing prototype/resize/string checks did not establish arbitrary native sizing, actual OS state, spoken VoiceOver or production localization activation. Four-language evidence does not cover the later Spanish/Simplified Chinese expansion.

## Permissions

Original design baseline `365db64` → `acce2f4`. Setup-later keeps profiles/rules/manual editing accessible while capture/output require actual Accessibility/posting preflights. Missing grants, engine failure, deliberate pause and Secure Input are distinct. Explicit request/settings/refresh routes never simulate a successful grant; revocation cancels safely and retains saved intent. Input Monitoring is not a startup requirement for the active tap; other access remains feature-specific.

Compact/German checks found negative origins, oversized instances and clipped wrapped text; anchors and intrinsic sizing repaired the reference layouts. Native acceptance still needed real grants/revocation, focus/VoiceOver, adaptive preferences and translated/expanded states. Those gates are retained in [UI-001](../tasks/UI-001-permissions-onboarding.md) and [native evidence](../verification/permissions-native.md), which also records subsequent integration of all 53 original keys.

## General

Original baseline `acce2f4`. Global enabled intent is separate from actual runtime and SMAppService login status. Login registration/removal is explicit, refreshes real status after success/failure, preserves approval as a distinct state and does not modify pause/profile/rules. Busy/unavailable states must not imply success. Emergency pause stays paused in memory after a failed save; restoring a disk preference must not restart interception.

The design covered active/paused, approval/error/missing-access states, Light/Dark and compact localization; it did not prove real login, grants, native transitions or accessibility. [UI-003](../tasks/UI-003-general-settings.md) and [native evidence](../verification/general-settings-native.md) own current open acceptance, the later full-main overflow repair and AX-label checks.

## Input

Original baseline `acce2f4`. The slice exposed existing per-binding hold duration (100–5,000 ms, 100 ms step) and system double-press timing; it did not introduce global timing overrides or prove physical accuracy. Hold edits retain existing storage/cancellation behavior; save failure keeps a retryable draft. The old four-preset/shortcut-only trackpad description is superseded by SPEC §3.4.

[UI-004](../tasks/UI-004-input-settings.md) and [native Input/Language evidence](../verification/input-language-native.md) own subsequent implementation and physical timing/focus/accessibility gates. Later wheel, exclusions and smooth-scrolling behavior have their own INPUT tasks.

## Language

Original baseline `acce2f4` → `b453d8d`. The design established System Default plus the original four autonyms, draft versus saved/active language, conditional Apply, atomic save/retry, protected storage and explicit reopen guidance. Save must not change profiles/rules/pause, restart capture or quit/relaunch automatically. User content and shortcut identity stay unchanged. System Default resolves ordered supported preferences with English fallback.

Native integration chose manual quit/reopen for coherent SwiftUI/Foundation/Cocoa activation. [SPEC §11](../SPEC.md#11-localization-core) owns the current six-language contract; [UI-005](../tasks/UI-005-language-settings.md) and [native evidence](../verification/input-language-native.md) retain production relaunch, projection-repair and full accessibility/locale acceptance. The original scoped menu/layout review did not close those gates.
