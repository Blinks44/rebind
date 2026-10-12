# Liquid Glass controls and design-transfer research

Reviewed 2026-10-12 for [UI-016](../tasks/UI-016-editor-design-adoption.md). Scope: macOS 26+ SwiftUI capsules, secondary actions and inactive-window fidelity to the live Sketch source. No package, shader or third-party source was installed/copied/executed. No minimum-OS or project identity change.

## Available implementations

GitHub metadata, manifests, README, available full licenses and Swift Sources were read at the revisions below, except `temoki/lq`, where review covered metadata/tree/README/license only. All seven were non-archived at review. Dates describe the inspected commits, not verified support. Swift Package Index discovery found SwiftGlass, but direct listing retrieval failed; no SPI build compatibility is claimed. None was locally compiled.

| Candidate and pinned source | Manifest / license / date | Fit and decision |
| --- | --- | --- |
| [metneo/LiquidGlass](https://github.com/metneo/LiquidGlass/tree/36f81c85922aa3475b7e5bb210e69ffe20a2b377) | Swift tools 6.3, macOS 12; MIT; 2026-09-14 | Native 26 branch wraps system glass. Older-platform opacity/light controls do not expose Sketch's renderer settings on 26. No useful inactive-window override found. Reference only. |
| [rguillen-dev/LiquidGlass](https://github.com/rguillen-dev/LiquidGlass/tree/4b5519f647dc384874fbf4ef70a9a60c4352dc2e) | Tools 6.0, macOS 14/iOS 17; MIT; 2026-09-19 | Despite iOS-focused README, manifest includes macOS. Native path uses regular/tinted system glass; custom controls do not solve the missing optical settings. Reference only. |
| [1998code/SwiftGlass](https://github.com/1998code/SwiftGlass/tree/0572ed387525f3189a89838641a98a9b722596f9) | Tools 5.9, macOS 14; MIT; 2026-05-03 | Configurable frost/gradient edges. Capsule/circle paths use the fallback material rather than native 26 optics. A valid stylized-material candidate, but adopting its general abstraction would not resolve the source's precise control/state contract. Reference only. |
| [BarredEwe/LiquidGlass](https://github.com/BarredEwe/LiquidGlass/tree/81d921841b517c189dd63d6f9f455ef5f4318062) | Tools 6.0, iOS 14; no identified license; 2025-12-21 | UIKit hierarchy capture/Metal, unguarded UIKit dependencies. Does not fit native macOS. Do not adopt. |
| [anuero/LiquidGlass](https://github.com/anuero/LiquidGlass/tree/892f75fbee0bc48de015d3736f22be7217691bee) | Tools 5.9, iOS 15; MIT; 2026-08-01 | UIKit snapshot/CADisplayLink/Metal implementation, not a macOS control package. Do not adopt. |
| [KKarsyline/liquid-glass](https://github.com/KKarsyline/liquid-glass/tree/a1424c7522e06c96854d9c70be57535c8246670d) | Tools 6.2, macOS 26; no identified license; 2026-06-17 | Circle-lens library/demo with sampled background and precompiled Metal resource. Not a general native-control kit. Do not adopt without resolving licensing and a concrete optical need. |
| [temoki/lq](https://github.com/temoki/lq/tree/a2a100b152469c481dbd7b6eae1d4bb12525b7bf) | No root SPM manifest; MIT; 2025-07-05 | Shader demo with upstream-port provenance. Not a reviewed reusable desktop control package; backend/platform behavior not audited. Do not adopt for this task. |

## Native renderer and implementation decision

The public macOS 26 [Glass API](https://developer.apple.com/documentation/swiftui/glass) exposes material, tint, shape and interactivity. It does not expose Sketch's custom blur radius, depth, distortion or specular-highlight switch. Public [`appearsActive`](https://developer.apple.com/documentation/swiftui/environmentvalues/appearsactive) affects descendant appearance, not actual keyboard ownership; live review showed it alone does not freeze the native glass fill. The user's later clarification explicitly accepts native active/inactive color variation; final production code does not force active appearance. Do not use private window state or disable keyboard focus to hide a rendering difference.

Keep native glass for the shared selector/selection-track family and preserve accessible opaque fallbacks. Secondary content-card buttons use a small native `ButtonStyle` with the authored accent wash and quiet inner lighting: Sketch explicitly disables specular highlights there, and the default glass button produced an extra grey rim. This style is **not claimed to reproduce the Sketch glass shader**. No broad shader renderer is justified by that subtle flat-background detail. Source typography, geometry, fills and semantics remain directly portable; changing optics requires an actual rendered comparison.

## Skill discovery and transfer practices

The user-supplied [Swift Agent Skills directory](https://github.com/twostraws/swift-agent-skills) was inspected. Existing project skills already cover SwiftUI composition/review, UI patterns/previews, Liquid Glass and macOS accessibility. Apply them with ENGINEERING's macOS overrides, not upstream iOS defaults.

Additional candidates inspected: [Figma to SwiftUI](https://github.com/daetojemax/figma-to-swiftui-skill) README and entrypoint; [Swift FocusEngine Pro](https://github.com/mhaviv/Swift-FocusEngine-Agent-Skill) README and entrypoint; Swift Architecture repository overview. Figma skill is tied to Figma/iOS and its fetched entrypoint postpones validation unless requested, conflicting with this project's routine rendered checks. No full license was identified there. FocusEngine advertises MIT and macOS-specific references, but the macOS reference retrieval failed; it is a possible later focus-audit addition, not a fully reviewed installation. Architecture entrypoint retrieval returned 404. No additional skill was installed or partially trusted.

The immediate fix is an executable component system: adaptive assets, shared logical-point typography/metrics, reusable native controls and deterministic UI-only specimens, followed by rendered comparison and behavior/layout checks. [ENGINEERING](../ENGINEERING.md#translating-the-live-design-into-swiftui) records this development practice. Sketch remains the live source rather than duplicating its entire component inventory in Markdown.

Next: verify the final scoped editor/Settings materials on macOS 26 and with adaptive preferences/VoiceOver. Re-evaluate a package when it provides a needed public capability rather than the same system wrapper.
