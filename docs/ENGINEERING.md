# Rebind — engineering standards

Read before changing app code or choosing an input/action mechanism. These standards preserve the original repository rules; workflow and design ownership live in [AGENTS](../AGENTS.md), [WORKFLOW](WORKFLOW.md) and [DESIGN](DESIGN.md).

## 2. Platform and technical baseline

- **macOS only**, initially target **macOS 26+**. Re-evaluate only with explicit technical reasons documented in the plan.
- Prefer **Swift 6.2+** using the current stable Xcode toolchain installed in the environment. Preserve existing project settings unless an update is necessary.
- Use **SwiftUI** for UI and **AppKit** for platform integration where SwiftUI is insufficient. Use Core Graphics/Quartz Event Services, IOKit/HID, Accessibility, and ServiceManagement where appropriate.
- No Electron, React Native, web-based UI, mandatory account, cloud backend, or analytics.
- Mac App Store distribution is **not** a requirement. App Sandbox may be disabled **if actually required**, with documented security and distribution implications. Do not disable SIP, weaken machine-wide security, or require root privileges as a shortcut.
- Prefer a single native app process with a menu-bar presence. Introduce helpers, privileged components, XPC, or separate agents only after demonstrating a real necessity.
- Choose the smallest reliable implementation. Do not build a generic automation platform or introduce profiles/workflows that the spec does not request.

## 3. Modern Swift rules

Adopt the useful macOS-applicable conventions from SwiftAgents:

- Prefer Swift's Observation framework (`@Observable`) for shared UI state. Isolate observable UI models on `@MainActor` unless the project intentionally uses main-actor default isolation; use `@State` for owned models, and `@Bindable` / `@Environment` as appropriate.
- Apply **Swift 6 strict concurrency** thoughtfully: define actor boundaries, make value types `Sendable` when appropriate, and do not silence data-race warnings with unjustified `@unchecked Sendable`.
- Use structured concurrency and `async`/`await` for asynchronous work when they fit. **Exception:** real-time event callbacks and required Core Foundation/C callbacks must follow their synchronous thread/run-loop contracts; never add `Task`, actor hops, blocking I/O, or unnecessary allocations on the critical event path.
- Prefer modern Foundation and `FormatStyle` APIs. Use `localizedStandardContains()` for user-facing search.
- Avoid force-unwraps, force-tries, unnecessary singletons, and legacy patterns when sound alternatives exist.
- Prefer clear types, small functions, explicit event lifecycle handling, and data-driven matching over giant switch statements.
- Comments should explain unusual system behavior, timing, API limitations, or ownership, not narrate obvious code.

## 4. SwiftUI and macOS UX rules

- Prefer native controls: `NavigationSplitView`, `List`, `Table` where suitable, `Form`, `Settings`, `MenuBarExtra`, `Button`, `Toggle`, `Picker`, sheets, and standard keyboard focus behavior.
- Prefer `foregroundStyle` over `foregroundColor`; prefer `clipShape(.rect(cornerRadius:))` where a rectangular clipping shape is needed; use current `onChange` overloads; use `Button` instead of a generic tap gesture for an actionable control.
- Use `@Observable` rather than legacy `ObservableObject` for new shared UI state unless integration requires otherwise.
- Use semantic SF Symbols with accessible text, useful tooltips, correct keyboard navigation, and meaningful accessibility labels.
- Respect light/dark appearance, Reduce Motion, Increase Contrast, and localization expansion.
- Follow [DESIGN](DESIGN.md), the live Sketch design and macOS Human Interface Guidelines. Rebind deliberately uses modern macOS 26+ materials, appropriate Liquid Glass, depth and restrained gradients; native controls do not require a flat legacy Settings appearance. Give effects a hierarchy/interaction purpose and preserve accessible fallbacks.
- Do not over-style: avoid gratuitous gradients, oversized radii, nested cards, mismatched typography, or decorative animation. Make the app feel hand-designed and native, not generic AI-generated UI.
- In `NavigationSplitView`, vertically fixed text outside scrolling content can inflate the native split's minimum height during sizing. Keep pinned Settings/runtime text responsive to size proposals; do not fix overflow with clipping or per-locale heights. Check each added section inside the full main window, including native split/column bounds, resizing and transitions; a standalone page fixture or root hosting bounds alone cannot establish integration. See [General regression evidence](verification/general-main-window-repair.md).
- Avoid iOS-only instructions from upstream SwiftAgents (UIKit, `UIScreen`, iOS-specific navigation assumptions) in this macOS project.

### Translating the live design into SwiftUI

Inspect the relevant Sketch composition **and** its shared symbols, Foundations and state annotations before changing a control. Use logical points, not dimensions inferred from a zoomed screenshot. Map colors to adaptive assets, text roles to shared typography and repeated geometry to scoped metrics. Sketch remains the source; these are executable implementation tokens, not a second visual specification.

Build repeated controls once as small SwiftUI views, `ButtonStyle` or `ViewModifier` implementations. Keep `Button`, native menu tracking, bindings, disabled behavior and system keyboard focus. Screens compose the same selector, capture, keycap, selection-track and feedback components; avoid a new style per screen. Reuse an existing component before introducing another abstraction.

Review a UI-only component specimen first, then the actual editor/window in the same state, language, appearance and logical size as Sketch. Keep previews independent of `AppModel`, persistent user data and input interception. Check active/inactive, enabled/disabled, focus, localized expansion and adaptive preferences separately. A layout test proves bounds; compilation does not prove materials. Fix observed differences before expanding adoption and record any native-renderer limitation explicitly. Never describe a custom wash as native Liquid Glass or claim full-screen fidelity from a component-only review.

## 5. Global input engine: non-negotiable rules

- Keep global interception, low-level event capture, input matching, action dispatch, persistence, and UI presentation separate enough to test, but avoid unnecessary interface layers.
- Treat physical keyboard codes, modifier state, mouse button identifiers, and gesture state as distinct concepts. Additional mouse buttons must **not** be restricted to a fixed enum of five or eight cases.
- Preserve down/up symmetry; modifiers, double press, hold, scrolling, gesture thresholds, and synthetic-event tagging must be deliberate.
- An unmatched input must preserve normal system behavior.
- Suppress a matched source event only when the actual interception mechanism supports suppression and when safe. Never claim a globally observed event can be suppressed if it cannot.
- Never assume a generic Quartz event can reliably identify which of two physical mice emitted it. Verify source attribution before enabling per-device behavior.
- Do not intercept, store, display, or log typed text. Respect Secure Input / password contexts and limit debug diagnostics to safe event metadata.
- Do not run UI updates, file writes, scripts, process launching, heavyweight gesture classification, or other blocking operations inside the synchronous tap callback.
- If a tap is disabled or permissions are revoked, fail safely: release synthetic held states, avoid trapping user input, and surface a useful status.
- Work with **real** APIs and observed hardware behavior. Differentiate `implemented`, `verified on hardware`, `experimental`, `blocked`, and `not implemented`.

## 6. Dependencies, private APIs, and agent skills

Before building difficult functionality from scratch, investigate maintained packages and native APIs. Potential research candidates are listed in `docs/SPEC.md`; **none is an automatic dependency**.

For every dependency record in `docs/research/DEPENDENCIES.md`: purpose, source URL, license, supported OS/Swift versions, maintenance status, known limits, and decision. Use Swift Package Manager where practical.

- Review third-party skill instructions before installing or running them; skills are instructions/code, not a trust boundary. Install only task-relevant skills after checking the contents and license.
- The [Swift Agent Skills directory](https://github.com/twostraws/swift-agent-skills) is a discovery index. Useful candidates include SwiftUI Pro, Swift Concurrency Pro, Swift Testing Pro, and security/accessibility skills; choose selectively rather than adding everything.
- GPL-licensed reference implementations may inform your research but must not be copied into a differently licensed project without an explicit licensing decision. “Not in the App Store” does **not** remove license obligations.
- If private MultitouchSupport or other private APIs are necessary, isolate them behind a small adapter, document macOS compatibility risk, and confirm behavior on an actual device.
- Prefer public, stable APIs when they can satisfy the same requirement; do not use unsupported APIs merely for novelty.

### Project-local skills and tooling

Reviewed skills live in `.agents/skills/` with their licenses and a small `manifest.json` recording sources, revisions and review notes. No per-file checksum validator is required. Codex supports this repository-local location; check the current skill list after installation and refresh/restart the client if a skill does not appear. Installed files and loaded session context are different. Read only the relevant skill and references:

- `swiftui-pro/SKILL.md`: SwiftUI changes, UI code review, localization, and view performance.
- `swift-concurrency-pro/SKILL.md`: isolation, shared state, asynchronous work, and Swift 6 diagnostics.
- `swift-testing-pro/SKILL.md`: behavioral unit/integration tests; UI tests still use XCTest.
- `appkit-accessibility-auditor/SKILL.md`: AppKit controls, focus, keyboard operation, and VoiceOver. This concerns UI accessibility, not TCC Accessibility permission.
- `swift-api-design-guidelines-skill/SKILL.md`: new Swift interfaces and call-site clarity; apply locally, not as permission for mass renaming/documentation churn.
- `swiftui-performance-audit/SKILL.md`: measured UI rendering/observation problems and Instruments evidence; separate from synchronous input-engine profiling.
- `swiftui-ui-patterns/SKILL.md`: component references, sheets, previews, macOS Settings and menu commands; read only the relevant reference.
- `swiftui-design-principles/SKILL.md`: visual hierarchy, spacing consistency, semantic colors and restrained native components.
- `swiftui-liquid-glass/SKILL.md`: native glass API composition when the requested design benefits from it; check actual macOS availability first.
- `swiftui-accessibility-auditor/SKILL.md`: SwiftUI semantics, keyboard/VoiceOver focus, contrast and motion; complements the AppKit auditor.
- `writing-for-interfaces/SKILL.md`: action names, hints, errors, onboarding and empty states; preserve behavior and translate all four languages.

For the design agent: follow [DESIGN](DESIGN.md) and [WORKFLOW](WORKFLOW.md), read `docs/SPEC.md` UX/action status requirements and the affected existing views, then inspect the current Rebind designs in Sketch via MCP. Load Sketch's `get_guide` (`mcp`, then `use` for document inspection/work); use document info, layer structure/styles and screenshots of the relevant frames rather than an old PNG or memory. Resolve the user-identified document/frames and reuse existing symbols/styles. If MCP is unavailable or the target is ambiguous, explain what is missing and ask for the document/frame; do not silently fall back to `design.png` or invent the current design. Reading a design for implementation does not authorize editing its Sketch document. For authorized design edits, follow the MCP guide and visually verify the changed frames. Use SwiftUI Pro plus Design Principles for ordinary visual work; consult UI Patterns, Liquid Glass, Writing for Interfaces and the appropriate accessibility auditor selectively. Keep the current Sketch design’s desktop hierarchy and native `NavigationSplitView`/`List`/`Table`/`Form`, semantic SF Symbols, standard keyboard operation and readable localized text. Reuse current UI state/persistence; do not change engine behavior or present unimplemented inputs/actions as working. Design exploration does not authorize running remappings or altering the user's rules/permissions. If another agent is editing the same UI/catalog file, agree file ownership before editing; preserve existing uncommitted work.

Upstream design skills contain iOS/widget examples and opinionated pixel/typography rules. Rebind's macOS controls, semantic fonts, native spacing and current Sketch design take precedence: no forced monospaced text, 44-point desktop rows, all-purpose 10-point cards, TabView/NavigationStack scaffold, UIKit colors or extra widgets. Check macOS 26 availability rather than accepting `#available(iOS 26, *)` as a macOS guard. Use glass for hierarchy/chrome when appropriate; keep content readable in light/dark appearance, Reduce Transparency, Increase Contrast and Reduce Motion. API-design documentation guidance applies to useful contracts, not boilerplate comments on every internal declaration. UI performance advice is a hypothesis until measured; avoid speculative caching/singletons.

Product copy is calm, concise, direct and helpful. Name the action/result, then give one practical next step if needed. Use existing localized terminology for rules, profiles, triggers, permissions and actions; keep technical implementation details in documentation unless they help a user decide. Prefer native label semantics over adding duplicate accessibility announcements. Do not invent functionality to shorten a limitation. New skill metadata does not authorize automatic agent spawning, scripts, dependency installs or publishing.

Resolve skill-relative paths from the installed folder. Rebind's macOS 26 minimum, actual installed SDK, and synchronous input-callback rules take precedence over upstream iOS examples, newer toolchain assumptions, and generic async advice. Do not install upstream plugin bundles or execute their scripts implicitly. See `docs/research/DEPENDENCIES.md` for review decisions.

Use `scripts/dev.sh doctor`, `build`, `release`, `build-for-testing`, `test`, `resolve`, or `run`; see `../README.md`. The script selects full Xcode per process without changing `xcode-select`. Keep target/scheme `rebind`, module `rebind`, and bundle ID `blinks44.rebind` stable; the app product is `Rebind.app`. Global-input code must explicitly opt out of the app target's default MainActor isolation where its callback contract requires it.

## 7. Persistence, localization, and security

- Store user rules locally. Prefer versioned `Codable` data and atomic file replacement unless the real feature set justifies a database.
- Support **English, Russian, German, French** plus system-default selection. Use String Catalogs (`.xcstrings`) and localized symbol keys where supported by the project/toolchain. Never ship untranslated user-visible strings as if localized.
- Request only permissions a specific implementation needs; verify **actual** permission state after onboarding, never a button-click proxy.
- No secrets in the repository, no hidden telemetry, no remote input collection. Advanced actions (shell/AppleScript) must be explicitly user-configured and safely represented.

## 8. Verification and handoff

Follow [WORKFLOW](WORKFLOW.md) for task-specific checks, evidence, status updates and handoff, including its local-by-default screenshot policy for native visual checks. Build after app code changes. Hardware acceptance is separate from compilation and mocked tests. Xcode MCP operations are preferred when available; otherwise use scripts/dev.sh.

## 9. Scope control

- Keep phase scope clear. Do not spend multiple phases polishing UI while core input remapping is broken.
- Do not replace substantial existing project files without first understanding their purpose.
- Preserve user changes and avoid unrelated refactors.
- When a claim depends on OS APIs or a library version, check current documentation/repository state and record evidence.
- If an exact requirement is genuinely impossible, implement the best honest fallback, disclose the limitation in product UI, `docs/CAPABILITIES.md` and the affected task, and never mark that requirement complete.

## 10. Research and Third-Party Libraries

Before implementing any non-trivial functionality,
actively research existing solutions.

Do not limit research to libraries explicitly mentioned
in SPEC.md.

Search GitHub, Swift Package Index, Apple documentation,
and relevant open-source macOS projects.

Pay particular attention to:

- Keyboard and mouse event interception
- HID device handling
- Additional mouse buttons
- Multitouch gesture recognition
- Magic Mouse gesture support
- macOS window management
- System actions and automation
- Accessibility permissions

Before implementing custom functionality:

1. Search for existing libraries or implementations.
2. Evaluate their compatibility with modern macOS.
3. Check maintenance activity and licensing.
4. Compare them against native Apple APIs.
5. Prefer a reliable existing solution when appropriate.

Do not reinvent complex low-level functionality
without investigating existing alternatives.

Do not blindly add dependencies.

Use native APIs when they provide a simpler,
more reliable implementation.

Document important dependency decisions
in docs/research/DEPENDENCIES.md.

If internet or GitHub access is unavailable,
explicitly report this limitation.
Do not claim that research was performed.
