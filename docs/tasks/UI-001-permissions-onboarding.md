# UI-001 — coherent first-run and permission recovery

- Updated: 2026-10-10, after the scoped onboarding layout review.
- Stage: `in_design`; repair of frames 08–13 is complete. Additional permission compositions and native implementation remain open.
- Owner: Unassigned for the next slice; current design chat (`/root`) completed and released the scoped layout review on 2026-10-10.
- Reviewed surfaces: Sketch frames 08–13 and their setup introduction/other-permissions sources. No app source/catalog ownership claimed; preserve concurrent workflow/input work.
- Requirements: SPEC §§6–8/10–11, S2; PLAN Phases 7–9; DESIGN's modern macOS 26+ direction.
- Code baseline inspected: `6c1a5be`, functional actual permission checks/guidance exist.

## Outcome and scope

Provide a clear native first-run flow and recovery when grants are missing/revoked. Preserve real checks and user rules/intentional pause. Start by completing the missing-permission main-window and Settings → Permissions design, then implement a bounded onboarding slice; do not build all Settings, fake grants or alter capture behavior to match a mock.

## Design handoff

Saved `Rebind.sketch`, 2026-10-10; current document ID `A2DE362A-E026-47F5-8F3E-FBC3AF4353DD`, resolve live again. Saved revision SHA-256: `1fd30ff5ef06830fdb4ce6b8927133943e267b17a671218743a39f65b9915f4d`. Six permission frame IDs remain stable in [DESIGN](../DESIGN.md#screen-index-and-implementation-status). Repaired Light/Dark setup components and Apple macOS 26 controls remain live and reusable.

Saved/reviewed states: Accessibility missing Light/Dark, AX granted/event-posting missing, ready, revoked and German expansion. The latest review fixes negative text origins, a vertically compressed icon, unanchored symbol contents and inconsistent button spacing. All six states were screenshot-checked at 560 × 580, 520 × 560 and 720 × 680; resizing back restores the original geometry after applying Stacks. See [layout review](../verification/menu-bar-onboarding.md#onboarding-layout-repair--2026-10-10).

Implementation sizing contract: preferred 560 × 580; tested minimum 520 × 560, 32 pt outer margins, square 48 pt introduction icon, fixed-size native buttons, 16 pt permission-action gap and footer pinned 32 pt above the bottom. Keep text wrapping and use scrolling for content that exceeds the native available height rather than shrinking typography or controls. Setup-later's main-window destination and Settings → Permissions still need composition. Ready means actual grants, not a successful tap/engine. RU/FR/runtime layouts and accessibility settings remain open; no blanket user acceptance is claimed.

Repaired live sources on **04 · Symbols**:

| Source | Stable layer ID |
| --- | --- |
| Rebind/Light/Setup/Introduction | `BBBC8810-6979-4192-BE0A-A1E845943656` |
| Rebind/Dark/Setup/Introduction | `86843F55-7D06-478D-B2EF-1CF0B440722D` |
| Rebind/Light/Setup/Other permissions | `24A3BC50-657A-44EE-A371-D22ADD95F36F` |
| Rebind/Dark/Setup/Other permissions | `3FB04F76-BE49-44DE-9DB0-A6A2A0F4419C` |

[Copy handoff](../verification/permissions-onboarding-copy.json): 28 keys × EN/RU/DE/FR, not integrated into the app catalog. Use Writing for Interfaces when revising user-visible text; preserve terminology and all languages.

## Acceptance

- [x] Scoped repair: existing frames 08–13 saved, visually checked at three sizes, and resize roundtrip geometry verified; unaffected Sketch artwork preserved.
- [ ] Missing-permission main-window and Settings → Permissions states saved and visually checked in current Sketch, with IDs/version/state behavior recorded.
- [ ] Native onboarding uses existing AX/posting preflights; grants are never inferred from button taps or requested by polling.
- [ ] Setup-later, ready and revocation routes are real; recording/remapping remain unavailable without required access, engine errors stay visible, deliberate pause/rules preserved.
- [ ] Current tap does not ask for unrelated Input Monitoring/Full Disk Access/Screen Recording. Automation remains action-specific.
- [ ] Native implementation builds; meaningful transition tests use isolated state; permission behavior separately checked with actual grants when authorized.
- [ ] Light/Dark, window sizing, EN/RU/DE/FR, keyboard/VoiceOver and transparency/contrast/motion settings verified for the delivered slice; handoff retains open checks.

## Implementation and verification

Baseline has `InputPermissions`, `InputPermissionRequirement`, `PermissionView`, `AppModel` actual checks and explicit request/settings/refresh routes. Existing guidance is not the saved first-launch UI. Current app has no Settings scene/About/onboarding implementation. Menu Bar asset delivery is separate and already integrated.

Prior screenshots, saved-document integrity, copy and icon-resource build checks are recorded in [menu-bar/onboarding verification](../verification/menu-bar-onboarding.md). No app build or permission grant was performed during this workflow migration.

## Next handoff

- **Design — actionable:** refresh the live Sketch source/ownership, compose the missing-permission main-window and Settings → Permissions surfaces using existing components and material direction, save/screenshoot and record frame IDs. State the ready bounded implementation scope and remaining design checks.
- **Code — dependent handoff:** refresh this record and live frames before implementing the prepared first-run/permissions scope. The full flow is not yet ready; the additional surfaces above are pending. Proceed only on a genuinely ready bounded slice or independent authorized prerequisites, preserving actual permission checks and user rules. Record justified native differences.
- User-facing handoff name: **first-run and permissions**. A request to continue its design or implement its prepared design resolves here without requiring `UI-001`. No automatic agent messaging or extra design-approval gate is implied.
