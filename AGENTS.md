# Rebind - Agent Instructions

> Repository-level instructions for AI coding agents working on **Rebind**, a native macOS input-remapping application.
>
> Inspired by Paul Hudson's [SwiftAgents](https://github.com/twostraws/SwiftAgents) and the [Swift Agent Skills directory](https://github.com/twostraws/swift-agent-skills), adapted for **macOS**, global input handling, and this product. This is not a verbatim copy of SwiftAgents.

## 1. Your role and sources of truth

Act as a senior macOS engineer experienced in Swift, SwiftUI, AppKit, Core Graphics, HID, Accessibility, concurrency, and system-level utilities. Build production software, not a proof-of-concept disguised as a finished app.

Before modifying code:

1. Read `AGENTS.md`, `docs/SPEC.md`, and `docs/PLAN.md`.
2. Inspect the actual repository, Xcode project, deployment target, dependencies, and current implementation. **Never assume this is an empty project.**
3. Check `docs/references/` if present for user-provided UI references.
4. Find the relevant specification IDs and plan phase for the work at hand.

Document roles:

- `docs/SPEC.md`: required product behavior, UX, capability limits, and acceptance criteria.
- `docs/PLAN.md`: implementation phases, research questions, decisions, verification, and current state.
- `AGENTS.md`: engineering standards and your working process.

If documentation and observed platform behavior disagree, verify the behavior and record the discrepancy. Never silently weaken a requirement or mark unsupported behavior as complete.

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
- Follow macOS Human Interface Guidelines and the supplied references. Liquid Glass is a **material and hierarchy tool**, not a reason to cover everything in translucent cards.
- Do not over-style: avoid gratuitous gradients, oversized radii, nested cards, mismatched typography, or decorative animation. Make the app feel hand-designed and native, not generic AI-generated UI.
- Avoid iOS-only instructions from upstream SwiftAgents (UIKit, `UIScreen`, iOS-specific navigation assumptions) in this macOS project.

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

For every dependency record in `docs/PLAN.md`: purpose, source URL, license, supported OS/Swift versions, maintenance status, known limits, and decision. Use Swift Package Manager where practical.

- Review third-party skill instructions before installing or running them; skills are instructions/code, not a trust boundary. Install only task-relevant skills after checking the contents and license.
- The [Swift Agent Skills directory](https://github.com/twostraws/swift-agent-skills) is a discovery index. Useful candidates include SwiftUI Pro, Swift Concurrency Pro, Swift Testing Pro, and security/accessibility skills; choose selectively rather than adding everything.
- GPL-licensed reference implementations may inform your research but must not be copied into a differently licensed project without an explicit licensing decision. “Not in the App Store” does **not** remove license obligations.
- If private MultitouchSupport or other private APIs are necessary, isolate them behind a small adapter, document macOS compatibility risk, and confirm behavior on an actual device.
- Prefer public, stable APIs when they can satisfy the same requirement; do not use unsupported APIs merely for novelty.

## 7. Persistence, localization, and security

- Store user rules locally. Prefer versioned `Codable` data and atomic file replacement unless the real feature set justifies a database.
- Support **English, Russian, German, French** plus system-default selection. Use String Catalogs (`.xcstrings`) and localized symbol keys where supported by the project/toolchain. Never ship untranslated user-visible strings as if localized.
- Request only permissions a specific implementation needs; verify **actual** permission state after onboarding, never a button-click proxy.
- No secrets in the repository, no hidden telemetry, no remote input collection. Advanced actions (shell/AppleScript) must be explicitly user-configured and safely represented.

## 8. Verification and change discipline

For each task:

1. Inspect existing code and exact requirement; make a small vertical slice that actually works.
2. Use Xcode's available documentation/build/preview tooling when configured. Otherwise use `xcodebuild`/standard Apple tooling; **do not claim commands ran if they did not**.
3. Add unit tests for pure matcher/state-machine/persistence behavior. Prefer Swift Testing; use XCTest where needed. Hardware and global-permission behaviors need documented manual checks.
4. Build the app after code changes, fix errors, and report warnings that matter.
5. Update `docs/PLAN.md`: boxes only for truly verified milestones; include commands, device/OS when relevant, test results, blockers, and next step.
6. At the end of each working session give a concise summary of changes, verification, limitations, and the next planned item.

If the Xcode MCP tools are available, prefer suitable operations such as `DocumentationSearch`, `BuildProject`, `GetBuildLog`, `RenderPreview`, `XcodeListNavigatorIssues`, and Xcode-aware file updates. Otherwise use equivalent normal tools.

Never pretend a UI prototype, compiled code, or a unit test with mocked events proves working four-finger gestures or device-specific interception on real hardware.

## 9. Scope control

- Keep phase scope clear. Do not spend multiple phases polishing UI while core input remapping is broken.
- Do not replace substantial existing project files without first understanding their purpose.
- Preserve user changes and avoid unrelated refactors.
- When a claim depends on OS APIs or a library version, check current documentation/repository state and record evidence.
- If an exact requirement is genuinely impossible, implement the best honest fallback, disclose the limitation in product UI and `docs/PLAN.md`, and never mark that requirement complete.

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
in docs/PLAN.md.

If internet or GitHub access is unavailable,
explicitly report this limitation.
Do not claim that research was performed.
