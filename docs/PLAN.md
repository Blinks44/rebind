# Rebind - Development Plan and Verification Log

**Plan status:** Repository preparation verified; Phase 1 implementation has not started. Phase 0 hardware feasibility work remains open.
**Last reviewed:** 2026-10-08 (repository, toolchain, builds, test infrastructure, skills, and upstream research).
**Owner:** Coding agent, with user decisions on major architecture or license trade-offs.  
**Product requirements:** `SPEC.md`  
**Engineering rules:** `../AGENTS.md`

## How to use this file

- Work in **thin, verifiable vertical slices**. Do not build months of UI ahead of the functional input engine.
- Before changing a box to `[x]`, record concrete evidence: files changed, build/test commands and results, actual macOS/device test when needed. `[x]` means the stated acceptance criteria are met, not merely attempted.
- `Implemented` does not equal `Verified`. Hardware-dependent features remain unverified without physical testing. Use the capability status vocabulary in `SPEC.md` §13.
- If an OS limitation prevents a task, note reproduction steps, research sources, workaround options, and product/UI implications under **Research findings / blockers**.
- Keep all phase names, outcomes, and next actions up to date for a new agent session. Add concise entries to **Session log** after substantive changes.
- Preparation checks below have concrete evidence in the session log. Product and hardware checks remain open until independently verified.

## Development preparation — completed 2026-10-08

Scope: Phase 0; `SPEC.md` §§6–7, 10–12, 14. This session configures development only. None of K1/K2, M1/M2, D1/D2, T1/T2, G1/G2, R1, A1/A2, or S1/S2/S3 has passed a Rebind implementation test.

- [x] Inventory existing SwiftUI application, project/workspace, assets, Git, documentation and both references.
- [x] Verify installed full Xcode, compiler, SDK, SwiftPM, and local build destination.
- [x] Configure macOS 26.0 minimum, Swift 6 mode/complete concurrency checking, and Rebind display identity.
- [x] Disable application sandbox for intended interception/actions; retain build-script sandboxing and enable Hardened Runtime.
- [x] Preserve `blinks44.rebind` and automatic signing; verify local ad-hoc build/launch without inventing credentials.
- [x] Add hosted `rebindTests` target and shared `rebind` scheme; compile Swift Testing and app-module imports; execute empty runner successfully.
- [x] Review and install four revision-pinned project skills with licenses and checksums; verify actual files and Git visibility.
- [x] Extend `.gitignore`; verify no user-specific Xcode files are tracked, and all existing requirements/references are tracked.
- [x] Research native APIs and runtime candidates; add no speculative runtime packages.
- [x] Add reproducible `scripts/dev.sh` commands and developer `README.md`; verify Debug/Release builds, test build/run, package resolution and app launch.

### Configuration decisions

- Original project is a small Xcode 27 starter: target `rebind`, `ContentView.swift`, `rebindApp.swift`, synchronized source group, empty icon slots, no entitlements file, no packages, no test target/shared scheme. Existing source files are unchanged. Preserve project format/object version and source directories.
- Host: macOS **27.0.1 (26A434)**, Apple Silicon. Full Xcode **27.0 (27A266a)**, Apple Swift **6.4 (swiftlang-6.4.0.34.1)**, SDK **27.0 (26A425)**; `swift package --version` reports **Swift Package Manager – Swift 6.4.0-dev**. These are installed-toolchain facts, not a promise of macOS 26 runtime verification.
- `xcode-select -p` points to `/Library/Developer/CommandLineTools`; bare `xcodebuild` fails. `scripts/dev.sh` respects explicit `DEVELOPER_DIR`/valid system selection, otherwise uses installed full Xcode per process. No system-wide selection or security changes.
- Both app configurations use `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`, deployment **26.0** instead of 27.0. Preserve approachable concurrency, member-import visibility, and **MainActor default isolation**. Future synchronous C/CF tap types must explicitly use appropriate `nonisolated` boundaries. Test target has no MainActor default, so isolated app code requires explicit actor-aware tests.
- Product/display name **Rebind**, Swift module **rebind**, target/scheme/project **rebind**. Bundle ID **blinks44.rebind** remains unchanged. Test bundle **blinks44.rebind.tests** depends on and is hosted by the actual app; no test framework package is necessary.
- `ENABLE_APP_SANDBOX = NO`: `SPEC.md` requires filtering/synthesis and cross-app AX operations; Apple documents restrictions on assistive Accessibility and related operations in [App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox). Outside-Mac-App-Store distribution accepts the loss of app-container isolation; future code must minimize local access and permissions. Remove unused sandbox file-access and app-group-registration settings. No Full Disk Access, root, SIP changes, or new capabilities.
- `ENABLE_HARDENED_RUNTIME = YES`; keep `ENABLE_USER_SCRIPT_SANDBOXING = YES`. Release sets `CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO` because observed Xcode defaults otherwise injected `get-task-allow`. Final Release signature has `runtime` flag and **no entitlements**. Debug retains Xcode debugger/testing grants; Xcode disables its hardened runtime during ad-hoc debugging/testing. No manually authored entitlement file.
- No existing development team; `security find-identity -v -p codesigning` found zero usable identities. Automatic **Sign to Run Locally** uses ad-hoc signing successfully. Stable Apple Development identity is recommended before TCC/hardware work; Developer ID/notarization remains a credentials-dependent distribution task. Keep bundle ID and launch path stable; do not create certificates, reset TCC, or grant permissions as preparation.
- `rebindTests/TestSupport.swift` only imports `Testing` and `@testable import rebind`; **zero tests** is deliberate. Meaningful tests start with Phase 1. Shared scheme supports Build, Run, Test, Profile, Analyze, and Archive.
- `.gitignore` keeps `Package.resolved`, shared schemes, `.agents/skills`, docs, and references visible; ignores macOS metadata, IDE user data, DerivedData/build/SwiftPM caches, and result/archive/symbol bundles. The previously tracked scheme-management user file was already removed by the user by the final inventory; local user data remains on disk. No Git index changes, commits, pushes, remotes, hooks, or identity configuration added. Existing docs/references became tracked during this session through user activity and were preserved.
- Both references inspected: `design.png` shows the intended pane hierarchy; `interface.png` shows a macOS VM interface/material direction. References do not expand product scope to Touch Bar/Siri Remote or prove input-device availability. Icon design, real UI, and localization remain roadmap work.

### Agent skills: installation and review

Installed using the **bundled Codex skill-installer**, `--dest <repo>/.agents/skills --ref <reviewed SHA> --method download`. Public source/metadata was downloaded to `/tmp` for review; no upstream installer/script was executed. Codex's supported project location is [`.agents/skills`](https://learn.chatgpt.com/docs/build-skills). Newly installed skills are available on the next turn; `AGENTS.md` also lists exact paths. Automatic future-session UI enumeration itself was not restarted/tested.

| Installed skill | Source / reviewed revision | Maintenance evidence | Use and compatibility |
|---|---|---|---|
| SwiftUI Pro | [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill), `f9800713b24580bc444931949aad4519128605e8` | Commit 2026-10-07; not archived; MIT | Agent Skills/Codex metadata; SwiftUI, localization, performance and accessibility references. Upstream includes iOS 27/iPhone assumptions and newer Xcode claims: use only macOS advice valid for installed SDK and macOS 26 minimum. |
| Swift Concurrency Pro | [twostraws/Swift-Concurrency-Agent-Skill](https://github.com/twostraws/Swift-Concurrency-Agent-Skill), `bee3f69ba17142da148d3c5406f148ed62592b69` | Commit 2026-05-17; not archived; MIT | Swift 6.2+; actor/default-isolation diagnostics, streams/cancellation and callback interop. Synchronous tap contracts override generic async recommendations. |
| Swift Testing Pro | [twostraws/Swift-Testing-Agent-Skill](https://github.com/twostraws/Swift-Testing-Agent-Skill), `2d6bba14a3c8bf3694f218b92fffe617c41ae43e` | Commit 2026-05-17; not archived; MIT | Swift 6.2+; behavioral/parameterized/async tests and migrations. XCTest remains required for future UI tests. |
| AppKit Accessibility Auditor | [rgmez/apple-accessibility-skills](https://github.com/rgmez/apple-accessibility-skills), `64e5848d371b7774a4c27ffd430c02121d03e371` | v1.5.0 commit 2026-10-05; not archived; MIT | Self-contained macOS/Codex-compatible UI audit and `checklist.md`; adds AppKit key-view-loop/NSAccessibility guidance. Distinct from AX client permission handling. |

Reviewed SKILL.md instructions, supporting file inventory, applicable reference content, OpenAI metadata, licensing and maintenance. Normalization: retain the upstream top-level skill/reference/asset/agent files unchanged, add each repository's MIT LICENSE, exclude `.claude-plugin/` and nested duplicate `skills/` plugin packaging (ZIP extraction flattens its reference symlinks). No nested entry points or executable scripts remain. **47 installed files** verified against upstream and recorded in `.agents/skills/manifest.json` with SHA-256 hashes. Manifest is an additional file. All entry-point names/descriptions, referenced files, license presence, file hashes, and Git visibility checked.

Other candidates reviewed from the [Swift Agent Skills index](https://github.com/twostraws/swift-agent-skills) and independent GitHub searches:

| Candidate | Evidence / license / compatibility | Decision |
|---|---|---|
| [markmals/mac-dev-skills](https://github.com/markmals/mac-dev-skills) | Commit 2026-09-28, MIT, active; inspected AppKit Design instructions; requires separate `sdk-search`/`sdk-api` tooling and broader plugin workflow | Defer: useful AppKit specialization, but mandatory external tooling and architecture opinions are unnecessary for SwiftUI-first preparation. Do not install whole plugin. |
| [PasqualeVittoriosi/swift-accessibility-skill](https://github.com/PasqualeVittoriosi/swift-accessibility-skill) | Commit 2026-03-09, MIT, Agent Skills; inspected instructions/references inventory; mixed AppKit/UIKit/SwiftUI and App Store labeling guidance | Defer: chosen focused AppKit auditor plus SwiftUI Pro cover needed UI work with less iOS-specific overlap. |
| [rgmez SwiftUI Accessibility Auditor](https://github.com/rgmez/apple-accessibility-skills/tree/main/skills/swiftui-accessibility-auditor) | Same 2026-10-05 MIT release; Codex-compatible; inspected instructions | Defer: overlaps SwiftUI Pro; revisit for a dedicated UI accessibility pass. |
| [ivan-magda/swift-security-skill](https://github.com/ivan-magda/swift-security-skill) | Commit 2026-06-17, MIT, Agent Skills; inspected instructions; specializes in Keychain, biometric auth, credentials, crypto and OWASP | Defer: no account/secrets/network auth in Rebind; does not solve input privacy/TCC safety. |
| [Dimillian/Skills: SwiftUI Performance Audit](https://github.com/Dimillian/Skills/tree/main/swiftui-performance-audit) | Commit 2026-03-29, MIT, Codex skills; inspected code-review/Instruments workflow | Defer: useful when a measured UI problem exists; SwiftUI Pro has routine performance guidance. Input-path performance needs native profiling, separate from SwiftUI rendering. |
| [Dimillian/Skills: macOS SPM app packaging](https://github.com/Dimillian/Skills/tree/main/macos-spm-app-packaging) | Same commit/license; inspected bootstrap/release instructions and templates inventory | Defer: would replace the existing Xcode app with an SPM scaffold and introduce unnecessary packaging/signing/update scripts. Native Xcode already resolves SPM libraries. |
| [fayazara/macos-app-skills](https://github.com/fayazara/macos-app-skills) | Commit 2026-05-27; inspected build instructions and repository contents; no root license found / GitHub license null | Do not install: reuse license unclear; build guidance also filters output without preserving command failure status. |

No additional linting/formatting frameworks, XcodeGen, Node/Homebrew toolchains, external CI service, or runtime library is needed for current preparation. Re-evaluate with evidence at the relevant milestone.

## Milestones

### Phase 0 - Repository inventory, feasibility and dependency audit

**Goal:** avoid architecture mistakes before writing low-level interception code; immediately move toward a working prototype when feasibility is clear.

- [x] Inspect project target(s), source layout, bundle ID, entitlements, sandbox setting, build scheme, current macOS deployment target, Swift language mode, tests, and existing work. **Preserve the existing project.**
- [x] Confirm toolchain availability (Xcode / `xcodebuild`, build destination, Swift version). Document exact command to build the app.
- [x] Read relevant Apple docs for `CGEventTap`, event types, synthesis, IOKit/HID, Accessibility, secure input, permission prompts, background app lifecycle, and `SMAppService`.
- [ ] Confirm which combinations allow interception plus suppression, which permit observation only, and which are blocked by the OS.
- [ ] Investigate mapping per-event → physical HID device; **test two-mouse attribution before promising per-device rules**.
- [ ] Investigate normal and extra buttons beyond #5, including differing HID/CGEvent numbering, firmware/driver overrides, and limits.
- [ ] Investigate real trackpad four-finger tap capture, native gesture conflicts, and suppression feasibility.
- [ ] Investigate Magic Mouse contact capture separately from trackpad. Do not assume one library covers both.
- [x] Compare reusable packages/references with license, Swift/macOS compatibility, sandbox requirements and maintenance status. Review code/skill content before installing.
- [ ] Decide smallest architecture and confirm which feature claims are `Core`, `Experimental`, `Blocked`, or `Later`.
- [ ] Record design decisions and risk matrix below; update this plan if a genuine platform constraint is discovered.

**Exit evidence:** written findings plus working build command, justified capture approach, explicit multitouch/device-identification risks. Start Phase 1 directly when enough is understood; avoid endless research with no tested prototype.

### Phase 1 - Smallest working global remapping slice

**Goal:** prove the app can recognize, match, suppress when allowed, and dispatch an action in a separate foreground app.

- [ ] Define stable `Binding`, `DeviceScope`, `InputTrigger`, `ModifierSet`, `RebindAction`, and useful diagnostics types (`Codable`, testable).
- [ ] Implement deterministic matching for one physical keyboard trigger and for a normal extra mouse button plus exact modifiers.
- [ ] Create a real global input capture path (likely Quartz event tap for supported events) without UI dependency.
- [ ] Separate the real-time tap callback from action execution; ensure passthrough for unmatched events.
- [ ] Implement synthesized shortcut sending with correct down/up lifecycle and protection against recursive processing.
- [ ] Add a minimal real interface to display/edit at least one rule and show whether the engine is active; no decorative mock UI.
- [ ] Add global Pause/Resume, safe release of synthetic states, and a clearly accessible quit path.
- [ ] Unit test exact modifiers, match/nomatch, conflict, and synthetic-event feedback.
- [ ] Build on the available macOS toolchain and **manually test** at least one configured keyboard → shortcut mapping and `Control + Mouse Button 4` mapping if a suitable mouse is attached.

**Exit evidence:** at least one end-to-end remap actually works outside Rebind; if hardware is unavailable, record unverified items explicitly. Do not claim the app is functionally complete at this phase.

### Phase 2 - Robust keyboard and mouse engine

**Goal:** production-quality core capture and matching, not just a proof-of-concept.

- [ ] Correct modifier transitions, left/right where detectable, key up/down, key repeat, rapid holds and releases.
- [ ] Add double press/hold semantics and state machines; special-key research for `Caps Lock`, `Fn/Globe` and protected contexts.
- [ ] Correctly handle many mouse button identifiers without fixed max enum; implement normal button, hold, double click and optional mouse-button combinations.
- [ ] Implement modifier + vertical/horizontal wheel and button-hold + mouse motion gestures with thresholds/cancellation.
- [ ] Normalize button labels and numbers across HID/NSEvent/Quartz sources.
- [ ] Handle event tap disable/timeouts, sleep/wake, engine restart, and permission removal gracefully.
- [ ] Build a safe diagnostics view/tool that shows event metadata and raw button code, **never typed strings**.
- [ ] Verify original-event suppression / passthrough and down/up symmetry with real apps.
- [ ] Add tests for hold/release, click counts, scroll throttling, event cancellation, and disabled mode.

**Exit evidence:** all advertised core keyboard/mouse bindings reliably work in ordinary apps without stuck keys or click-through surprises.

### Phase 3 - HID discovery and device capabilities

- [ ] Enumerate attached keyboards, standard/third-party mice, trackpads, and Magic Mouse where exposed by APIs.
- [ ] Display meaningful vendor/product labels and connected state; handle hotplug/disconnect/reconnect.
- [ ] Report real, observable button capabilities, including any buttons above #5.
- [ ] Keep category-wide rules separate from device-bound rules and define honest unknown-source behavior.
- [ ] Test physical source attribution with multiple simultaneously connected mice; implement per-device rules **only if interception/source can be correlated reliably**.
- [ ] Verify device ID stability after reconnect and restart; avoid conflating identical mice.
- [ ] Keep disconnected-device bindings persisted.

**Exit evidence:** devices and availability are truthful; any unresolved per-device limitations are marked and explained.

### Phase 4 - System actions and unified action catalog

- [ ] Add a single typed action catalog for all devices, with clear categories and parameter definitions.
- [ ] Keyboard shortcuts/keys and mouse click output, including reliable modifier release.
- [ ] Implement supported window/application actions using native API, AX, or justified shortcuts.
- [ ] Implement Mission Control, Desktop/Space navigation, Show Desktop and related operations via verified integration; document shortcut configuration dependency.
- [ ] Implement media volume/mute/playback and other available system actions, with capability checks.
- [ ] Implement open app, activate app, open URL/file, and Apple Shortcut integration where reliable.
- [ ] Omit or explicitly mark unavailable entries rather than leaving inert choices in the picker.
- [ ] Unit tests for action parameter validation; manual tests for representative actions in other apps.

**Exit evidence:** every visible enabled action has a real implementation; unsupported system functions are explained.

### Phase 5 - Multitouch trackpad feasibility and implementation

- [ ] Validate actual raw touch events on built-in trackpad / Magic Trackpad with current macOS.
- [ ] Audit OpenMultitouchSupport (private framework, default trackpad only, sandbox implications) and alternatives; choose and record integration strategy.
- [ ] Build reliable tap classification for supported 3/4/5 finger counts, single/double touch when feasible, hold and directional swipe; test noise, cancellations, timing.
- [ ] Add suitable modifier+gesture combinations when modifier state is available during recognition.
- [ ] Investigate pinch/rotation/Force Click and add only those actually workable.
- [ ] Test system gesture conflicts and suppression limitations in System Settings permutations.
- [ ] Validate four-finger tap → `Command + W` **on physical hardware**; document any double-effect scenario with safe remediation.
- [ ] Build a real record gesture UX only for supported gestures; provide useful unavailable states otherwise.
- [ ] Add recognition pure-logic tests (contact sequences, one-shot firing, reset/cancel), separate from hardware tests.

**Exit evidence:** a truthful trackpad capability matrix and hardware-verified mapping, or a documented blocker with a safe user-facing limitation.

### Phase 6 - Magic Mouse integration

- [ ] Inspect hardware and current low-level frameworks for genuine Magic Mouse touch events.
- [ ] Audit relevant MIT alternatives/references; do not paste GPL-3.0 project code without a licensing decision.
- [ ] Implement Magic Mouse-specific touch acquisition, gesture detection and mouse/scroll coexistence.
- [ ] Reuse trackpad recognition when semantics match, without forcing mismatched hardware into identical gestures.
- [ ] Add capture/recording and action binding for verified supported gestures.
- [ ] Test actual Magic Mouse gestures, native scrolling conflicts, disconnect/reconnect, and pause.

**Exit evidence:** supported Magic Mouse gestures are verified on named real hardware; other requested gestures are clearly labeled as unsupported/experimental.

### Phase 7 - Settings, persistence, permissions and background lifecycle

- [ ] Versioned, atomic local JSON configuration; schema evolution, corrupt file recovery, import/export/reset.
- [ ] App window can close while engine and Menu Bar menu remain active.
- [ ] Launch at Login using ServiceManagement (`SMAppService`) and real state checks.
- [ ] First-run permissions onboarding; accurate Accessibility/Input Monitoring state, action-specific Automation requests.
- [ ] Revalidation and clear guidance when returning from System Settings; helpful errors for tap creation failure.
- [ ] Settings: General, Permissions, Input, Language, Advanced; About screen with version/licenses.
- [ ] Ensure repeated window opening does not create duplicate taps/services.
- [ ] Verify relaunch, login, sleep/wake, permission revocation, and paused/disabled behavior.

**Exit evidence:** reliable long-running background utility with recoverable persisted state and no fake permission toggles.

### Phase 8 - Full SwiftUI experience and visual polish

- [ ] Review all available user references under `docs/references/`.
- [ ] Implement native macOS 26 `NavigationSplitView` with devices left, bindings/actions main, divider, Settings/About at bottom.
- [ ] Binding list, searchable action chooser, recording sheets, states/conflicts/empty screens.
- [ ] Thoughtful Liquid Glass, consistent typography, spacing, platform-native feedback, SF Symbols and window resizing.
- [ ] Adapt focus/keyboard navigation; VoiceOver labels; light/dark, Reduce Motion, increased contrast.
- [ ] Create the final Rebind application icon asset (white/light, distinctive dimensional remapping/key symbol), and verify Dock/Finder small sizes.
- [ ] Manual usability pass: creating a new binding requires no raw key/button codes and as few decisions as possible.

**Exit evidence:** aesthetically finished **functional** native UI that aligns with provided references; no inert controls or placeholder data.

### Phase 9 - Four-language localization

- [ ] Add String Catalog keys and localized text for English, Russian, German, French.
- [ ] Select system default + offer manual language setting; implement genuine switching behavior or accurately explain relaunch.
- [ ] Localize actions, trigger names, errors, permission/onboarding text, Settings, About, tooltips and accessibility labels.
- [ ] Test EN/RU/DE/FR layouts, long strings, keyboard glyphs, empty states and error screens.

**Exit evidence:** core UX has no untranslated strings in any of the four selected languages.

### Phase 10 - Final integration, packaging, and reliability pass

- [ ] Re-run acceptance walkthroughs from `SPEC.md` §15; record pass/fail/experimental, macOS build and devices for each.
- [ ] Run unit tests and full Xcode build; fix issues introduced by concurrency, code signing, packaging or permissions.
- [ ] Smoke-test background operation over repeated enable/disable and sleep/wake cycles, high-frequency input and reconnects.
- [ ] Audit dependencies/licenses and produce third-party credits.
- [ ] Prepare runnable app distribution guidance for outside Mac App Store, including signing/notarization considerations if distribution is desired.
- [ ] Write concise launch/build instructions in repository documentation (may add README later).
- [ ] Conduct a final check that no experimental or missing feature is described as complete.

**Exit evidence:** reproducible build, credible hardware verification record, clean UI, safe runtime, and an honest known-limitations section.

---

## Research findings / blockers

> Updated from Apple documentation/installed SDK and reviewed upstream sources on 2026-10-08. These establish candidate mechanisms, **not verified Rebind hardware behavior**. No input capture or synthesis was run during preparation.

### Native API comparison and provisional first-slice direction

- **Keyboard/mouse filtering:** prefer a small native Core Graphics adapter for Phase 1. Active taps can pass through, replace or drop events; passive `listenOnly` taps cannot filter. Handle key down/up, flags changes, other-mouse down/up/drag and scroll, tap disable/timeout, and tagged synthetic input. The callback belongs to its CFRunLoop and must remain synchronous. [Quartz Event Services](https://developer.apple.com/documentation/coregraphics/quartz-event-services), [callback contract](https://developer.apple.com/documentation/coregraphics/cgeventtapcallback), and installed `CGEvent.h` / `CGEventTypes.h` inspected. No framework wrapper needed merely to create a tap; lifecycle, state matching and action dispatch still need real implementation/tests.
- **API discrepancy:** Apple [tapCreate documentation](https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate(tap:place:options:eventsofinterest:callback:userinfo:)) and SDK header still describe root-only HID-level placement, while current LinearMouse and pqrs examples use HID taps in permission-gated apps. Do not resolve this by adding root privileges. Start with a session-level tap; measure interception order/permission behavior on the target OS before choosing a lower placement or making suppression claims.
- **AppKit:** `NSEvent` is useful for app-local recording and UI/platform integration. A global monitor is observation-only, excludes the app's own events, and cannot replace the interception engine. [Apple event-monitor guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html); SDK `NSEvent.h` agrees.
- **HID:** public `IOHIDManager` provides device matching/removal callbacks, element/report values, vendor/product identity and button usages. Enumeration/non-seizing capture does not suppress Quartz delivery. Seizing is a different architecture with failure/re-emission risks; defer. [IOHIDManager](https://developer.apple.com/documentation/iokit/iohidmanager_h), SDK `hid/IOHIDManager.h`, and pqrs examples inspected. Keep per-device discovery separate from reliable per-event attribution.
- **Permissions:** check `AXIsProcessTrusted` / `AXIsProcessTrustedWithOptions`, `CGPreflightListenEventAccess`, `CGPreflightPostEventAccess`, and method-appropriate `IOHIDCheckAccess`. Request only the selected capture/action's access; verify state and actual tap creation after System Settings. A prompt is asynchronous and does not make AX trust true. [AX trust](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions), [listen preflight](https://developer.apple.com/documentation/coregraphics/cgpreflightlisteneventaccess()), [post preflight](https://developer.apple.com/documentation/coregraphics/cgpreflightposteventaccess()), [IOHID access](https://developer.apple.com/documentation/iokit/3181573-iohidcheckaccess), [Apple consent overview](https://developer.apple.com/videos/play/wwdc2019/701/). No permission is required by the unchanged starter app or requested this session.
- **Secure Input:** Apple explains that secure keyboard contexts withhold events and exposes `IsSecureEventInputEnabled`. Fail safely; never log text, read passwords, or disable Secure Input to regain capture. [TN2150](https://developer.apple.com/library/archive/technotes/tn2150/_index.html) is archived guidance, not proof of current Rebind behavior; modern protected contexts require manual checks.
- **Native actions/lifecycle:** prefer `AXUIElement` for supported window operations, `NSWorkspace` for opening/activating apps and URLs, Core Audio for supported output-volume properties, and `SMAppService.mainApp` for launch-at-login. Verify action-level support and errors; output shortcuts can depend on user keyboard settings. [AX client APIs](https://developer.apple.com/documentation/applicationservices/axuielement_h), [NSWorkspace](https://developer.apple.com/documentation/appkit/nsworkspace), [Core Audio](https://developer.apple.com/documentation/coreaudio), [SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice). Apple's SMAppService DocC JSON was also retrieved to bypass the JavaScript-only web shell. No public universal Space-switch or media-control mechanism was established; defer those specific actions until validated. SwiftUI/AppKit own menu-bar/window lifecycle; no helper is currently justified.
- **Performance:** maintain a small event mask and synchronous allocation-light matcher; bound any diagnostic/action handoff and stream buffering. Package convenience does not establish callback safety. For private touch adapters, audit C-buffer lifetime, callback cancellation, hotplug/wake behavior and concurrency before selection; do not copy singleton/force-unwrap/main-queue patterns blindly.

### Risk R-01 - Trackpad raw contacts vs OS gesture suppression

- **Source evidence:** OpenMultitouchSupport currently uses `MTDeviceCreateDefault`, a private binary framework, Swift tools 6.2/macOS 15+, and requires sandbox off. Its Swift adapter maps frames and formats timestamps; audit overhead/ownership before use. Subsurface supports multiple-device monitoring and recognition; its source also classifies Magic Mouse, but has private API and dependency risks.
- **Unknown:** actual four-finger tap behavior, conflicts and suppressibility on target macOS/mac hardware.
- **Action:** spike on hardware before claiming replacement behavior; isolate private API adapter. Sanne explicitly describes system-gesture conflicts and advises disabling overlapping OS gestures; contact callbacks are not suppression proof. [Sanne guidance](https://github.com/anandghegde/sanne), [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport), [Subsurface](https://github.com/mrkai77/Subsurface).
- **Status:** Researching (no Rebind implementation/test evidence yet).

### Risk R-02 - Mouse device attribution

- **Source evidence:** public CGEvent fields do not establish unique hardware identity. [LinearMouse's device routing](https://github.com/linearmouse/linearmouse/blob/03b0656dc5e4364ee951449e0851a029a25fd5be/LinearMouse/Device/DeviceManager.swift) uses private `CGEventCopyIOHIDEvent` and `IOHIDEventGetSenderID`; unavailable attribution/keyboard events can use last-active-device fallback. This fallback is insufficient evidence for Rebind's exact per-device semantics. Receiver multiplexing and identical models add ambiguity.
- **Unknown:** viable low-latency correlation/interception for two simultaneous mice.
- **Action:** test source tagging/correlation and fail safely to all-mice scope if inconclusive.
- **Status:** Researching.

### Risk R-03 - Extra mouse buttons and vendor drivers

- **Source evidence:** SDK `NSEvent.buttonNumber` and `CGEventField.mouseEventButtonNumber` expose numeric values; HID button usage is separate. Common Quartz/AppKit primary/secondary/middle indexes are 0/1/2, while human/HID Button 1/2/3 labels are typically one-based. Normalize verified events, preserve unknown numbers, and do not import another app's fixed maximum. [NSEvent](https://developer.apple.com/documentation/appkit/nsevent), [LinearMouse mapping documentation](https://github.com/linearmouse/linearmouse/blob/03b0656dc5e4364ee951449e0851a029a25fd5be/Documentation/Configuration.md). OEM remapping/HID++ can emit keys or consume events instead of mouse-button events.
- **Unknown:** behavior across specific user hardware and macOS installations.
- **Action:** include raw button-number diagnostics and test actual side buttons; don't hard-code maxima.
- **Status:** Researching.

### Risk R-04 - Magic Mouse multitouch

- **Source evidence:** MIT Sanne enumerates private MultitouchSupport devices and separates mouse/trackpad acquisition. Apache-2.0 Subsurface's device source recognizes Magic Mouse families with a built-in-device caveat. These are alternatives to GPL-3.0-only Magic Mouse Toolkit; none establishes Rebind hardware support. The GPL toolkit also documents permission-revocation hazards, reinforcing the need for fail-open design rather than importing its runtime.
- **Unknown:** actual capture, suppression and compatibility for requested gestures.
- **Action:** research MIT/public/private alternatives and test on real Magic Mouse; honor license obligations.
- **Status:** Researching.

### Risk R-05 - System actions and Space switching

- **Source evidence:** native AX/NSWorkspace/ServiceManagement cover discrete responsibilities. HotKey and KeyboardShortcuts register Carbon hotkeys; they are not arbitrary key/button remapping engines. LinearMouse's DockKit includes private declarations, so do not treat it as a public universal system-action layer.
- **Unknown:** which actions can be invoked and verified on target macOS with current user settings.
- **Action:** record mechanism per action, preconditions, permission needs and tested result.
- **Status:** Researching.

### Risk R-06 - Permission/signing stability

- **Known lead:** Accessibility, Input Monitoring and Automation have different flows; code signing changes can alter prompts and grants.
- **Verified preparation:** stable bundle ID, local ad-hoc Debug/Release signatures and launch; no team/usable certificate configured. Release hardened runtime has no entitlements. Xcode test preparation injects temporary Debug test-runner allowances; these are absent from final Release. [pqrs signing note](https://github.com/pqrs-org/osx-event-observer-examples/blob/c55d9c994a2aa8528e5410d5409e2a6242801e77/cgeventtap-example/README.md) reinforces identity stability for repeated builds.
- **Unknown:** actual TCC prompts, trust restoration/revocation and Developer ID/notarization for this app; no input features yet.
- **Action:** keep bundle ID stable, test real prompts/state, record code signing settings without weakening security.
- **Status:** Researching.

## Dependency decision register

Reviewed upstream manifests, READMEs/licenses and relevant capture/source files. Maintenance dates below are the reviewed default-branch commit dates, not guarantees of quality or OS support. **No candidate runtime code was copied or installed, and no third-party library was built.** Source compatibility is declared upstream; Swift 6/macOS 26 runtime behavior still needs validation.

| Candidate / source | Purpose, compatibility and maintenance | License / limits / decision |
|---|---|---|
| [Apple Core Graphics / IOKit HID / AX](https://developer.apple.com/documentation/coregraphics/cgevent) | Native filtering, synthesis, device discovery, supported actions; installed SDK 27 declarations inspected, usable API availability predates macOS 26 | Apple SDK terms; **prefer native for Phase 1**, no package. Session placement, permissions, lifetime/symmetry and Secure Input still need implementation/hardware checks. |
| [pqrs event-observer examples](https://github.com/pqrs-org/osx-event-observer-examples) | Quartz/HID/NSEvent comparison; macOS 10.13+; Objective-C/C++; commit 2026-10-03, `c55d9c9`, not archived | Unlicense; **reference only**. Requires CMake to build samples; none executed because they collect global events and are unnecessary for preparation. |
| [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport) | Default trackpad contacts; tools 6.2/macOS 15+, Xcode 26.2+; commit 2026-05-28, `15c6bb0`, not archived | MIT; binary XCFramework 4.0.0 plus swift-async-algorithms ≥1.1.4. Private API/sandbox off, default-device limit and per-frame work; **defer to Phase 5 hardware spike**. |
| [Subsurface](https://github.com/mrkai77/Subsurface) | Raw contacts, hotplug, gesture recognition, haptics; tools 6.2/macOS 13+; commit 2026-09-30, `88eb16b`, not archived | Apache-2.0; private framework; Scribe dependency tracks mutable `main` branch. Source includes locked callback state and Magic Mouse classification; audit buffer/backpressure/ABI, pin transitive revisions; **defer**, promising multi-device alternative. |
| [Sanne](https://github.com/anandghegde/sanne) | Trackpad/Magic Mouse and actions reference; tools 5.9/macOS 13+; commit 2026-10-05, `53bee5b`, not archived | MIT; full application with private dynamic framework and broader scope. **Reference only**, not an app-library dependency; audit ABI/provenance/concurrency before any later reuse. Native gesture conflicts explicitly documented. |
| [Magic Mouse Toolkit](https://github.com/mori0818/magic-mouse-toolkit) | Magic Mouse acquisition/remapping reference; macOS 26 SDK+, no root SPM manifest; commit 2026-08-04, `304e63c`, not archived | GPL-3.0-only; private MultitouchSupport/IOKit SPI and app-specific safety limitations. **Do not copy or link** absent explicit licensing decision; MIT/Apache alternatives preferred for evaluation. |
| [LinearMouse](https://github.com/linearmouse/linearmouse) | Mouse filtering, lifecycle, private sender routing and action references; Swift 5 mode, macOS 10.15 generally/12 with SDK 27; commit 2026-10-05, `03b0656`, not archived | MIT; app with several local modules, private event/HID/Dock APIs and fallback attribution. **Reference only**, not a drop-in Swift 6-safe engine; test exact sender routing with two mice before reuse. |
| [Karabiner-Elements](https://github.com/pqrs-org/Karabiner-Elements) | Physical keyboard/Caps Lock/device-seizing architecture reference; upstream supports macOS 13–27; build Xcode 26+/macOS 15+; commit 2026-10-04, `ec2fea8`, not archived | Root project Unlicense; dependencies have separate licenses. Virtual HID driver, multiple services and permissions exceed single-process scope; **do not install**, revisit only if measured key semantics require it. |
| [Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix) | Mouse gesture/lifecycle research; Objective-C/Swift Xcode app, no root package; current README targets macOS 11+; commit 2026-10-08, `dae242d`, not archived | Custom **MMF License**, not assumed MIT/GPL; distribution/monetization restrictions. **Conceptual reference only**, no copying/bundling. Third-party licenses need separate review. |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | Shortcut recorder and Carbon registered-hotkey handling; tools 6.2/macOS 10.15+, main-actor default; commit 2026-09-11, `772133d`, not archived | MIT; maintained recorder candidate, but cannot replace arbitrary event filtering, modifier-only keys or mouse interception. **Defer** until recording UX needs it; potential dependency for UI, not engine. |
| [HotKey](https://github.com/soffes/HotKey) | Carbon registered-hotkey wrapper; tools 5.0, README Swift 5/macOS support, no manifest minimum; commit 2024-12-29, `a3cf605`, not archived | MIT; older activity and same interception limits; strict-concurrency audit required. **Defer**, no current need. |
| [AXSwift](https://github.com/tmandry/AXSwift) | Swift AX client wrapper; tools 4.0, no manifest OS floor; commit 2021-11-14, `e18a184`, not archived | MIT; longstanding low-level wrapper, no recent Swift 6 verification. **Defer**, use native AX first for small action slice, revisit wrapper value in Phase 4. |
| Project skills | Four installed instruction bundles, see skill register and `.agents/skills/manifest.json` | MIT, **installed at project scope**. Never linked into Rebind; no runtime impact. |

Swift Package Index was searched: [KeyboardShortcuts](https://swiftpackageindex.com/sindresorhus/KeyboardShortcuts) and [HotKey](https://swiftpackageindex.com/soffes/HotKey) listings accessed. OpenMultitouchSupport/Subsurface listing requests returned tool errors and did not provide compatibility evidence; use their reviewed manifests rather than claiming index build verification. Full GitHub commit SHAs are in installed-skill manifest where applicable; runtime source links/reviewed short revisions above identify research snapshots and must be rechecked before adoption.

Update this table when a package is actually installed or rejected. Don't present candidate names as installed dependencies.

## Capability verification matrix

Update statuses as functionality is implemented and tested. Fill exact device + OS build + evidence.

| Capability | Initial status | Hardware / OS tested | Evidence / limitations |
|---|---|---|---|
| Keyboard shortcut capture and remap | Planned | None | Requires global capture/injection test |
| Physical key remap including Caps Lock | Planned | None | Caps Lock requires extra research |
| Modifier + Mouse Button 4/5 | Planned | None | Requires extra-button mouse |
| Buttons beyond 5 | Planned | None | Test actual device/driver events |
| Modifier + wheel | Planned | None | Continuous event throttling |
| Button-hold + pointer direction | Planned | None | Gesture state machine |
| Per-physical-device rules | Researching | None | No source attribution proof yet |
| Trackpad four-finger tap | Researching | None | Private API and OS conflicts |
| Trackpad swipes/pinch/rotate | Researching | None | Varies by gesture/OS |
| Magic Mouse touch gestures | Researching | None | Separate hardware validation |
| Space switching | Researching | None | Shortcut mapping may be user-dependent |
| Menu Bar and Launch at Login | Planned | None | ServiceManagement/permissions test |
| EN / RU / DE / FR | Planned | None | String Catalogs, UI checks |

## Session log

### 2026-10-08 — Repository preparation (no application features)

- Inspected all tracked project/source/workspace/assets/docs/references, Git status/history/ignore/remote state, capabilities/signing, installed Xcode/Swift/SDK/SwiftPM, and existing local user data. Read `AGENTS.md`, full `SPEC.md` and `PLAN.md` before changes. No Xcode MCP build/doc tools were exposed, so used Apple command-line tooling and SDK headers.
- Applied project settings, added real test target/shared scheme, four audited skills, checksum manifest, build/run helper, README and ignore rules. Preserved source, requirements, roadmap and user changes. No feature implementation, input monitoring, scripts/actions, runtime dependency installation, Git commits or pushes.
- Exact successful commands (each wrapper exports full-Xcode `DEVELOPER_DIR` and uses shared scheme, macOS destination and ignored `build/DerivedData`):
  - `scripts/dev.sh doctor`: Xcode 27.0/Swift 6.4/SwiftPM 6.4.0-dev/SDK 27.0; `xcodebuild -list` reports app and test targets/shared scheme.
  - `scripts/dev.sh build`: **BUILD SUCCEEDED**, Debug arm64, Swift 6/macOS 26.0.
  - `scripts/dev.sh build-for-testing`: **TEST BUILD SUCCEEDED**, hosted test bundle compiled/linked with Swift Testing and app import.
  - `scripts/dev.sh test -resultBundlePath build/PreparationTests.xcresult`: **TEST SUCCEEDED**, **0 tests / 0 failures**; runner/host verification only.
  - `scripts/dev.sh release`: **BUILD SUCCEEDED** after final entitlement change; universal arm64/x86_64 binary. No Intel execution claimed.
  - `scripts/dev.sh resolve`: exit 0, empty resolved-package list, as expected. No `Package.swift` or `Package.resolved` needed with zero package dependencies; retain future lockfile in Git.
  - `scripts/dev.sh run`: successful Debug build and `open`; live process verified; native UI tool inspected the **exact Debug bundle path**, displaying window/menu **Rebind** and original globe/Hello-world content. Bundle-ID lookup was ambiguous due to existing DerivedData copies; do not delete user builds or interpret another copy as this verification.
  - `codesign --verify --strict --verbose=2 build/DerivedData/Build/Products/Release/Rebind.app`: valid on disk/designated requirement. `codesign -d --verbose=4 --entitlements - …`: ad-hoc signature, `runtime` flag, **no Release entitlements**. Built Info.plist shows `blinks44.rebind`, Rebind display/executable/name, `LSMinimumSystemVersion = 26.0`.
  - `xcodebuild -showBuildSettings … -configuration Release`: confirms Swift 6, complete diagnostics, MainActor, sandbox NO, hardened runtime YES, script sandbox YES, no team and automatic local identity.
  - `plutil -lint rebind.xcodeproj/project.pbxproj`, `bash -n scripts/dev.sh`, `python3 scripts/verify-skills.py`: passed; all four installed skills verified. Shared scheme IDs/product names, both targets' configurations, and source/SPEC preservation also checked against the parsed project.
  - `git diff --check`: passed. `git status --short` contains only preparation changes/new files; no generated build output. `git ls-files '*xcuserdata*' '*xcuserstate*'`: empty; existing local scheme-management file remains on disk. Ignore probes confirm docs, references, shared scheme, skills and future `Package.resolved` are visible while caches/results/user state are excluded. Repository has no remote; existing Git settings preserved.
- Logs saved for this machine in `/tmp/rebind-{doctor,debug-build,test-build,test-run,release-build,resolution,launch,release-settings}.log`; automated result in ignored `build/PreparationTests.xcresult`. Logs are not committed artifacts.
- Environment caveat: the first sandboxed build failed because Apple's Preview macro plugin could not launch its own sandbox (`sandbox_apply: Operation not permitted`); rerunning the unchanged project through approved out-of-agent-sandbox execution passed. No compiler-macro sandbox or OS protection was disabled. Sandboxed inventory also emitted unrelated CoreSimulator/cache warnings; approved full-Xcode operations avoid these constraints.
- Remaining observed warnings: Xcode skips AppIntents metadata extraction because no AppIntents framework is linked (expected for starter; do not add a framework to suppress a tooling warning). Test host reports unavailable `com.apple.linkd.autoShortcut` service in this environment; runner and standalone app still succeed. No Swift source/concurrency warnings observed.
- **Remaining manual/implementation work:** stable development signing before permission persistence tests; real macOS 26 runtime and Intel runtime verification if supported; physical keyboard/side-button mouse/trackpad/Magic Mouse and two-device tests in their phases; permission onboarding and safe revocation behavior. Distribution signing/notarization requires user credentials. No current build/preparation blocker remains.
- **Next:** start Phase 1's smallest native keyboard + modifier/mouse remapping slice with pure matcher tests and permission-gated hardware verification, when explicitly requested. Hardware feasibility boxes remain open; preparation does not satisfy feature acceptance.

### 2026-10-08 - Initial specification and plan

- Created initial product requirements, agent instructions, and staged plan outside the project repository.
- No project source files, Xcode configuration, installed packages, builds, or hardware behavior have been examined at this point.
- **Next:** inspect existing Xcode project; research key risks; implement Phase 1's first working end-to-end remap, with tests and precise evidence.

<!-- Add future sessions here, newest first. Keep concise and verifiable. -->
