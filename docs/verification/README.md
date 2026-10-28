# Verification records

[CAPABILITIES](../CAPABILITIES.md) summarizes current support; [STATE](../STATE.md) indexes active tasks and [SPEC](../SPEC.md) owns current requirements. Read only evidence relevant to the task. A dated report describes its tested artifact: old schemas, controls, locale counts and implementation contracts are not today's product specification.

| Topic | Evidence / current owner |
| --- | --- |
| Final release pass | [Remaining acceptance queue](release-candidate.md), [final app preparation and package](../tasks/REL-003-final-app-readiness.md); previously confirmed subsets retained |
| October 18 manual checklist | [Reported passes, artifact limits and remaining checks](manual-test-2026-10-18.md); DEVICE-004/005, REVIEW-002 and INPUT-009/013/014 |
| Keyboard/mouse and lifecycle | [Phase 1](phase-1.md); [CAPABILITIES](../CAPABILITIES.md) routes specific input subsets. Retired Phase 2 reports: see [implementation history](../history/implementation-through-2026-10-10.md) |
| Actions | [Window evidence](phase-4-windows.md), [ACTION-001](../tasks/ACTION-001-standard-actions.md); remaining per-action checks in the [release queue](release-candidate.md). Retired Phase 4 reports: see [implementation history](../history/implementation-through-2026-10-10.md) |
| Trackpad | [Original tap](phase-5-four-finger-tap.md), [scheduling](trackpad-scheduling-timing.md), buffer/generation/focus reports and tap/editor records; INPUT-001–008 and UI-014 |
| Permissions | [Gate correction](permissions.md), [native setup/recovery](permissions-native.md); UI-001 |
| Settings and native integration | [General](general-settings-native.md), [Input/Language](input-language-native.md), [Advanced](advanced-settings-native.md), [About](about-native.md), [Mouse](mouse-native.md); corresponding UI tasks |
| Profiles/storage | [Profiles](profiles.md), [backup staging](advanced-backup-foundation.md), [protected saves/restoration](protected-saves-and-restoration.md) |
| Platform diagnostic | [AppKit sharing indicator](appkit-sharing-indicator.md); scoped root-cause evidence, no production workaround |
| Superseded visual handoffs | [Historical settings design](../history/settings-design-through-2026-10-11.md); current visuals come from DESIGN + live Sketch |

Keep dated commands, revision/environment, evidence source, meaningful result and limits. Current walkthroughs/open checks must remain discoverable from their task; an old report or successful build does not close them. Screenshots stay local under WORKFLOW. Remove a redundant report only after unique evidence/decisions and every open check are preserved and incoming links repaired.

[Pre-release copy/documentation audit](../tasks/REL-004-release-copy-and-documentation-audit.md) records the 1.0.0/2 candidate, six-language layout/site checks and remaining browser/runtime limits. [Release procedure](../RELEASING.md).
