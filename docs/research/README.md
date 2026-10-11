# Rebind — current mechanism and dependency decisions

Updated 2026-10-11: native Advanced transaction decision added after the [renewed tap-library audit](trackpad-tap-reliability.md). No new hardware experiment or app dependency. Check dates/revisions when changing a mechanism. [Dependency/reference register](DEPENDENCIES.md) retains licenses, pinned sources, maintenance and prior decisions. [Historical research](../history/implementation-through-2026-10-10.md#research-findings--blockers) retains reasoning and superseded approaches.

## Current adoption and boundaries

| Area | Current decision / evidence | Next uncertainty |
| --- | --- | --- |
| Capture/matching/output | Public active session Quartz tap on owned CF run loop; bounded matching/mailbox, tagged output, separate action worker. Native-first, no app Swift packages. | Real callback/action profiling, broader modifier/safety/hardware gates |
| Permissions | Current tap requires actual Accessibility + event-posting preflight; separate Input Monitoring is not its startup gate. Explicit request/settings routes. [Permission evidence](../verification/permissions.md). | Stable signing/TCC persistence, revocation and onboarding runtime |
| Device scope | User withdrew physical-device inventory/source attribution on 2026-10-08; category-wide input and manual profiles retained. Removed private sender probe stays removed. | Revisit only on a new explicit product request |
| Trackpad app adapter | Isolated private native adapter informed by pinned Subsurface ABI; bounded callback handoff/process-lifetime ownership and macOS major 26/27 availability gate. No app package. [Contract](../verification/phase-5-four-finger-tap.md). | Actual usability/click separation/teardown/recovery, macOS 26/Intel; no suppression claim |
| Trackpad recognizers | Narrow four-finger integrated path; Sanne MIT corner adaptation credited, broader pure tap sequence remains unwired. Original 500 ms settling notes are superseded by source's 60 ms guard and responsiveness/idle-gap fixes. | [INPUT-001](../tasks/INPUT-001-four-finger-tap.md); rest of compact scope |
| Standalone probe | `tools/TrackpadProbe` has pinned Subsurface/Scribe/SwiftSyntax dependencies separately; not bundled in Rebind.app. | Probe success does not prove app runtime/suppression |
| Tap/click alternatives | Sanne/other open implementations and commercial BTT/WheelClick are real research leads; no fully suitable embeddable component established. GPL references not copied. | Review relevant reuse/public-API lead before broader custom recognition |
| Actions | Core Audio, AppKit/NSWorkspace, public AX, IOKit sleep, public media/Quartz HID outputs. Shared catalog only advertises available implementations. | Target/device/permission/error/cancellation/latency checks per action |
| Mission Control / lock | Isolated dynamic private Dock notifications/login-framework entry point; explicitly Experimental. | Platform/version compatibility and effect/lifecycle acceptance |
| Spaces | Standard enabled Ctrl+arrow pair, secondary-Fn/HID posting, read-only settings validation. Failed session posting and instant Dock swipe were replaced. | Display/Reduce Motion/held modifiers/edges/latency/safety checks; no settings mutation |
| Icons/UI | SF Symbols primary UI set; native Icon Composer app icon; named vector Menu Bar template. Optional icon packages were researched, not adopted. | Current Sketch implementation/runtime/accessibility acceptance |
| Advanced backup/transactions | Native fileImporter/NSSavePanel/NSAlert, existing validated codec and Foundation atomic writes/raw-copy replacement; Swift Configuration evaluated, not adopted. [Decision](DEPENDENCIES.md#advanced-configuration-transactions--2026-10-11) | SPEC §15.12 restored-binding runtime and full accessibility acceptance |

## Current research risks

- **R-01 trackpad:** raw contacts do not establish tap/click exclusivity, source attribution or suppression. Integrated output exists but responsiveness/recovery acceptance remains open.
- **R-02 routing:** closed by explicit scope withdrawal; historical Unknown sender is not universal proof of platform impossibility.
- **R-03 mouse drivers:** numeric button model exists and G603 subsets work; buttons beyond 5, driver changes and detailed passthrough need hardware evidence.
- **R-04 Magic Mouse:** separate research/hardware gate; no current touch support claim.
- **R-05 actions:** many paths implemented with subset user confirmation; operation acceptance/posting does not prove visual completion and every platform combination.
- **R-06 signing/permissions:** local ad-hoc builds previously verified; stable identity, revoked grants and distribution need further evidence/credentials. No root/security shortcuts.

## Recording a new decision

Use the affected task for a small decision. A broad/new mechanism can have a focused research file. Record problem/requirements, source URLs/revisions, license/maintenance/platform limits, alternatives (including native APIs), chosen mechanism, callback/security ownership and what was actually tested. Explicitly supersede the previous decision; do not leave contradictory records both labeled current.

Update DEPENDENCIES when adding/removing/reusing third-party code or changing its audit. Actual bundled [notices](../../rebind/Resources/ThirdPartyNotices.txt), probe manifest/lockfile and installed `.agents/skills/manifest.json` are the artifacts to inspect. Historical skill checksums and removed validator commands remain historical; no per-file skill validator is required.
