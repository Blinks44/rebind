---
name: agent-workflow-setup
description: Set up, migrate, or audit durable agent development and design workflows in new or existing software projects, including project instructions, current state, handoffs, public documentation, and relevant skills. Use for configuring the workflow itself, rather than ordinary feature development under an existing workflow.
license: MIT
metadata:
  version: "1.0.2"
---

# Agent Workflow Setup

Configure a project so a fresh coding or design agent can identify what exists, select an authorized next step, verify its work and leave a usable handoff. Adapt to the project; do not copy the originating application's stack, visuals, paths or product requirements.

## Inspect before configuring

Read [adoption](references/adoption.md) for setup, migration or audit. Inspect existing instructions (including nested/override files), public docs, source/assets, build/test configuration, task tracker, Git changes and design sources. Establish product intent, platform/framework, delivery constraints, usable tools and evidence. Separate requirements, implementation, observed verification and unknowns.

Preserve existing user/contributor work and useful conventions. Adopt equivalent existing documents instead of creating competing sources of truth. For a new project, ask only for product/platform decisions needed to proceed; do not invent a stack or finished feature set from an empty directory. Report inaccessible code/design sources and continue independent setup.

## Build the smallest complete context system

Use [document contracts](references/documents.md) to adapt these responsibilities:

- `AGENTS.md`: short entry point, contextual reading rules, exact development commands, boundaries, verification and completion rules.
- Root `README.md`: public product introduction, availability, requirements, installation/run, stack, operation and links.
- Current state: implemented baseline, recent meaningful changes, open tasks, blockers and one concrete next action.
- Product requirements and plan: required outcomes/acceptance versus remaining priorities; no chronological session dump.
- Design contract, when applicable: direction, accessible states, canonical design source/components, versioned design-to-code handoff.
- Task/evidence records: bounded acceptance, advisory ownership, final artifact/revision, checks, review, unresolved work and next step.
- Engineering/developer guidance, decisions and history: only where the project's actual complexity warrants them.

Map roles to paths in the entry point. Keep routine startup small; route deeper documents by task. State files are read from disk, not shared chat memory. Scope specialized instructions to their module when useful. Do not make every small change update every document or read the whole repository.

All shared files created by setup must be suitable for committing. Use English for repository documentation, instructions, comments and skill content unless the project explicitly chooses another language; conversational replies follow the user's preference. Keep localized product resources and purposeful Unicode fixtures multilingual. Record technical outcomes rather than verbatim user replies or chat/tool transcripts. The repository-content boundary and reported-result format are defined in [document contracts](references/documents.md).

## Select skills and tools deliberately

Read [skill selection](references/skills.md) when inventorying/installing/updating project skills. Check existing skills first, match their actual contents to the detected stack and gaps, then review sources, licenses and executable behavior. Install a useful subset into the chosen project-local location when authorized; pin provenance and preserve licenses. Avoid duplicate skills, entire plugin bundles and blind catalog installs.

Tool integrations and skills are separate: a design skill does not grant Sketch/Figma access, and an installed skill is not necessarily loaded by every agent client. Verify each client's discovery convention and document any thin adapter/explicit entry prompt. Do not change global settings or credentials as a side effect of project setup.

## Establish the operating loop

Encode these outcomes in the project workflow, using its language and conventions:

1. Start/resume: read entry point and current state; inspect actual artifacts/diff and affected contracts before claiming a feature is absent. Already-open chats re-read changed instructions from disk and reconcile their current task; they do not restart it or rerun setup merely to refresh context.
2. Scope/claim: reuse the task, choose bounded acceptance and checks; identify ownership and shared surfaces. Owner fields are advisory, not atomic locks. Coordinate overlaps or use independent surfaces; separate worktrees still need a shared coordination point.
3. Design → code: identify saved design version and stable source IDs, behavior/copy/components/states; record native differences. Refresh design sources before dependent work. Design-ready, implemented and verified remain separate.
4. Verify/review: check changed behavior and relevant visual/accessibility/localization/security/platform constraints. Review the final diff against acceptance. Mock tests and successful compilation do not prove runtime/hardware acceptance.
5. Finish/interruption: persist actual checks/failures, limits, changed contracts/state and one actionable next step before the final handoff when possible. After an abrupt interruption, reconcile the diff; do not assume the last record was saved.

For “continue this project”, reconstruct priorities and choose the highest-priority actionable unfinished slice within the existing scope; explain and proceed. If the first slice needs unavailable hardware/access, retain its open acceptance and advance independent useful work. Ask only for material unknowns, genuine ownership conflicts or scope-changing choices. Saved next steps do not authorize deployment, messages, new agents or other external actions.

`done` means the bounded task's acceptance is met on the identified final artifact. Subsequent changes invalidate affected evidence. Product release readiness is a separate gate involving the project's actual compatibility, testing, delivery and operational requirements.

## Validate and deliver

Use [validation](references/validation.md) to review a fresh-chat continuation, interrupted migration, design handoff and unavailable-tool scenario. Review affected links and facts, use the project's existing checks, and run `git diff --check` when Git is available. Fix actionable failures, inspect final scope and record checks actually performed. Do not add a runtime, custom validator, CI job or test framework solely for workflow documentation.

Provide concrete changed files, adopted document roles, installed/retained/skipped skills with reasons, remaining access/verification limits, and short prompts for the next code/design chat. Complete authorized setup; do not stop with a file list or proposal. Leave no generated placeholder contracts presented as complete.
