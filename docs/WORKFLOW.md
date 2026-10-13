# Rebind: shared development workflow

Updated 2026-10-11. Applies to the human-directed code and Sketch agents. [AGENTS](../AGENTS.md) is the mandatory entry point; this document defines durable context and continuation. It does not create agents, send messages, change permissions or start the remapping engine automatically.

## Document responsibilities

| File/source | Maintained content | Read when |
| --- | --- | --- |
| AGENTS | Startup, boundaries, routing, completion contract | Every new task/session |
| Root README / DEVELOPMENT | Public introduction, basic setup / detailed developer commands and local behavior | Public docs/setup changes; do not put session logs or agent instructions in the root README |
| STATE | Current summary, recent meaningful changes, open/next task index | Every task/resume and dependent handoff |
| SPEC | Required behavior and acceptance; change only when requirements change | Product orientation and affected sections |
| DESIGN + live Sketch | Short direction/source locator and readiness; Sketch owns visual states, components, copy and annotations | UI/brand/design tasks |
| ENGINEERING | Platform, Swift, input, security, dependency and skill conventions | App implementation/review |
| PLAN | Phase goals and remaining exit gates | Select/align a slice, update phase evidence |
| tasks | One outcome's scope, ownership, design/code/evidence and next step | Work spans agents/sessions or is substantial |
| CAPABILITIES | Detailed real capability evidence and limits | Changing/advertising a capability |
| research | Mechanism/dependency decisions, sources and licenses | Non-trivial engine/actions/dependency work |
| verification | Concise technical check results, limits and justified durable evidence | Run/document relevant acceptance |
| history | Short dated technical outcomes, reasons and earlier evidence | Need rationale or prior results |

Do not duplicate a decision's full text in multiple files. Link to its owning record. Chat history and tool memories are supplementary. A requirement, design example, old unchecked box, screenshot or test count does not establish current implementation/support.

## Repository content and language

Repository documents, agent instructions, comments and skills use English; conversational replies follow the user's preferred language. Product translations and purposeful Unicode/localization fixtures remain multilingual.

Commit stable requirements/design/engineering contracts, a concise current-state/task index, consequential decisions and reproducible technical verification summaries. For reported hardware results, record date, tested configuration, observed outcome and remaining limits; do not copy the person's reply. For example: “Manual test report, 2026-10-08: Option + Button 4 + leftward movement triggered Command+A in TextEdit on G603 LIGHTSPEED. Other directions and cancellation remain unverified.”

Keep raw chat/tool transcripts, migration backups, personal absolute paths, actual rules/configurations and temporary logs out of commits. Workstation-only material belongs in temporary storage outside the repository; published docs must not depend on it. Use portable design names/share links and freshly resolved IDs. Build products, DerivedData and result bundles remain ignored. Before publishing screenshots, check that they show only suitable test content.

Verification screenshots and exports from Sketch, the native app or other tools stay in temporary storage outside the repository by default. A visual check does not require exporting or retaining an image. Git keeps concise results identifying the tested artifact/environment, checks, observed outcome and limits; these records must be useful without local screenshots. Version an image only for a concrete purpose: a requested deliverable, shipped asset, baseline consumed by a visual test, or specific defect evidence that a written result cannot adequately preserve. Record that purpose in the owning task/evidence note; a routine native regression check alone is not a reason. Preserve existing assets/baselines; policy adoption does not automatically delete or untrack existing files. Do not blanket-ignore image extensions.

A confirmation records only the result it supports: “Tester reported the configured binding working; timing and recovery checks remain open.” Design acceptance records the accepted scope/version separately from runtime verification. If the tested build or conditions are unknown, say so; a vague confirmation does not close broader acceptance. Shared STATE/tasks/evidence remain versioned. If committing is requested, review the exact staged diff; an ignore rule does not remove previously tracked private content.

The commented root `.gitignore` owns shared exclusion policy for Rebind's actual Xcode/SPM, editor and local-agent output. When introducing tools or output paths, inspect existing/nested rules and preserve source, shared configuration, lockfiles, design assets, concise verification records and specifically justified evidence. Test excluded and kept paths with `git check-ignore -v --no-index`; inspect `git ls-files --cached --ignored --exclude-standard` for tracked-rule conflicts. Do not exclude entire client directories or untrack files automatically. The reusable skill's [repository hygiene guide](../.agents/skills/agent-workflow-setup/references/repository-hygiene.md) details adaptation to other projects.

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

### Short requests and role-aware task selection

Interpret the intended action/outcome and established context in the user's language; example prompts are illustrations, not a command vocabulary. Tool or programming-language mentions constrain relevant sources/implementation, not the role by themselves: reading a design for implementation differs from editing it. They do not authorize installing tools or migrating the stack. Finding records, choosing IDs, reading contracts and maintaining status are the agent's responsibility. Match natural-language outcomes to task titles, requirements and actual artifacts; do not ask for an ID or old transcript when the project can answer the question.

1. Resolve role and scope from the latest request and this chat's established work. “Continue the task” resumes this chat's current outcome before choosing another. A design request stays within design; a code agent handles implementation/engineering. A fresh unqualified Rebind development request defaults to implementation. If two plausible roles/outcomes remain materially different, ask one focused question using human-readable names, while doing independent useful inspection.
2. Reconcile STATE/PLAN/task evidence and actual artifacts. Resume the current compatible unfinished slice if ownership is available; otherwise select the highest-priority actionable slice for that role. For code, prioritize core regressions/verification and ready implementation handoffs. For design, prioritize missing designs/states that unblock implementation. A hardware gate at the top of PLAN does not become a design task. Use STATE's role recommendations as dated hints, never unconditional commands.
3. Refresh a dependent handoff before implementation. Only its ready bounded scope is eligible; a task may contain saved initial frames plus unfinished design and code. Keep missing design/verification visible. A dedicated code agent can continue independent engineering; it changes role only when the user's request or established scope authorizes it.
4. Announce the chosen outcome, existing result, next action and bounded success in a few sentences, then work. Do not stop for routine approval of a next step already within the request. Continue until that bounded outcome/check/handoff is complete or requires unavailable access; a plain “continue” does not authorize working through the entire roadmap indefinitely.

If the first item requires unavailable hardware, credentials, a design source or user interaction, leave its acceptance open and choose independent useful work from the remaining priorities. Ask only when the missing answer changes scope or blocks all useful progress. A saved next step is guidance, not authorization to change product direction, publish, send messages or alter real user settings.

When blocked, say which outcome is waiting, exactly what is needed and what useful independent work remains. If nothing is actionable for this role, report that fact and the next receiving role/access requirement; do not invent polish or recreate a completed asset merely to keep busy. Active ownership conflicts still require coordination, not an automatic takeover.

### A named feature or change

“Let's build [feature]” selects that outcome ahead of the default next item. Check existing implementation/design and reuse a matching record; create a concise task only when useful. Derive observable acceptance and a sensible first slice from the request and current contracts, state the interpretation and proceed. Ask about materially missing behavior/product choices, not bookkeeping. Update affected requirements/priorities when the request changes them; distinguish proposed extensions from requested behavior. A design agent produces its design scope and implementation handoff; a code agent implements an existing ready contract or surfaces the precise design dependency while advancing independent prerequisites. Both agents can use the same outcome name without the user assigning IDs.

### Interrupted sessions and uncertain records

Save the smallest usable handoff when an interruption is foreseeable: last verified state, unfinished files/design edits, failed check, ownership and next action. An abrupt termination may prevent this; the next agent must inspect the actual diff/artifacts instead of assuming the last final message or STATE is current. Keep incomplete edits distinct from verified results. Do not discard a partial implementation or restart it merely because its task still says `planned`.

## Task status and capability status are different

Task stages: `planned`, `in_design`, `ready_for_implementation`, `implementing`, `awaiting_verification`, `done`, `blocked`, `cancelled`. Use the stages that apply; engine-only work skips design. `blocked` records a concrete dependency and a way to unblock, not vague uncertainty.

Also record design, implementation and verification separately. For example: design saved/reviewed; implementation integrated; software checks pass; hardware pending. `done` means the **task's explicitly bounded acceptance** is met. A completed asset-export task does not close the product's Dock/runtime gate. Hardware capability labels follow SPEC §13, independently of task stages.

Record user acceptance only if actually supplied. Do not invent approval or impose an approval meeting on every design task. New alternatives should be distinguished from the agreed/current direction; ask when selecting between them changes the requested outcome. A saved design is not native UI implementation.

## Code + design loop

1. The task states user outcome, relevant requirements, current behavior and acceptance.
2. Design work inspects the current app/capability limits and Sketch. It covers applicable empty/loading/error/disabled/conflict/permission/appearance states and copy. Prototype examples must not advertise unsupported triggers/actions as implemented.
3. Make the saved Sketch source self-contained: reusable components, applicable states, product copy and interaction/native-control annotations belong beside the frames. Review changes using live MCP screenshots. Keep only a short repository note naming the source/date, ready scope, limits and next step. Routine PNG exports, mirrored frame/style inventories and separate visual implementation manuals are not required. Apply the repository image policy above to any exports.
4. The implementation agent opens the current Sketch source through MCP and inspects its frames, components and annotations directly, even when a repository summary exists. It reuses current state/persistence/engine and implements the bounded slice. Record justified platform differences and behavior/test evidence; keep SPEC authoritative for required behavior.
5. Run relevant software and native visual/accessibility checks, then hardware/permission checks when required and authorized. Review against the handed-off design; record differences and remaining gates. Neither a Sketch screenshot nor an Xcode build proves runtime effects.
6. Complete the short status records below. If design changes after implementation starts, identify the affected surfaces/date and what needs reconciliation; there is no separate design-transfer ceremony.

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
2. Save concise behavior/build/hardware results in the relevant task or verification file. Date them; specify tested revision, relevant OS/device/permissions, exact commands and result. Say whether a result is user-reported, agent-observed or an injected test. For design-only work, a saved/reviewed Sketch source and concise task note are sufficient; do not create a parallel visual specification or persist every MCP screenshot. Local logs/images may expire: retain meaningful results and limits in the repo, applying the image policy above rather than routinely committing screenshots.
3. Update STATE's affected facts, recent changes and task rows. Keep roughly 1–2 pages, preferably under 8 KiB. Retain only a handful of recent meaningful changes; move old detail to history. Do not repeat the full capability matrix or daily tool transcript.
4. Update SPEC only for changed requirements; DESIGN only for changed direction/index/delivery; PLAN only for phase gates/priorities; CAPABILITIES only for changed supported behavior/evidence; research only for a relevant decision. No requirement to touch every file.
5. Add a concise dated history entry for substantive work: outcome, reason, task/evidence link, unresolved acceptance. If the task already contains detail, link rather than duplicating. Never relabel an old verification as a new run.
6. Check links/status consistency and `git diff --check`. Build after app code changes; run meaningful behavioral tests for changed logic. Docs-only work needs document verification; asset-only work needs the relevant asset/build checks. Do not launch input interception or execute configured actions merely to validate documentation.
7. Report the meaningful outcome name, what is ready, checks/limits and the next step for this role or receiving role. When a role transfer is needed, include a short natural-language request such as “Implement the prepared first-run and permissions design”; it must resolve from shared records without an ID. Documentation/handoff is part of completion, not an optional promise for later. The user should not have to ask where the work stopped.

Review the final diff against acceptance, capability limits and the affected design states. Fix actionable findings or leave them explicitly open. Relevant checks must describe the final changed artifact: later code/design changes invalidate affected earlier evidence until checked again. Identify an actual commit when one exists; for uncommitted work record the baseline plus changed files and, where reproducibility needs it, an artifact digest. Do not invent a commit to fill a field. A design saved after native review requires reconciliation of the affected native surfaces.

Task `done` does not mean the app is ready for distribution. Product readiness still requires SPEC §15 and PLAN's remaining reliability/hardware/accessibility/localization/signing/minimum-OS gates, on identified artifacts. Workflow setup cannot certify product readiness.

Do not append sessions to PLAN. New entries go into `history/YYYY-MM.md`; new complex decisions stay in the affected task or a focused research document. Historical evidence may contain superseded decisions; current contracts identify the applicable scope.

### Documentation review

Review affected links, task/STATE/PLAN consistency and claims against source/evidence, then run `git diff --check`. Use an existing documentation check when the project already has one. Workflow setup adds no runtime, package, custom validator, CI job or test framework solely for Markdown bookkeeping.

## Requests the user can give

Open the same project/intended checkout. These are example short requests; equivalent wording in the user's language works through the same intent/context rules. The agent performs the reading, task lookup and record updates:

| Intent | Sufficient request |
| --- | --- |
| Continue implementation | “Continue development.” |
| Continue design | “Continue creating the design.” |
| Resume this chat's task | “Continue the task.” |
| Select a feature | “Let's add [user-visible feature/behavior].” |
| Consume a saved design | “Implement the prepared first-run and permissions design.” |
| Ask for status | “What is ready, what is open, and what will you do next?” |

Task IDs/paths, acceptance details and constraints can help when the user has them; they are optional for continuing existing work. In a fresh chat, name a specific outcome only when intentionally selecting it. Give observable behavior for a genuinely new feature; the agent asks only about material ambiguity.

Save work and the smallest useful continuation note before finishing; the user should not need to remind the agent. For design this means saved Sketch plus source/readiness/next-step pointers, not a second design package in Git. An optional early interruption request is “Save the current result so we can continue later.”

Existing chats that began before this workflow update should be told once: “Read the updated project instructions and continue your task.” They then use the same short requests. Use the setup skill for configuration/audit; ordinary product requests use the project entry point and relevant skills.

## Reusing the workflow elsewhere

The document responsibilities, freshness checks, task/evidence status, repository hygiene and handoff pattern apply to any development project. Derive contracts, commands, skills and verification from its actual domain, inputs, tools and delivery environment; the examples are not an eligibility list. Omit visual DESIGN when no visual contract exists, and use relevant API/data/engineering contracts instead. Do not copy Rebind's macOS/permission/input rules. Add architecture/decision docs only when they explain real contracts; no mandatory collection of empty files.

Official background: [AGENTS discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [practical Codex guidance](https://learn.chatgpt.com/guides/best-practices). AGENTS is the entry point; arbitrary STATE/DESIGN files need these explicit reading instructions. This workflow supports fresh chats without claiming automatic cross-chat synchronization.
