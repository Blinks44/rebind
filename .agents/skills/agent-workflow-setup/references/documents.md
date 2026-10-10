# Document contracts

Use these content responsibilities to create or improve real documents. Map equivalent existing files instead of generating all these names. No empty bureaucracy: each added file must own information needed by the project.

## Language and repository boundary

Shared setup output is commit-ready by default. Write repository documentation, agent instructions, comments and skills in English unless an explicit project requirement says otherwise. Reply in the user's preferred language; this does not determine document language. Preserve product translations and intentional non-English test data.

Commit stable requirements/design/engineering contracts, concise current state/task records, significant decisions and technical verification summaries. Keep raw chat/tool transcripts, verbatim replies, personal absolute paths, real user configuration, temporary logs and migration backups out of shared documents. Use existing ignored local storage for genuinely local material, or add a narrowly scoped ignore rule when needed. Do not hide shared state/tasks from Git; another clone must be able to continue from committed records.

A reported result is evidence, not a quotation. Record it neutrally:

```text
Manual test report — date
Configuration: known device/OS/build/trigger; unknown fields explicitly stated
Result: specific requested behavior reported successful or failed
Evidence source: tester report; distinguish screenshots or agent observation
Limits: cases not covered, missing measurements and remaining acceptance
```

Do not replace a vague confirmation with a stronger claim than it supports. Successful reporting closes only the stated check, not every reliability/platform gate. Update the technical result without publishing the original reply or personal conversation details.

Keep design acceptance separate from runtime evidence: record the accepted design scope/version only when supplied. An unknown build or condition remains unknown. Shared state/tasks/evidence stay versioned; if committing is requested, review the exact staged diff. Ignore rules do not remove private material already tracked in Git.

## Entry point — AGENTS.md

Keep the mandatory entry point practical, usually a few KiB. Include:

- Project identity, detected stack/platform and immutable constraints with reasons.
- Startup/continuation: read current state and affected task, inspect actual implementation/diff, route further reading by task.
- Instruction updates: already-open chats re-read changed instructions and reconcile their task without restarting it; new chats read the entry point from disk.
- Document-role mapping and discrepancy rule: requirements say what is wanted; source/artifacts show implementation; named checks support claims.
- Exact existing build/test/lint commands and contextual verification; link detailed setup.
- Design source routing for visual work and relevant skill routing with platform overrides.
- Shared-file ownership, preservation of unrelated work and separately versioned code/design handoffs.
- Completion: actual checks, affected records and next step; `done` requires bounded acceptance.

Use module-local instructions for genuinely different commands or constraints. Do not duplicate large manuals, force full product orientation for a typo, or assume all agent clients auto-read arbitrary docs. Preserve meaningful existing security/license/concurrency rules while moving detail out of startup.

## Root README.md

Write for a repository visitor: product/use case, honest availability, useful implemented features, requirements, installation or source build, first run/basic usage, how it works and data handling, stack and documentation/contribution links. Use actual commands and artifacts. Show screenshots/assets only if representative and available.

Keep internal session logs, owner tables, test counts and agent prompts out of the root page. Link detailed development/limitations instead. Include release/download/license claims only when they actually exist; do not grant a software license while organizing docs. Distinguish the target OS from runtime compatibility tested on it.

## Current state — docs/STATE.md or equivalent

Keep a short index (roughly 1–2 pages as guidance):

- Updated date and inspected baseline/revision; uncommitted work explicitly noted.
- What exists, with meaningful implementation/verification limits and links to owners/evidence.
- A handful of recent changes; older outcomes in history.
- Current/open task links, stages, owners, dependencies and concrete next actions.
- Recommended next actionable slice and a fallback if the first needs unavailable access.

No full capability matrix or transcript. Update affected facts after substantive work. Treat state as a dated navigation aid and always compare it with actual artifacts. A newer timestamp alone is not stronger evidence.

## Product requirements and plan

SPEC owns user outcomes, scope/non-goals, behavior, constraints and observable acceptance. Reuse stable acceptance IDs where they exist; inventing numbering for every sentence is unnecessary. Distinguish approved requirements, proposed alternatives and genuinely withdrawn scope.

PLAN owns priorities/dependencies and remaining phase/milestone gates. A milestone checkbox describes a precise result, never “phase complete” because one build passed. Store execution details in tasks/evidence; no growing daily logs. Current state points to the plan rather than duplicating the backlog.

## Design contract — docs/DESIGN.md when relevant

Record the actual platform/brand direction, hierarchy, design system/tokens/components, source locations and version lookup, screen/surface index, delivery status and meaningful accessibility/responsive/localization states. Use relevant platform semantics. Do not prescribe macOS Liquid Glass to a website or copy a generic mobile density into a desktop app.

Document code ↔ design differences, reusable components, asset delivery roles and how agents obtain/save/version sources. A live document outside Git has its own saved revision; a screenshot is scoped evidence. Proposed designs, accepted design direction, integrated code and rendered verification have separate states.

## Task and evidence contract

One task tracks a bounded outcome across sessions/agents. Minimum useful fields:

```text
ID / outcome / updated
stage: planned | in_design | ready_for_implementation | implementing |
       awaiting_verification | done | blocked | cancelled
owner / scope / ownership checked / released or transferred
requirements and current behavior / dependencies
code baseline and actual implementation revision, or uncommitted files
acceptance: observable result and required checks
design handoff, if relevant: source/version/IDs/components/states/copy
implementation: changed artifacts and significant decisions
verification: actual commands/results, tested revision/environment, evidence
review: findings resolved or left open on the final artifact
open checks/blockers: reason and how to unblock
next: one action and required access/owner/version
```

Task stages are independent of capability labels such as implemented/experimental/hardware-verified. Skip inapplicable stages. `blocked` records a dependency; `done` requires the task's bounded acceptance, not general release readiness. If checks apply to an older artifact, keep the changed surface unverified.

Do not fill fields with invented IDs, commits or tests. Record whether evidence is agent-observed, user-reported, software-injected or historical. Summarize meaningful logs in durable records; a temporary path is not the only handoff. A tiny isolated edit can use a concise outcome/evidence note without a new task.

## Developer/engineering, decisions and history

Developer docs own detailed environment/build/test/signing instructions. Engineering docs own architecture boundaries and applicable concurrency/security/storage/testing conventions; link authoritative sources for unstable API claims. Avoid overlapping CODE.md and ENGINEERING.md copies.

Record consequential decisions with context, alternatives, choice, compatibility/license implications, evidence and reopening trigger. An existing ADR system or focused task section can own these; a new directory is not required.

History owns short dated technical outcomes/rationale/evidence links, without conversation excerpts. Prefer existing Git history and concise records over full copied session snapshots. Keep raw migration backups local and ignored; if a technical archive is genuinely useful, sanitize it for publication and exclude it from normal startup. Record current withdrawn/superseded decisions in current docs, not only archives.

The workflow document owns operational details: freshness, selecting an authorized next task, design-code iteration, ownership/synchronization, interruption recovery, checks/review and completion. Include short new-chat prompts; prefer “continue the project; reconstruct state and choose the next useful slice” over requiring the user to remember a prior agent's plan.
