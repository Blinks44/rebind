# Rebind - Development Plan and Verification Log

**Plan status:** Draft; the first agent must reconcile it with the existing Xcode project before executing it.  
**Last reviewed:** 2026-10-08 (initial product planning; not proof of implementation).  
**Owner:** Coding agent, with user decisions on major architecture or license trade-offs.  
**Product requirements:** `SPEC.md`  
**Engineering rules:** `../AGENTS.md`

## How to use this file

- Work in **thin, verifiable vertical slices**. Do not build months of UI ahead of the functional input engine.
- Before changing a box to `[x]`, record concrete evidence: files changed, build/test commands and results, actual macOS/device test when needed. `[x]` means the stated acceptance criteria are met, not merely attempted.
- `Implemented` does not equal `Verified`. Hardware-dependent features remain unverified without physical testing. Use the capability status vocabulary in `SPEC.md` §13.
- If an OS limitation prevents a task, note reproduction steps, research sources, workaround options, and product/UI implications under **Research findings / blockers**.
- Keep all phase names, outcomes, and next actions up to date for a new agent session. Add concise entries to **Session log** after substantive changes.
- Initial checked boxes below intentionally **none**; no repo inspection or code verification has yet been performed.

## Milestones

### Phase 0 - Repository inventory, feasibility and dependency audit

**Goal:** avoid architecture mistakes before writing low-level interception code; immediately move toward a working prototype when feasibility is clear.

- [ ] Inspect project target(s), source layout, bundle ID, entitlements, sandbox setting, build scheme, current macOS deployment target, Swift language mode, tests, and existing work. **Preserve the existing project.**
- [ ] Confirm toolchain availability (Xcode / `xcodebuild`, build destination, Swift version). Document exact command to build the app.
- [ ] Read relevant Apple docs for `CGEventTap`, event types, synthesis, IOKit/HID, Accessibility, secure input, permission prompts, background app lifecycle, and `SMAppService`.
- [ ] Confirm which combinations allow interception plus suppression, which permit observation only, and which are blocked by the OS.
- [ ] Investigate mapping per-event → physical HID device; **test two-mouse attribution before promising per-device rules**.
- [ ] Investigate normal and extra buttons beyond #5, including differing HID/CGEvent numbering, firmware/driver overrides, and limits.
- [ ] Investigate real trackpad four-finger tap capture, native gesture conflicts, and suppression feasibility.
- [ ] Investigate Magic Mouse contact capture separately from trackpad. Do not assume one library covers both.
- [ ] Compare reusable packages/references with license, Swift/macOS compatibility, sandbox requirements and maintenance status. Review code/skill content before installing.
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

> Fill this section with evidence after inspecting the repo and testing actual APIs/hardware. The entries below are **initial leads, not verified Rebind behavior**.

### Risk R-01 - Trackpad raw contacts vs OS gesture suppression

- **Known lead:** OpenMultitouchSupport uses a private MultitouchSupport framework, documents default-device-only trackpad scope, and requires App Sandbox disabled.
- **Unknown:** actual four-finger tap behavior, conflicts and suppressibility on target macOS/mac hardware.
- **Action:** spike on hardware before claiming replacement behavior; isolate private API adapter.
- **Status:** Researching (no Rebind implementation/test evidence yet).

### Risk R-02 - Mouse device attribution

- **Known lead:** HID enumeration identifies devices, but a global Quartz event does not automatically carry an unambiguous physical-mouse identity.
- **Unknown:** viable low-latency correlation/interception for two simultaneous mice.
- **Action:** test source tagging/correlation and fail safely to all-mice scope if inconclusive.
- **Status:** Researching.

### Risk R-03 - Extra mouse buttons and vendor drivers

- **Known lead:** AppKit/Quartz can expose extra button indexes; some physical buttons are intercepted or translated by proprietary tools.
- **Unknown:** behavior across specific user hardware and macOS installations.
- **Action:** include raw button-number diagnostics and test actual side buttons; don't hard-code maxima.
- **Status:** Researching.

### Risk R-04 - Magic Mouse multitouch

- **Known lead:** Native and community implementations exist, but hardware/API behavior differs from trackpads. A potential reference project is GPL-3.0.
- **Unknown:** actual capture, suppression and compatibility for requested gestures.
- **Action:** research MIT/public/private alternatives and test on real Magic Mouse; honor license obligations.
- **Status:** Researching.

### Risk R-05 - System actions and Space switching

- **Known lead:** many system behaviors are best exposed through user-configured shortcuts, Accessibility, or action-specific integrations, not a single universal public API.
- **Unknown:** which actions can be invoked and verified on target macOS with current user settings.
- **Action:** record mechanism per action, preconditions, permission needs and tested result.
- **Status:** Researching.

### Risk R-06 - Permission/signing stability

- **Known lead:** Accessibility, Input Monitoring and Automation have different flows; code signing changes can alter prompts and grants.
- **Unknown:** actual Xcode/Developer ID/run behavior of this repo.
- **Action:** keep bundle ID stable, test real prompts/state, record code signing settings without weakening security.
- **Status:** Researching.

## Dependency decision register

| Candidate | Role | License / notes | Decision | Evidence needed |
|---|---|---|---|---|
| Native Core Graphics / HID / Accessibility | Input and actions | Apple APIs | Evaluate first | Current Apple docs; running prototype |
| OpenMultitouchSupport | Trackpad raw touch data | MIT; private API, default device; sandbox off per README | Research only | Compatible build, real hardware, limitations |
| Sanne | Gesture-app reference | MIT | Research only | Audit integration usefulness vs complexity |
| Magic Mouse Toolkit | Technical reference | GPL-3.0 | **Reference only pending licensing decision** | Avoid copying source without license review |
| SwiftUI Pro / other Swift Agent Skills | Coding-agent instructions, not app runtime | Individually review source and licenses | Optional, inspect before install | Applicable skill contents, trust review |

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

### 2026-10-08 - Initial specification and plan

- Created initial product requirements, agent instructions, and staged plan outside the project repository.
- No project source files, Xcode configuration, installed packages, builds, or hardware behavior have been examined at this point.
- **Next:** inspect existing Xcode project; research key risks; implement Phase 1's first working end-to-end remap, with tests and precise evidence.

<!-- Add future sessions here, newest first. Keep concise and verifiable. -->
