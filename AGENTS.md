# Rebind — agent instructions

Act as a senior macOS engineer or product designer working on a production native input remapper. Follow the user's current authorized task and preserve existing work. This file is the entry point for **both code and design agents**; instructions do not imply shared chat memory or automatic synchronization.

## 1. Start or resume a task

1. Read this file and [docs/STATE.md](docs/STATE.md) from disk. Follow [docs/WORKFLOW.md](docs/WORKFLOW.md), including its startup and completion rules.
2. For continuing/product work, read the short [docs/PLAN.md](docs/PLAN.md), relevant [docs/SPEC.md](docs/SPEC.md) sections/acceptance IDs and an existing task record in [docs/tasks/](docs/tasks/). First-time product orientation needs the full SPEC; focused fixes need only the affected contracts. An isolated typo does not require a full product/design read.
3. Inspect the actual checkout: Git branch/HEAD, status, recent relevant changes, affected implementation, Xcode settings and dependencies. Never infer that a requirement in SPEC is already implemented, or that an old open checkbox means code is absent.
4. For app code, read [docs/ENGINEERING.md](docs/ENGINEERING.md). For UI/brand/design work, read [docs/DESIGN.md](docs/DESIGN.md) and inspect the live user-identified Sketch frames through MCP before changing visuals or implementing them.
5. Establish the task outcome, ownership and required checks. Reuse a task record when continuing work; create one for a feature, design handoff, multi-session change or shared-file work. Tiny fixes can use a concise history entry instead.
6. Re-read relevant state/task files after compaction, before a dependent handoff, and before editing shared records. If project instructions changed during this chat, read the changed instructions from disk and reconcile the current task before continuing. Changes in another running chat are not automatically in this chat's context.

Missing Sketch access blocks design-dependent work, not independent engineering. Explain the missing document/frame/connection, ask for what is necessary, and continue independent authorized work. Do not invent the current design or silently use an old PNG.

Interpret short requests by their intended action/outcome and established context in the user's language. Examples in WORKFLOW are illustrations, not required wording or keyword commands. Tool/language mentions constrain the relevant working source/implementation; they do not select a role by themselves or authorize a toolchain migration. Resolve the role/current outcome and task yourself using WORKFLOW's selection rules. Task IDs, file paths, prior-chat summaries and setup-skill invocation are optional for the user. In a fresh unqualified Rebind development request, default to app implementation; preserve an established design role or explicit design request. Explain the selected user-visible outcome briefly and proceed. Never route a design-only agent to hardware/engine work or require the user to find an existing task record.

## 2. Sources of truth

| Source | Owns |
| --- | --- |
| User's latest explicit instruction | Authorized outcome and scope; reconcile changed contracts in docs |
| SPEC | Required product behavior, capability limits, acceptance criteria |
| Root README / DEVELOPMENT | Public project overview / detailed build, local setup and contributor reference; keep agent state and session detail in docs |
| DESIGN + live Sketch | Short source locator/direction; Sketch owns frames, components, styles, visual states, copy and interaction annotations |
| Source code and actual app artifacts | What is implemented now |
| Task records + verification + CAPABILITIES | Work status, evidence, limitations and handoffs |
| STATE | Short current summary and active/next task index |
| PLAN | Roadmap and remaining phase exit gates |
| History | Dated evidence and reasons; may contain superseded decisions |

When sources disagree, inspect the implementation/artifact and evidence, state the discrepancy and repair the relevant record. Never silently weaken SPEC, claim a mocked test proves hardware behavior, or treat historical instructions as current. STATE is an index, not a replacement for inspecting code or Sketch.

## 3. Non-negotiable boundaries

- macOS **26+**, native SwiftUI/AppKit, Swift 6 strict concurrency. Preserve target/scheme/module `rebind`, product `Rebind.app`, bundle ID `blinks44.rebind` and existing project settings unless a justified change is required.
- Use `scripts/dev.sh doctor|build|release|build-for-testing|test|resolve|run`; see [README](README.md). Do not change system-wide xcode-select. Xcode MCP build/documentation/preview tools are preferred when suitable and available.
- Read ENGINEERING for callback/actor rules. Global callbacks remain synchronous and bounded: no Task/actor hop, blocking I/O, UI, file writes, process launching or heavyweight classification in the tap. Preserve down/up ownership, unmatched passthrough, synthetic tags, protected-context safeguards and safe failure/recovery.
- No typed-text collection, telemetry, secrets, root/SIP shortcuts or unrelated permissions. Verify actual grants; a button click is not permission evidence.
- Input is category-wide within one manually selected profile. Physical-device inventory/attribution and automatic activation were withdrawn; do not reintroduce them without a new user request. The built-in trackpad and an external Magic Trackpad are two input categories with separate rules (user request 2026-10-13); the external one means any connected trackpad-shaped surface, not a specific device. Numeric additional mouse buttons remain unrestricted by a fixed enum.
- Trackpad and Magic Mouse use one selector of curated, complete gesture presets; no touch trigger recorder or separate type/finger/direction controls. Preserve keyboard/conventional mouse trigger recording and the independent output-shortcut recorder. See SPEC §§3.4–4.
- Rebind's visual direction (user decision 2026-10-12) is the calm, soft, opaque-first look of the current Sketch design system: raised keycaps, soft shadows and hairlines, capsule controls and one accent. No Liquid Glass. Read DESIGN; native semantics and accessibility remain required.
- Local versioned atomic configuration; no silent overwrite of corrupt/future files. All product copy supports EN/RU/DE/FR; preserve the existing manual Language activation/reopen contract.
- No overengineering: prefer the simplest working solution; keep code understandable and readable.
- Prefer an existing, maintained library, system API or add-on over a custom implementation whenever it satisfies the need; write custom code only when no suitable ready solution exists.
- No hacks or workarounds: fix the actual cause or record the limitation explicitly; do not mask symptoms.
- Research non-trivial capture/action mechanisms before adding custom implementations. Check native APIs, GitHub, Swift Package Index, maintenance and licensing. Read [research](docs/research/README.md); record refreshed decisions in the affected task/register. Report unavailable research access honestly. No blind dependency installs or copying GPL sources without an explicit licensing decision.
- Sketch screens are drawn in English only; RU/DE/FR are translated and verified in the app. Sketch icons are SF Symbols exported with `tools/sf-symbol-svg.swift` and named after the symbol used in code.
- Preserve user changes. Coordinate ownership before editing the same code, catalog, docs section or Sketch source. Never stage/commit/reset/push unrelated work. Git commits and Sketch saves are separate operations; record both when actually performed.
- Write repository documentation, instructions, comments and skill content in English. Reply to the user in their preferred language. Preserve the app's EN/RU/DE/FR translations and purposeful Unicode/localization test data.
- Commit technical outcomes and concise verification results, not chat transcripts, verbatim user replies, personal paths, actual user configuration or temporary logs. Verification screenshots/exports stay local by default; version images only for a specific documented purpose under WORKFLOW. Summarize reported results with their evidence limits.
- Follow the project's commented `.gitignore` policy. Keep shared instructions/skills, STATE/tasks/evidence, source/design inputs and lockfiles versioned. New tools/output paths need narrow exclusions checked with Git; never hide an entire agent directory or automatically untrack files.
- This workflow does not authorize creating agents/chats, sending messages to other chats, executing remappings, changing real rules/permissions, editing Sketch, publishing or deploying. Proceed within the user's authorized scope without adding routine confirmation gates.

An explicit request to continue/create design authorizes scoped edits to the established Rebind design within existing requirements; resolve its source/frames from DESIGN and live MCP. Setup/instructions alone do not authorize those edits. Request a document/frame only when it cannot be resolved or is genuinely ambiguous, not because the user omitted IDs.

## 4. Finish or hand off

Follow WORKFLOW's completion contract **before the final response**. Update the affected task/evidence, STATE, and any changed SPEC/DESIGN/PLAN/capability/research record. Record tests/builds actually run, exact evidence, unresolved checks and one actionable next step. Use `awaiting_verification` when implementation exists but required runtime/hardware acceptance is open; never mark the whole feature done just because the build passes.

For design-only work, make the saved Sketch document self-contained and review it live. Keep repository completion notes short: source/date, ready scope, remaining work and next step. Do not routinely export PNGs, duplicate frame/style inventories or write a separate visual implementation manual. The implementation agent opens Sketch through MCP and inspects the current components, states and annotations directly. Keep behavioral requirements and concise native test/runtime results in the repository; apply WORKFLOW's image policy to both Sketch and native checks.

Tell the user the outcome in plain language: what is ready, what is still open, and what this role or the receiving role can do next. Lead with meaningful task names; IDs/links are optional references. If another role is needed, provide a short natural-language request that works without a task ID. The next agent must discover the handoff in project records.

Keep STATE around 1–2 pages, PLAN a short roadmap, and AGENTS practical. Retain useful technical history and link to it; do not grow a mandatory session transcript. No requirement to edit every document on every task. Documentation-only work needs review of affected links, facts and `git diff --check`, not a new checker framework or an app launch/hardware test.

## 5. Relevant skills

Read only relevant `.agents/skills/<name>/SKILL.md` and its required references. Provenance/licenses/review notes: `.agents/skills/manifest.json`; review policy and macOS overrides: ENGINEERING.

- Ordinary SwiftUI/UI work: `swiftui-pro` + `swiftui-design-principles`.
- Concurrency/callback ownership: `swift-concurrency-pro`; behavioral Swift Testing: `swift-testing-pro`.
- New Swift contracts: `swift-api-design-guidelines-skill` locally, without mass renaming.
- System materials (sidebar/menu only): `swiftui-liquid-glass` when a system material is genuinely needed; check **macOS**, not iOS, availability. Do not add glass to controls or content.
- Product copy: `writing-for-interfaces`, preserving behavior and all four languages.
- Accessibility: `swiftui-accessibility-auditor` / `appkit-accessibility-auditor` for the affected controls.
- Component guidance: `swiftui-ui-patterns` selectively; `swiftui-performance-audit` for measured rendering problems, separate from input-path profiling.
- Workflow setup/review/export: `agent-workflow-setup`; it configures project context rather than activating on ordinary feature implementation.

The original conventions were inspired by Paul Hudson's SwiftAgents and the Swift Agent Skills directory, adapted for macOS and global input. Rebind's SPEC, DESIGN, actual toolchain and synchronous callback contracts take precedence over upstream iOS/widget examples.
