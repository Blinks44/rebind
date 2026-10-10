# Rebind — shared development workflow

Updated 2026-10-10. Applies to the human-directed code and Sketch agents. [AGENTS](../AGENTS.md) is the mandatory entry point; this document defines durable context and handoff. It does not create agents, send messages, change permissions or start the remapping engine automatically.

## Document responsibilities

| File/source | Maintained content | Read when |
| --- | --- | --- |
| AGENTS | Startup, boundaries, routing, completion contract | Every new task/session |
| Root README / DEVELOPMENT | Public introduction, basic setup / detailed developer commands and local behavior | Public docs/setup changes; do not put session logs or agent instructions in the root README |
| STATE | Current summary, recent meaningful changes, open/next task index | Every task/resume and dependent handoff |
| SPEC | Required behavior and acceptance; change only when requirements change | Product orientation and affected sections |
| DESIGN + live Sketch | Visual direction, document/frame/component index and design delivery status | UI/brand/design tasks |
| ENGINEERING | Platform, Swift, input, security, dependency and skill conventions | App implementation/review |
| PLAN | Phase goals and remaining exit gates | Select/align a slice, update phase evidence |
| tasks | One outcome's scope, ownership, design/code/evidence and next step | Work spans agents/sessions or is substantial |
| CAPABILITIES | Detailed real capability evidence and limits | Changing/advertising a capability |
| research | Mechanism/dependency decisions, sources and licenses | Non-trivial engine/actions/dependency work |
| verification | Detailed behavior checks and durable evidence | Run/document relevant acceptance |
| history | Short dated technical outcomes, reasons and earlier evidence | Need rationale or prior results |

Do not duplicate a decision's full text in multiple files. Link to its owning record. Chat history and tool memories are supplementary. A requirement, design example, old unchecked box, screenshot or test count does not establish current implementation/support.

## Repository content and language

Repository documents, agent instructions, comments and skills use English; conversational replies follow the user's preferred language. Product translations and purposeful Unicode/localization fixtures remain multilingual.

Commit stable requirements/design/engineering contracts, a concise current-state/task index, consequential decisions and reproducible technical verification summaries. For reported hardware results, record date, tested configuration, observed outcome and remaining limits; do not copy the person's reply. For example: “Manual test report, 2026-10-08: Option + Button 4 + leftward movement triggered Command+A in TextEdit on G603 LIGHTSPEED. Other directions and cancellation remain unverified.”

Keep raw chat/tool transcripts, migration backups, personal absolute paths, actual rules/configurations and temporary logs out of commits. Optional workstation-only material can live in ignored `.local/agent-context/`; published docs must not depend on it. Use portable design names/share links and freshly resolved IDs. Build products, DerivedData and result bundles remain ignored. Before publishing screenshots, check that they show only suitable test content.

A confirmation records only the result it supports: “Tester reported the configured binding working; timing and recovery checks remain open.” Design acceptance records the accepted scope/version separately from runtime verification. If the tested build or conditions are unknown, say so; a vague confirmation does not close broader acceptance. Shared STATE/tasks/evidence remain versioned. If committing is requested, review the exact staged diff; an ignore rule does not remove previously tracked private content.

## Start, resume and establish freshness

1. Read AGENTS and STATE from the current checkout, not a remembered copy. Read this workflow on first use or when it changes; refresh relevant sections after compaction.
2. Inspect `git status --short`, branch/HEAD and relevant recent history/diff. Read the affected code/assets and task record. Preserve existing uncommitted work; do not commit other agents' files as part of yours.
3. Locate SPEC sections/acceptance IDs and PLAN phase. Check actual implementation before deciding a feature is missing. If requirements changed, reconcile SPEC in the authorized scope.
4. For UI, resolve the current Sketch document from DESIGN's path/name and the user's target. Stored document IDs are lookup hints and can change after save/reopen. Load MCP guides, refresh the live ID, inspect frame trees/styles/screenshots and reuse existing components. Verify referenced IDs; do not trust an old export as today's design.
5. Identify a small outcome, owner, files/Sketch sources and required checks. Reuse an existing task ID; otherwise create a focused record from [the template](tasks/TEMPLATE.md). A tiny isolated fix needs only a short evidence/history entry. Task creation is bookkeeping, not permission to expand scope.
6. Share a brief context update: existing implementation/design, relevant limitation, selected task and next action. Do useful authorized work; ask only for missing information that materially blocks it.

A new chat is a useful task boundary, not a requirement after every small edit. Keep one coherent feature's implementation, debugging and verification together. Before moving chats, save a handoff even if the task is unfinished. A new agent should reconstruct the next step without reading the previous transcript.

### Already-open chats after workflow changes

Read the updated AGENTS and affected workflow/contracts from disk, refresh STATE and the current task, and reconcile them with the actual diff. Preserve that task's work and ownership; updating instructions is not a reason to restart implementation or run workflow setup again. Report any material conflict and continue the authorized task under the updated rules. Repeat this refresh after a relevant handoff from another agent.

### When the request is simply “continue the app”

Reconcile STATE's next-task index with PLAN, existing tasks and actual artifacts. Resume an owned unfinished slice if ownership is current and compatible with this chat; otherwise choose the highest-priority actionable slice of the existing scope. Prefer a known regression/core acceptance gap before unrelated polish. Summarize what already exists, why this slice is next and what will count as success, then proceed without asking the user to reconstruct the previous chat.

If the first item requires unavailable hardware, credentials, a design source or user interaction, leave its acceptance open and choose independent useful work from the remaining priorities. Ask only when the missing answer changes scope or blocks all useful progress. A saved next step is guidance, not authorization to change product direction, publish, send messages or alter real user settings.

### Interrupted sessions and uncertain records

Save the smallest usable handoff when an interruption is foreseeable: last verified state, unfinished files/design edits, failed check, ownership and next action. An abrupt termination may prevent this; the next agent must inspect the actual diff/artifacts instead of assuming the last final message or STATE is current. Keep incomplete edits distinct from verified results. Do not discard a partial implementation or restart it merely because its task still says `planned`.

## Task status and capability status are different

Task stages: `planned`, `in_design`, `ready_for_implementation`, `implementing`, `awaiting_verification`, `done`, `blocked`, `cancelled`. Use the stages that apply; engine-only work skips design. `blocked` records a concrete dependency and a way to unblock, not vague uncertainty.

Also record design, implementation and verification separately. For example: design saved/reviewed; implementation integrated; software checks pass; hardware pending. `done` means the **task's explicitly bounded acceptance** is met. A completed asset-export task does not close the product's Dock/runtime gate. Hardware capability labels follow SPEC §13, independently of task stages.

Record user acceptance only if actually supplied. Do not invent approval or impose an approval meeting on every design task. New alternatives should be distinguished from the agreed/current direction; ask when selecting between them changes the requested outcome. A saved design is not native UI implementation.

## Code + design loop

1. The task states user outcome, relevant requirements, current behavior and acceptance.
2. Design work inspects the current app/capability limits and Sketch. It covers applicable empty/loading/error/disabled/conflict/permission/appearance states and copy. Prototype examples must not advertise unsupported triggers/actions as implemented.
3. The design handoff records saved document path or share link, freshly resolved document ID, stable frame/source IDs, saved revision/time or digest when available, reusable styles/components, behavior/copy and remaining questions. Record screenshots/exports as evidence, with date and scope; the live document remains the visual source.
4. The implementation agent refreshes that handoff and live frames. It reuses current state/persistence/engine and implements the bounded slice. Record justified platform differences instead of silently approximating or inventing functionality.
5. Run relevant software and native visual/accessibility checks, then hardware/permission checks when required and authorized. Review against the handed-off design; record differences and remaining gates. Neither a Sketch screenshot nor an Xcode build proves runtime effects.
6. Complete the records below and hand off the specific next action. If design changes after implementation starts, note changed frame IDs/revision and which implemented surfaces require reconciliation.

## Concurrent work and synchronization

- Assign one owner per shared file/section and Sketch source before editing. STATE's open-task table plus task `Owner` / `Owned surfaces` fields are the coordination record. An owner is a chat/agent identifier when known, not an invented person.
- Parallel work should use separate files and bounded Sketch targets. Shared styles affect every instance: explicitly include that impact in ownership. For overlapping work, coordinate or proceed on independent surfaces first.
- Before updating a shared doc, re-read it and merge only your section; do not overwrite another task's new status with a stale whole-file copy. An owner claim may be stale: inspect the latest record and clarify an actual conflict; do not silently take over live edits.
- Markdown owner fields are advisory coordination, not atomic locks. Check activity when possible and record ownership time/revision and release/transfer. If ownership is uncertain, use independent surfaces or coordinate; do not infer that an old date alone permits takeover. Separate worktrees isolate code, but their task boards also diverge until explicitly integrated. Choose one shared coordination location when parallel work is used; Git alone is not a live lock service.
- Both agents need access to these project docs. If the Sketch agent has only MCP, supply the startup documents and task handoff and arrange for its result to be written back; it cannot read inaccessible files automatically. Shared filesystem access does not mean shared in-memory context.
- Separate clones/worktrees see different revisions until synchronized. Record the task's branch/base commit, current implementation commit when actually made, and whether work is still uncommitted. Transfer intended changes through normal Git review/integration before the dependent agent starts. Never reset a checkout or auto-commit all changes to make synchronization easy.
- Sketch outside Git needs its own saved document/version and backups. A Git commit does not save a Sketch edit. Code and design references should identify the same handoff version; refresh before dependent work, not merely once at chat creation.

## Verification and completion contract

Before the final answer or interruption handoff:

1. Update the task with actual deliverables, artifact/revision references, checks run, failures/limits and a concrete next step. Keep `awaiting_verification` if required acceptance remains open.
2. Save detailed behavior/build/hardware evidence in the relevant verification file when useful. Date it; specify tested code/design revision, OS/device/permissions, exact commands and result. Say whether a result is user-reported, agent-observed or an injected test. `/tmp` logs may expire: retain the meaningful result in the repo, and never make a temporary path the only handoff evidence.
3. Update STATE's affected facts, recent changes and task rows. Keep roughly 1–2 pages, preferably under 8 KiB. Retain only a handful of recent meaningful changes; move old detail to history. Do not repeat the full capability matrix or daily tool transcript.
4. Update SPEC only for changed requirements; DESIGN only for changed direction/index/delivery; PLAN only for phase gates/priorities; CAPABILITIES only for changed supported behavior/evidence; research only for a relevant decision. No requirement to touch every file.
5. Add a concise dated history entry for substantive work: outcome, reason, task/evidence link, unresolved acceptance. If the task already contains detail, link rather than duplicating. Never relabel an old verification as a new run.
6. Check links/status consistency and `git diff --check`. Build after app code changes; run meaningful behavioral tests for changed logic. Docs-only work needs document verification; asset-only work needs the relevant asset/build checks. Do not launch input interception or execute configured actions merely to validate documentation.
7. Report what changed, what was checked, limitations and the next planned item. Documentation/handoff is part of completion, not an optional promise for later.

Review the final diff against acceptance, capability limits and the affected design states. Fix actionable findings or leave them explicitly open. Relevant checks must describe the final changed artifact: later code/design changes invalidate affected earlier evidence until checked again. Identify an actual commit when one exists; for uncommitted work record the baseline plus changed files and, where reproducibility needs it, an artifact digest. Do not invent a commit to fill a field. A design saved after native review requires reconciliation of the affected native surfaces.

Task `done` does not mean the app is ready for distribution. Product readiness still requires SPEC §15 and PLAN's remaining reliability/hardware/accessibility/localization/signing/minimum-OS gates, on identified artifacts. Workflow setup cannot certify product readiness.

Do not append sessions to PLAN. New entries go into `history/YYYY-MM.md`; new complex decisions stay in the affected task or a focused research document. Historical evidence may contain superseded decisions; current contracts identify the applicable scope.

### Documentation review

Review affected links, task/STATE/PLAN consistency and claims against source/evidence, then run `git diff --check`. Use an existing documentation check when the project already has one. Workflow setup adds no runtime, package, custom validator, CI job or test framework solely for Markdown bookkeeping.

## How the user starts the next chat

If you do not know the previous next step, this is sufficient:

> Continue work on Rebind. Restore context from AGENTS.md, inspect the current implementation and choose the next useful unfinished slice. Explain the choice, proceed within scope, and save the outcome and next step in the project.

Open the **same project** with the intended checkout and give the outcome, task ID if continuing, and constraints. It is not necessary to paste the specification or recite yesterday's work. A sufficient prompt:

> Continue Rebind following AGENTS.md. Refresh context from docs/STATE.md and task UI-001. Complete its next actionable step, preserve current constraints and update the handoff before finishing.

For a new feature:

> Rebind needs [user outcome]. Follow AGENTS.md, inspect current implementation and create a task record when useful. Acceptance: [observable result].

For design:

> Continue Rebind design following AGENTS.md and docs/DESIGN.md: [screen/flow]. Use the current Rebind.sketch and existing components. Save the design and implementation handoff with frame IDs, states and unresolved questions.

For an unfinished chat:

> Save the task's current state and one concrete next action in the project so a new chat can continue it.

For an already-open chat after instructions change:

> Re-read the updated AGENTS.md and affected workflow documents from disk, refresh STATE and the current task, reconcile existing edits, and continue that task under the updated rules. Keep shared records in English.

Use the setup skill to configure or audit a workflow, not for every product task. Normal feature/design requests use AGENTS and the relevant task; the agent selects applicable engineering/design skills.

## Reusing the workflow elsewhere

The document responsibilities, freshness checks, task/evidence status and handoff pattern apply to iOS, web, backend and other projects. Adapt ENGINEERING, commands, acceptance and DESIGN to each platform; do not copy Rebind's macOS/permission/input rules. Backend-only work can omit DESIGN or link its API contract instead. Shared API/schema contracts and deployment environment/revision become important evidence for frontend/backend work. Add architecture/decision docs only when they explain real contracts; no mandatory collection of empty files.

Official background: [AGENTS discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [practical Codex guidance](https://learn.chatgpt.com/guides/best-practices). AGENTS is the entry point; arbitrary STATE/DESIGN files need these explicit reading instructions. This workflow supports fresh chats without claiming automatic cross-chat synchronization.
