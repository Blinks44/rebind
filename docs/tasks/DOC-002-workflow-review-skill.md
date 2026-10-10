# DOC-002 — reusable agent workflow

- Updated: 2026-10-10
- Stage: done (documentation/skill scope; product acceptance remains open)
- Owner: Unassigned; completed documentation ownership released
- Requirements: Portable development/design workflow; English, commit-ready records; instruction-only skill
- Baseline: `6c1a5be` plus uncommitted documentation changes; app implementation unchanged

## Outcome

Created [agent-workflow-setup 1.0.2](../../.agents/skills/agent-workflow-setup/README.md), a self-contained MIT skill with project-adoption guidance, document contracts, selective skill review/install, design/code handoffs and review scenarios. Existing 11 third-party skill records and licenses are retained.

The workflow now covers selecting the next actionable unfinished slice, interruption recovery, advisory ownership, separately versioned code/design and verification of the final artifact. Shared records use English technical summaries. Reported results retain scope and evidence limits without quoting replies.

## Acceptance

- [x] Current-context/continuation, interruption and ownership rules documented.
- [x] Design-ready, implementation, verification and release readiness remain distinct.
- [x] Shared documentation is commit-ready; local transcripts/backups/access hints are excluded.
- [x] Instruction-only skill with metadata/references and scoped MIT license; custom checker and tests removed.
- [x] Affected documents/links and final diff reviewed; product gates unchanged.

## Verification and limits

Documentation/source inspection, affected local links/anchors, skill metadata/resource/version consistency and `git diff --check`; no app build, runtime/hardware test or live Sketch edit. Reviewed the 12 scenarios in the skill's [validation guide](../../.agents/skills/agent-workflow-setup/references/validation.md): stack adaptation, continuation, interrupted work, design access, overlapping ownership, offline skill review, informal test reports, already-open chats and repeated setup. These are author-performed reviews, not independent end-to-end adoption in other projects.

Final document check: 60 Markdown files and 258 local links/anchors, no missing targets/anchors. Shared Markdown scan found no Cyrillic text, personal workstation paths or removed checker references. Skill metadata/version/license/resources are consistent; eight instruction/metadata/license files and no executable helpers. The manifest diff preserves all 11 third-party records. Local raw backups/access hints are ignored and not tracked. Final `git diff --check` passed.

## Final workflow review — 2026-10-10

- Root README describes the actual product, availability/limits, stack, source build/run and first launch. Commands match `scripts/dev.sh`; internal prompts and session state are routed to docs. The skill's document contract teaches this same public-facing role without inventing releases or an app license.
- AGENTS routes both agents to current state, affected requirements/task, actual artifacts and relevant skills. The portable contract covers detected stack, exact commands, boundaries, verification and completion rather than copying Rebind's platform rules.
- STATE/PLAN/tasks distinguish implemented artifacts, reported subsets and open acceptance. Design source/version and saved design remain separate from native implementation and runtime checks. Continuation does not require an old transcript.
- Fixed stale snapshot references and a docs-index sentence that incorrectly routed session transcripts into shared documents. Preserved the older software-check commands/results as a concise technical register and corrected evidence-link labels. Local raw backups/access hints remain ignored, while shared tasks/state/evidence remain versioned.
- Added explicit refresh instructions for already-open chats, neutral confirmation guidance directly in the task template, and staged-diff review when committing is requested. Unknown test conditions remain unknown; design acceptance does not become runtime verification.
- Skill 1.0.2 carries these rules into other projects, retains selective licensed skill installation and has no project/runtime dependency. No extra workflow files, validators or Python helpers added by this review.

Raw migration snapshots and workstation access hints are retained only in ignored local storage. The discarded helper code was removed. The delivered skill has no scripts, runtime, package or CI dependency. No publication, global settings, unrelated skill install or app-wide license change.

## Next handoff

Copy/publish the whole skill folder when requested. Continue the selected Rebind product task; INPUT-001, UI-001 and BRAND-001 retain their open acceptance. Refine the skill against demonstrated adoption results rather than adding speculative process/tooling.
