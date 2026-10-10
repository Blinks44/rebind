# DOC-001 — shared context for code/design agents

- Updated: 2026-10-10
- Stage: `done` (documentation scope only; product hardware/UI gates remain open)
- Owner: Completed by workflow-migration chat; shared documentation ownership released
- Owned surfaces: AGENTS, README document routing, SPEC routing/visual direction, new workflow/state/design/engineering/task/research/history records, PLAN migration and verification evidence pointers
- Requirements: User's 2026-10-10 workflow/design request; preserve SPEC behavior, original engineering rules and existing work
- Baseline: `6c1a5be` plus existing uncommitted PLAN/menu-bar verification work; original text captured before migration

## Outcome and acceptance

Let a fresh agent continue from project files, identify existing implementation and current Sketch sources, and leave a reviewable handoff. Keep requirements, implementation state, design and historical evidence separate. Explicitly record the user's modern macOS 26+ Liquid Glass/depth/gradient direction without changing app code or Sketch.

- [x] Short AGENTS/STATE/PLAN route to current contracts/tasks; original engineering standards retained and build/input/security/localization boundaries preserved.
- [x] Current design/source IDs refreshed through read-only Sketch MCP; implemented assets distinguished from pending native screens.
- [x] Useful earlier decisions/capabilities/task evidence preserved and indexed; raw migration backups are local-only.
- [x] No newly broken local links/anchors, schema reference matches source, entry points remain concise and `git diff --check` passes.
- [x] Existing unrelated work retained; no app/runtime/Sketch/settings changes or invented verification; next-chat/user workflow documented.

## Deliverables and verification

See [history entry](../history/2026-10.md), [WORKFLOW](../WORKFLOW.md), [STATE](../STATE.md), [DESIGN](../DESIGN.md) and [roadmap](../PLAN.md). Startup order, final-state updates, owner coordination, cross-checkout Git handoff and separately saved Sketch versions are explicit. Three pending product tasks seeded; none is marked done by this migration.

Verification covered document links/anchors, source schema 22, concise entry points and stored Sketch IDs against a read-only inspection. `git diff --check` passed. No new Xcode/hardware checks were performed. Public history now uses a [technical summary](../history/implementation-through-2026-10-10.md); raw backups and personal access hints are ignored locally. No custom document-checking tooling is required.

## Next handoff

Documentation ownership is released. Existing chats should re-read AGENTS/STATE and the affected task before continuing. Start a fresh same-project chat with the desired outcome or task ID; select pending input/permission/brand work as authorized by the user. No commit/push or global agent configuration was performed.
