# Touch-library and native-coexistence audit

Reviewed 2026-10-12 for [RESEARCH-001](../tasks/RESEARCH-001-touch-library-audit.md), baseline `59f5754` plus uncommitted editor work. Source audit only: no new dependency, third-party execution, input experiment, OS setting or stored rule change.

## Result

Reusable packages and permissive implementations exist for both surfaces. They can reduce acquisition/recognition work, but none reviewed establishes a maintained, complete macOS 26/Swift 6 library that safely replaces the requested Trackpad/Magic Mouse preset pool and selectively cancels every native gesture. Acquisition, recognition and cancellation are separate capabilities. This is a conclusion about the reviewed sources, not a proof of platform impossibility.

## Search and evidence

Searched Apple APIs, GitHub (multitouch, trackpad, Magic Mouse, Swift gesture recognition and cancellation) and Swift Package Index. Direct SPI Subsurface/OpenMultitouchSupport listings failed; no index build compatibility inferred. GitHub API metadata/tree, README, available manifests and complete license texts were retrieved at the pinned revisions below. Selected callback/recognizer/filter sources were read for Subsurface/OpenMultitouchSupport/MouseToucher/MagicBind/CalmMouse/Sanne and Touchy/Sleight/Toolkit/MiddleClick; macOSMiddleClick is explicitly a metadata/README-only implementation lead. No license was identified for Touchy. Public audit downloads stayed outside the repository; no code was installed, built, run or copied into Rebind. All twelve repositories were non-archived at review; commit dates show activity, not maturity or compatibility.

Public AppKit touch/responder APIs concern app-local delivery; NSEvent global monitors observe rather than cancel. An active Quartz tap can drop its actual events, but that does not establish access to or safe association with all system-recognized gestures. See [the native API review](native-gesture-suppression.md). These candidates largely use private MultitouchSupport, so a wrapper still requires ABI/lifecycle/OS gates.

## Candidate register

Tools/platform declarations below come from source manifests, not local build verification.

| Source / pinned commit date | License | Packaging / declared baseline | Source finding / decision |
| --- | --- | --- | --- |
| [Kshitij-Shringi/magicbind](https://github.com/Kshitij-Shringi/magicbind/tree/5a6731bec243d7f25a3f3d68d80b38b735cd08db) · 2026-08-17 | MIT | 5.9 / macOS 13; internal Core target, no library product | Promising separate reader/types/recognizer and Magic Mouse coexistence logic. Pre-1.0; README reports Magic Mouse/macOS 26 testing only and unmeasured thresholds. MouseButtonMonitor is listenOnly. No drop-in library or verified selective cancellation. |
| [Kyome22/OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport/tree/15c6bb0c6a2d2858559493a28ab23f7ac58648a3) · 2026-05-28 | MIT | 6.2 / macOS 15; library, binary XCF 4.0.0, AsyncAlgorithms | Default-device touch observer. No complete preset recognition or system-gesture cancellation. Trackpad candidate; no established Magic Mouse delivery. |
| [Malik1942/CalmMouse](https://github.com/Malik1942/CalmMouse/tree/ce05497fbca6cf61ed9a35157bd6281e2e112ba8) · 2026-09-22 | MIT | 5.9 / macOS 13; exported CalmMouseCore | Pure TapRecognizer/ScrollBlocker library. Private acquisition and active event tap belong to executable. Actual scroll-event drop/rewrite exists, not proof of cancelling Smart Zoom/Mission Control/Look Up. Strong narrow candidate for tap/scroll arbitration. |
| [SomeGuyNamedDaveIsTaken/macOSMiddleClick](https://github.com/SomeGuyNamedDaveIsTaken/macOSMiddleClick/tree/59abd684500621daccdc5f54bb3189cea0fde33f) · 2026-07-12 | MIT | Small C app; no SPM/Swift contract | README/tree/license/metadata reviewed; its C filtering implementation not audited in this pass. Targeted middle-click reference, not a general recognizer or verified suppression solution. |
| [anandghegde/sanne](https://github.com/anandghegde/sanne/tree/53bee5b36ebae96a8b1228221e878de7acf79149) · 2026-10-05 | MIT | 5.9 / macOS 13; internal SanneKit, no library product | Dedicated Mouse tap/swipe machines, PhysicalClickGuard/ScrollLock and device lifecycle references. Large app; callback path includes diagnostics/allocations and asynchronous output. suppressUntilLift prevents its own synthetic output; not native-gesture suppression. Existing corner adaptation remains credited. |
| [artginzburg/MiddleClick](https://github.com/artginzburg/MiddleClick/tree/566155d7e3f4f4a63d9f894ca47dc374ed070f93) · 2026-09-02 | GPL-3.0 | Xcode app; no reusable SPM product audited | Focused three-finger middle-click implementation. Native click filtering does not establish general OS-gesture cancellation. Conceptual only, no source copying. |
| [gugahoi/touchy](https://github.com/gugahoi/touchy/tree/56b0e33f67ce72940528f53989799f30bb395824) · 2026-09-15 | No license identified | 6.0 / macOS 13; executable, Swift 5 mode | Private C bridge and recognizers, advises disabling conflicting OS gestures. No license file found in tree; do not copy or adopt until permission is established. |
| [kamenlevi/Sleight](https://github.com/kamenlevi/Sleight/tree/c8485f317bd27fa86b02ff5a53314d020063c85a) · 2026-09-02 | GPL-3.0 | 5.10 / macOS 14; executable/root helper | Touch gesture app; scroll swallowing in dial mode is a narrow mechanism. Not a permissively embeddable library; no copied code/helper/security changes. |
| [meatpaste/mousetoucher](https://github.com/meatpaste/mousetoucher/tree/3f5b1a3749ba95a8abf80c5ea9a8eb355e812327) · 2026-09-08 | MIT | 5.5 / macOS 11; MouseToucherLib | Exports only TapDetector/TwoFingerTapDetector; explicitly excludes acquisition/app. App acquisition treats all non-built-in devices as Mouse, which may include external trackpads. Retained device-list lifetime and callback safety require repair before reuse. Narrow recognition reference. |
| [mhuusko5/M5MultitouchSupport](https://github.com/mhuusko5/M5MultitouchSupport/tree/f64fcccba07c484f578b1d958c309564fa8c387a) · 2015-05-08 | MIT | Objective-C/C; no SPM/modern Swift contract | Legacy observer last committed in 2015. Modern alternatives preferred; no current ABI/build evidence. |
| [mori0818/magic-mouse-toolkit](https://github.com/mori0818/magic-mouse-toolkit/tree/304e63c7a71bf139c51a6431304be91351bae7e5) · 2026-08-04 | GPL-3.0-only | macOS 26; Swift/IOKit app, no root SPM manifest | Touch remapper with MIT/GPL provenance notices. Safety note warns about input freeze after permission revocation. Conceptual only; independently inspect original MIT MouseToucher rather than GPL derivatives. |
| [mrkai77/Subsurface](https://github.com/mrkai77/Subsurface/tree/88eb16b0a6f7a44a898cecff9e283298aa413936) · 2026-09-30 | Apache-2.0 | 6.2 / macOS 13; library, Scribe branch dependency | Raw contacts/devices and swipe/magnify/rotation recognizers. Already pinned in standalone TrackpadProbe, not the app. Public contactFrames buffers newest 1; internal synchronous handler is not a public adapter API. Candidate acquisition experiment, not a tap/drop-in engine. |

## What the source actually does

- Subsurface `SubsurfaceDevice.contactFrames()` keeps only the newest frame. Dropping a zero-contact edge can invalidate tap sequencing; reuse must preserve ordered bounded delivery and explicit loss cancellation. Its internal synchronous handler is not exposed as a general public acquisition adapter. Existing probe pins this same revision; probe success is separate from app safety.
- OpenMultitouchSupport listeners invoke observation callbacks and the manager uses a default device. Its binary package and stream do not provide tap/click exclusion, double-tap arbitration or cancellation of native gestures.
- MagicBind retains the created device list and separates reading/types/recognition. Its engine classifies under a lock in the touch callback and queues dispatch to main; configuration reads and per-device recognizer creation are unsuitable to copy into Rebind's bounded callback without adaptation. Its mouse monitor explicitly uses `.listenOnly`. README's coexistence claim is credible as intent, not replacement/suppression evidence.
- MouseToucher exports only pure detectors. Its acquisition example identifies non-built-in devices as Magic Mouse and lets the created list leave local scope while keeping raw references; neither category classification nor lifetime is sufficient for our production adapter.
- CalmMouse `EventTap.handleScroll` returns nil for a drop and rewrites deltas for another decision; `ScrollBlocker` tracks phase/momentum/button grace. This is genuine limited Quartz filtering. It is outside the exported pure Core and does not show cancellation of native Smart Zoom/Mission Control. Do not import its physical sender attribution into the withdrawn Rebind routing scope.
- Sanne `session.suppressUntilLift` exits its own recognition and rejects synthetic clicks after scroll/physical click. The name does not mean it cancels macOS recognition. Its bounded pure machines/guard are the useful reuse unit, not the whole app.

Full MIT/Apache notices and any attribution must accompany actual reuse; current bundled notices are unchanged because this pass adds no source/dependency. GPL implementations remain conceptual references pending an explicit licensing decision.

## Candidate first pool and native reservations

Apple's [current gesture guide](https://support.apple.com/en-us/102482) lists Trackpad three-finger Look Up, two-finger Smart Zoom/secondary click/scroll/navigation, three/four-finger navigation variants, and Magic Mouse one-finger Smart Zoom/scroll/page swipes plus two-finger Mission Control/Space swipes. Accessibility [three-finger double-tap Zoom](https://support.apple.com/guide/mac-help/mchl779716b8/mac) is another reservation. Settings, app-specific gestures, drag options and hardware behavior still matter.

| Surface / preset | Initial assessment | Required evidence before exposing as conflict-free |
| --- | --- | --- |
| Trackpad stationary four-finger single/double tap | Best initial candidate: absent from Apple's listed stationary system presets; existing engine and limited four-finger delivery evidence available. | No swipe/drag/click/zoom side effects under supported settings; single/double arbitration, cancellation, latency and external Trackpad separately. |
| Trackpad three-finger single/double tap | Conflicts with Look Up and optional Zoom; double can also produce single-stage native effects. | Explicit configuration guidance plus physical coexistence; do not claim replacement without proven filtering. |
| Trackpad two-finger double/click | Smart Zoom / secondary click reservations. | Native conflict resolution before advertising clean remapping. |
| Trackpad corners / multi-contact physical clicks | A corner tap can still be an ordinary tap-to-click; physical clicks already have an OS action. | Correct down/up ownership and actual source-event suppression/click separation. Not automatically free gestures. |
| Magic Mouse stationary one/two-finger single tap | Possible candidates, not listed as standalone OS actions; double-tap/system timing and finger-rest/pointer/scroll ambiguity remain. | Real-device acquisition, false positives, physical-click exclusion, native doubles and scroll coexistence. |
| Magic Mouse stationary three/four-finger tap | Additional source-supported candidates in MagicBind; not in Apple's standard guide. | Real mouse model contact capacity/ABI and ergonomics; never infer support from Trackpad. |
| Magic Mouse one/two-finger double tap or ordinary swipe | Smart Zoom, Mission Control, page/Space navigation reservations. | Leave out of a proposed conflict-free initial pool unless a narrow cancellation route is demonstrated. |

Absence from Apple's list is candidate evidence, not a guarantee. This table proposes an implementation order; existing saved rules, four current Trackpad choices and final SPEC remain intact. The user's conditional smaller initial pool does not silently authorize deleting rules or reducing release requirements.

## Recommended next experiment

1. Retain the working Trackpad adapter/sequencer while comparing a pinned Subsurface acquisition route in the standalone probe. Measure zero-contact delivery/loss, click separation, stop/wake/recovery and named macOS 26 hardware; do not replace the app path merely to gain a wrapper.
2. For Magic Mouse, first evaluate the MIT MagicBind reader/types and CalmMouseCore tap/scroll arbitration, with MouseToucher/Sanne pure machines as narrower alternatives. Build only an explicitly reviewed isolated adapter; retain category-wide rules, no device picker/automatic activation and no engine integration yet.
3. Implement a small verified pool, beginning with stationary taps, only after device/coexistence tests. Reject an adapter if it needs callback Task/actor hops, UI/logging/output work, unbounded queues, silent edge loss, weak ownership, privileged helpers or OS settings mutation. Preserve paired click ownership, passthrough, tags, pause/protected contexts and disconnect recovery.

The reusable-source decision is ready; actual package compatibility, Magic Mouse support and gesture suppression remain research/hardware gates. No capability was promoted by this audit.
