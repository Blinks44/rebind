# Adopting an existing or new project

## Inventory and reconciliation

Capture branch/HEAD/status and preserve unrelated changes. Inspect project/package manifests, source entry points, deployment/support targets, test/build scripts, CI and dependency lockfiles. Read existing AGENTS/override/nested instruction files and any client-specific entry points. Note which instructions actually load in each agent environment; a file's existence is not proof of discovery.

Identify where product intent, current work, decisions and design live today. A maintained issue tracker can own tasks: use links and a short local index rather than copying a second backlog. Offline access must be explicit; note the date of any cached tracker snapshot. Existing `ARCHITECTURE.md`, `CONTRIBUTING.md` or `ROADMAP.md` can fulfill the corresponding role without renaming them.

Reconcile proposed docs with code/assets and recent relevant changes. For each ambiguous fact use evidence, or label it unverified. An unchecked old task may already have partial code; a screenshot may be only a proposal. Do not mark all legacy tasks complete or infer approval from a mockup. Preserve user requirements separately from withdrawn or superseded decisions.

Before restructuring large documents, preserve useful information through existing Git history or a local migration backup. Migrate current facts and decisions into their owners. Do not create a committed copy of a raw session log; publish only sanitized technical history when it is useful, with corrected links and an explicit historical notice. An archive is evidence, never part of routine startup. Avoid deleting files with unknown callers. Do not commit, reset or publish simply to facilitate migration.

## Scale the structure to the project

- Small project: concise AGENTS, public README, current state and requirements/plan may be sufficient; design/task detail can be sections rather than directories.
- Multi-session UI app: add a design contract and task handoff records; keep the engineering guide separate when rules are substantial.
- Backend/library: use API/schema/compatibility contracts and relevant data migration/operation/release evidence; do not manufacture a visual design pipeline.
- Monorepo: root context covers shared product/contracts; module instructions cover local commands and boundaries. Use stable task links and shared API/schema versions for dependent frontend/backend work. Avoid a single mandatory map of every service.

Names in this skill are examples, not mandatory filenames. Record the chosen mapping once and reuse it. Separate required behavior from discovered implementation and keep public claims no stronger than evidence permits.

## Safe, repeatable adoption

On a second invocation, inspect the existing mapping and improve only demonstrated gaps. Do not reset state/backlog, generate new task IDs for the same outcome, reinstall identical skills or create another archive without changed content. Preserve dates/results of prior verification; only update them after actual checks. Refresh pins deliberately, not whenever a skill is used.

Record an unknown next step as a proposed bounded action, not as a feature requirement invented by setup. If product direction is missing, complete the repository inventory and ask the necessary product question while retaining useful setup work.

Configure local docs/skills within the requested scope. Setup is not permission to edit a live design document, execute application actions, connect accounts, install global tooling, change secrets, deploy, create/message agents, or run package-provided scripts. Use existing authorizations for actions genuinely requested; avoid new ceremonial approvals.

## Design source options

Use the project's established source: live Sketch/Figma, repo-native components/tokens, or another named artifact. An accessible authoritative export can be used if it is explicitly the current design contract; label its version and limits. Do not insist on an external editor for a code-native UI, or invent a current visual source when the live document is inaccessible. Record proposed exploration separately from an accepted implementation contract.

Handoff evidence identifies source link/path, saved version/revision/digest where available, stable frames/component IDs, applicable states, behavior/copy and changed scope. Local machine absolute paths need a portable share/access instruction for other machines. Re-resolve session-specific document IDs instead of treating them as permanent identity.

Before implementing a changed design, reconcile affected code/capabilities and preserve real state/data behavior. After implementation, check the rendered interface against the same design revision and record justified platform differences. Later design revisions do not automatically change the native app.

## Multi-agent access

Both coding and design agents need the entry point, state and affected task. If one client cannot read the repository, supply a compact handoff and establish who writes its outcome back; do not claim automatic synchronization. For separate clones/worktrees, record code revisions and intended integration; for design outside Git, record saved design version separately.

Give the user a prompt to refresh already-open chats after setup: re-read updated instructions/current records, reconcile actual edits and continue their authorized task. Do not assume those chats reload instructions automatically or require a new chat for every small edit. Subsequent product work follows the entry point; setup is used again for a workflow audit or migration.

Owner records include time/revision, scope and transfer/release. They are a coordination aid: two writers can race. Existing active overlap requires coordination, a single shared task board, or independent work. Do not create agents as part of setup unless explicitly authorized.
