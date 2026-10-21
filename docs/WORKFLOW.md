# Rebind: shared development workflow

Updated 2026-10-21. [AGENTS](../AGENTS.md) is the entry point for code and design work. This workflow defines durable context, ownership and completion; it does not authorize new agents, messages, remappings, permission changes or publication.

## Document responsibilities

| Source | Owns / read when |
| --- | --- |
| AGENTS + STATE | Boundaries and current task index; every start/resume |
| Root README / DEVELOPMENT | Public overview / detailed build, signing and local setup |
| SPEC | Current requirements and acceptance; product orientation or affected contracts |
| DESIGN + live Sketch | Direction, source locator/readiness / current visual states, components, copy and annotations; UI work |
| ENGINEERING | Native input, Swift/concurrency, storage, security and skill conventions; app code |
| PLAN | Priorities and remaining release gates; selecting a slice |
| tasks | One outcome's current scope, owner, implementation, evidence and next action |
| CAPABILITIES | Actual implemented/verified subsets and limits; capability changes/claims |
| research | Mechanism choices, sources, maintenance and licensing; non-trivial mechanisms |
| verification | Dated results and reproducible walkthroughs; relevant acceptance |
| history | Short dated outcomes and rationale; optional historical lookup |

Link to the owning record instead of copying its full content. Requirements, screenshots, old checkboxes and test counts do not establish current implementation or hardware support. Inspect actual artifacts when records disagree.

## Start, resume and establish freshness

1. Read AGENTS and STATE from the current checkout. Read this workflow on first use or when changed; refresh relevant sections after compaction or a dependent handoff.
2. Inspect branch/HEAD, `git status --short`, relevant history/diff and the affected implementation/task. Preserve unrelated and uncommitted work. Locate the relevant SPEC acceptance and PLAN priority.
3. For UI, resolve the live Sketch source from DESIGN. Load its MCP guides, refresh document IDs and inspect applicable frames, shared sources, styles, annotations and screenshots. An old export is not the current design.
4. Establish a bounded outcome, owner, surfaces and required checks. Reuse a matching task; use [TEMPLATE](tasks/TEMPLATE.md) for substantial new work. A tiny isolated fix needs only concise evidence/history.
5. Explain the selected outcome, existing result and next action briefly, then complete authorized work. Ask only about material missing behavior/access.

Already-open chats adopt changed instructions by re-reading them and reconciling their existing task/diff. They do not restart work or rerun setup merely to refresh context. A new chat is optional; before a handoff save enough context for another agent to continue without the old transcript.

### Short requests and role-aware task selection

Interpret intent in the user's language and established scope. “Continue the task” resumes this chat's outcome; “continue design” stays in design. A fresh unqualified Rebind development request defaults to app implementation. Tool/language mentions identify applicable sources, not a new role or permission to migrate/install tools. Resolve task IDs, contracts and source locations yourself.

A named feature takes precedence over default priorities. Inspect related partial work, reuse its record and derive observable acceptance. Otherwise select the highest-priority actionable slice for this role: core regressions/verification or ready handoffs for code; missing designs/states for design. A task with initial frames and missing states is not wholly design-ready.

If hardware/access/ownership blocks that slice, retain the gate and advance independent work within the authorized role. If none exists, state the exact missing input and next responsible role. Ask one focused question only for a material unresolved choice. Do not recreate completed work or treat “continue” as permission to exhaust the roadmap. A saved next step does not authorize external actions.

### Interrupted sessions and uncertain records

Before an interruption, save the verified artifact, unfinished edits, failed/pending checks, ownership and next action. After an abrupt interruption, inspect the actual diff; do not assume the last note was saved or discard partial implementation because its task still says `planned`.

## Task status and capability status are different

Stages: `planned`, `in_design`, `ready_for_implementation`, `implementing`, `awaiting_verification`, `done`, `blocked`, `cancelled`. Skip inapplicable stages. `blocked` identifies a concrete dependency and how to unblock it.

Record design, implementation and verification separately. `done` requires the task's bounded acceptance on an identified final artifact. Keep `awaiting_verification` when required runtime/hardware acceptance remains open. Capability labels follow SPEC §13; distribution readiness requires SPEC §15 and PLAN's gates. Builds/mocks do not prove physical behavior. Record user acceptance only when supplied, limited to its actual scope; no routine approval ceremony is required.

## Code + design loop

The task owns outcome/acceptance. Inspect the actual app/capability limits and live Sketch before design or implementation. Cover applicable empty, loading, error, disabled, conflict, permission, appearance and recovery states without advertising unsupported behavior.

For design work, save a self-contained Sketch source with reusable components, states, copy and native interaction annotations; review it live. The repository needs source/date, ready scope, limits and next step. The implementation agent inspects that source directly, reuses state/storage/engine and records justified native differences. Do not mirror component inventories or routinely export PNGs.

Check rendered software/native behavior against the same source revision; perform hardware/permission checks only when required and authorized. Later code or design changes invalidate affected earlier evidence. Reconcile the changed surfaces before claiming parity; a Sketch save and a Git commit are separate operations.

## Concurrent work and synchronization

- Claim one owner per shared file/section and Sketch source in the task and STATE. Record scope, time/baseline and release/transfer; identifiers are advisory, not atomic locks.
- Prefer independent surfaces. Shared styles/catalogs need explicit impact ownership. Re-read shared records immediately before editing and merge only your changes. Do not infer takeover permission from an old date; coordinate an active overlap or leave it untouched.
- Both roles need project records and relevant artifacts. If a client cannot read the repository, provide the startup/handoff and establish who persists its result. Shared files do not create shared chat memory.
- Separate worktrees/clones need an explicit shared coordination location and normal Git integration. Record real baselines/implementation commits or uncommitted files; never reset or auto-commit unrelated work for synchronization.
- Sketch needs its own saved version/backup. Refresh both source and code before dependent work; session IDs are lookup hints.

## Repository content and language

Shared documentation, instructions, comments and skills use English; conversation follows the user's language. Preserve product translations and intentional Unicode fixtures.

Keep stable contracts, current state/tasks, significant decisions and concise reproducible verification. Report date, known build/OS/device/settings, observed result, evidence source and limits. Distinguish agent observation, tester report and injected tests. Unknown conditions remain unknown; a vague confirmation does not close broad acceptance.

Keep transcripts, quoted replies, personal absolute paths, real rules/configurations, migration backups and temporary logs out of commits. Use portable source names/access instructions. Screenshots/exports stay in temporary storage outside the repository by default; written results must remain useful without them. Version an image only for a documented deliverable, shipped asset, required visual-test baseline or defect evidence that text cannot preserve. Preserve existing justified assets; policy changes do not automatically delete/untrack them.

The commented `.gitignore` owns actual Xcode/SPM/editor/local-output exclusions. For new paths, inspect nested rules, test ignored and kept samples with `git check-ignore -v --no-index`, and inspect `git ls-files --cached --ignored --exclude-standard`. Keep shared context, source/design inputs and lockfiles visible. Do not blanket-ignore client directories or image extensions; do not auto-untrack files. See the skill's [hygiene reference](../.agents/skills/agent-workflow-setup/references/repository-hygiene.md).

## Incremental documentation maintenance

Ordinary completion includes maintaining the affected topic. Replace superseded requirements/current claims and completed next steps directly; do not append a chain of overrides. Keep task summaries focused on current scope, evidence links and open acceptance. History receives the short outcome/reason, not another session transcript.

Remove completed tasks from STATE's active table. Retain records owning unique decisions/evidence or a useful handoff. Retire a redundant record only after durable facts and every open check have an identified owner; repair incoming links/anchors in the same change. Old evidence is not disposable merely because it is old or the build passes. Obsolete visual inventories can be reduced to source/date and meaningful results because live Sketch owns current visuals.

Keep STATE roughly 1–2 pages (preferably under 8 KiB), PLAN a short roadmap and startup free of mandatory archives. Broader moves/merges/deletions require a scoped cleanup task; routine work does not authorize unrelated reorganization. Do not introduce a new archive hierarchy or bookkeeping framework without a concrete need.

## Verification and completion contract

Before the final answer or interruption handoff:

1. Update the affected task/evidence with the final deliverables, real revision or baseline plus uncommitted files, actual checks/failures, limits and one next action per applicable role. Keep historical tests dated; a document edit is not a rerun.
2. Update STATE's affected facts/rows and concise recent outcomes. Update SPEC for changed requirements, DESIGN for direction/source/readiness, PLAN for priorities/gates, CAPABILITIES for supported behavior/evidence and research for mechanism decisions. Touch only relevant records.
3. Add a short dated history entry for substantive work, linking detailed evidence. Apply incremental maintenance above so current handoffs describe the final result.
4. Review the final diff against acceptance, capability limits and affected design states. For new app changes, apply AGENTS' build-number rule before the final verification build: increment Debug and Release together, then record the resulting version/build. Build after app changes; run meaningful behavioral tests for changed logic and relevant asset checks. After each completed app change set, run `apps/rebind/scripts/release.sh` and require successful app/DMG signing and image verification before handoff. Report the actual version/build and DMG path for manual installation; a Debug build or `dev.sh release` alone is insufficient. Documentation-only, test-only, website-only and Sketch-only work does not require repackaging. On failure, report the blocker and do not offer an older package as current. Local packaging does not authorize installation/publication/deployment. Keep unresolved runtime/hardware/accessibility/platform gates explicit.
5. Report the meaningful outcome, what is ready/open and the next action/role. A receiving-role request such as “Verify Language selection and relaunch” must resolve from saved records without IDs or the old chat.

### Documentation review

Check affected facts against artifacts/evidence, current task/STATE/PLAN consistency, incoming local links/anchors and `git diff --check`. Use existing document tooling where available. Docs-only work does not require app launch, interception, hardware actions, a new checker, runtime, CI job or test framework.

## Requests the user can give

Ordinary requests such as “continue development”, “continue creating the design”, “continue the task”, “add [behavior]” or “implement the prepared permissions flow” use the selection rules above. IDs, source coordinates and old-chat summaries are optional. On workflow changes tell existing chats once to read updated instructions and continue their existing task.

## Reusing the workflow elsewhere

The reusable [Agent Workflow Setup](../.agents/skills/agent-workflow-setup/README.md) adapts document responsibilities and checks to another project's actual domain and tools. Do not copy Rebind's macOS/input rules or require empty documents. Use it for setup/audit/migration; ordinary product work follows AGENTS and relevant skills.
