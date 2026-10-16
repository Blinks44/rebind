# Rebind: current mechanism and dependency decisions

Current decisions reconciled 2026-10-16 against source and task records; no new mechanism experiment was performed by the documentation cleanup. The [touch-library audit](touch-library-audit.md) is a dated candidate review, not a current implementation inventory. Check dates/revisions when changing a mechanism. [Dependency/reference register](DEPENDENCIES.md) retains licenses, pinned sources, maintenance and prior decisions. [Historical research](../history/implementation-through-2026-10-10.md#research-findings--blockers) retains reasoning and superseded approaches.

## Current adoption and boundaries

| Area | Current decision / evidence | Next uncertainty |
| --- | --- | --- |
| Capture/matching/output | Public active session Quartz tap on owned CF run loop; bounded matching/mailbox, tagged output, separate action worker. Native-first; Logitech HID++ uses the local MIT HIDPP package, separate from capture. | Real callback/action profiling, broader modifier/safety/hardware gates |
| Permissions | Current tap requires actual Accessibility + event-posting preflight; separate Input Monitoring is not its startup gate. Explicit request/settings routes. [Permission evidence](../verification/permissions.md). | Stable signing/TCC persistence, revocation and onboarding runtime |
| Device scope | Rules are category-wide and profiles manual. Settings → Devices has physical inventory and mouse-specific settings; wheel sender attribution serves per-mouse smooth scrolling. [DEVICE-001](../tasks/DEVICE-001-mouse-devices.md), [INPUT-011](../tasks/INPUT-011-apps-mice-gesture-button.md). Removed private rule-sender probe stays removed. | Multi-device/reconnect and companion-driver acceptance; no physical-device rule routing |
| Trackpad app adapter | Isolated private observer, bounded callback handoff/process-lifetime ownership and macOS major 26/27 gate. No app package. [Contract](../verification/phase-5-four-finger-tap.md), [suppression feasibility refresh](native-gesture-suppression.md). | Actual timing/recovery and macOS 26/Intel; click/corner replacement has separate filters, while general native gesture cancellation is not established |
| Trackpad recognizers | Twelve complete tap/double-tap/corner/physical-click presets, built-in and external categories, shared actions and one optional held modifier. Existing bounded acquisition/recognition; Sanne MIT adaptation credited. [Current requirements](../SPEC.md#34-built-in-trackpad-and-magic-trackpad-research-gated), [evidence](../CAPABILITIES.md). | Physical accuracy/timing, coexistence, external hardware and safety; raw contacts alone prove none of them |
| Standalone probe | `tools/TrackpadProbe` (pinned Subsurface/Scribe/SwiftSyntax, never bundled) was removed on 2026-10-13 after integration; see Git history. `apps/rebind/tools/magic-mouse-probe.swift` has no dependencies. | Probe success does not prove app runtime/suppression |
| Tap/click alternatives | [Current source audit](touch-library-audit.md): Subsurface/OpenMultitouchSupport acquisition, MagicBind MIT reader and CalmMouseCore pure tap/scroll logic are bounded candidates; no complete selective native-gesture cancellation established. No new dependency/source reuse. | Compare isolated acquisition/coexistence on named hardware before integration |
| Actions | Core Audio, AppKit/NSWorkspace, public AX, IOKit sleep, public media/Quartz HID outputs. Shared catalog only advertises available implementations. | Target/device/permission/error/cancellation/latency checks per action |
| Mission Control / lock | Isolated dynamic private Dock notifications/login-framework entry point; explicitly Experimental. | Platform/version compatibility and effect/lifecycle acceptance |
| Spaces | Standard enabled Ctrl+arrow pair, secondary-Fn/HID posting, read-only settings validation. Failed session posting and instant Dock swipe were replaced. | Display/Reduce Motion/held modifiers/edges/latency/safety checks; no settings mutation |
| Icons/UI | SF Symbols primary UI set; native Icon Composer app icon; named vector Menu Bar template. Optional icon packages were researched, not adopted. | Current Sketch implementation/runtime/accessibility acceptance |
| Advanced backup/transactions | Native fileImporter/NSSavePanel/NSAlert, existing validated codec and Foundation atomic writes/raw-copy replacement; Swift Configuration evaluated, not adopted. [Decision](DEPENDENCIES.md#advanced-configuration-transactions-2026-10-11) | SPEC §15.12 restored-binding runtime and full accessibility acceptance |

## Current research risks

- **R-01 trackpad:** raw contacts do not establish tap/click exclusivity, source attribution or suppression. Integrated output exists but responsiveness/recovery acceptance remains open.
- **R-02 rule routing:** physical-device rules remain outside scope; Settings inventory/mouse attribution is separate. Historical Unknown sender is not proof of platform impossibility.
- **R-03 mouse drivers:** numeric button model exists and G603 subsets work; buttons beyond 5, driver changes and detailed passthrough need hardware evidence.
- **R-04 Magic Mouse:** separate research/hardware gate; no current touch support claim.
- **R-05 actions:** many paths implemented with subset user confirmation; operation acceptance/posting does not prove visual completion and every platform combination.
- **R-06 signing/permissions:** local ad-hoc builds previously verified; stable identity, revoked grants and distribution need further evidence/credentials. No root/security shortcuts.

## Recording a new decision

Use the affected task for a small decision. A broad/new mechanism can have a focused research file. Record problem/requirements, source URLs/revisions, license/maintenance/platform limits, alternatives (including native APIs), chosen mechanism, callback/security ownership and what was actually tested. Explicitly supersede the previous decision; do not leave contradictory records both labeled current.

Update DEPENDENCIES when adding/removing/reusing third-party code or changing its audit. Inspect bundled [notices](../../apps/rebind/rebind/Resources/ThirdPartyNotices.txt), actual package references/lockfiles and installed `.agents/skills/manifest.json`; the removed standalone probe manifest is historical. Historical skill checksums and removed validator commands remain historical; no per-file skill validator is required.

2026-10-16: [Multi-vendor battery audit](multi-vendor-batteries.md) selects native IOKit/CoreBluetooth plus small MIT Razer/SteelMouse read-only source adaptations; no extra package/runtime/driver. Exact hardware/transport acceptance remains in DEVICE-003.

2026-10-16: [Production review](../tasks/REVIEW-001-production-review.md) refreshed Apple menu APIs and Logitech/Solaar/Linux protocol comparisons. Local HIDPP ADC flags/SET acknowledgement and short-report receiver notification classification corrected; the additional review checked the latter against Linux HID++. No GPL code copied or dependency added. Standard NSMenuItem image + attributed title/attachment can represent the battery row; the compiled prototype's interactive visual check is blocked by ScreenCaptureKit -3811, and native menu integration remains open.
