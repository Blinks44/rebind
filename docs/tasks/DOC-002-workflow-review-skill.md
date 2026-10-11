# DOC-002 — reusable agent workflow

- Updated: 2026-10-11
- Stage: done (documentation/skill scope; product acceptance remains open)
- Owner: Unassigned; completed documentation ownership released
- Requirements: Domain-adaptive development/design workflow, role-aware short requests/named handoffs and project-specific Git hygiene; English, commit-ready records; instruction-only skill
- Baseline: initial migration `6c1a5be`; continuation review `f549764`; portable adoption feedback reviewed at `365db64` plus uncommitted skill/docs changes. This task does not change app implementation.

## Outcome

Created [agent-workflow-setup 1.3.0](../../.agents/skills/agent-workflow-setup/README.md), a self-contained MIT skill with domain-adaptive project adoption, short role-aware requests, document contracts, selective skill review/install, named contract/design handoffs, project-specific Git hygiene, local-by-default verification screenshots and review scenarios. Existing 11 third-party skill records and licenses are retained.

The workflow now covers selecting the next actionable unfinished slice, interruption recovery, advisory ownership, separately versioned code/design and verification of the final artifact. Shared records use English technical summaries. Reported results retain scope and evidence limits without quoting replies.

## Acceptance

- [x] Current-context/continuation, interruption and ownership rules documented.
- [x] Design-ready, implementation, verification and release readiness remain distinct.
- [x] Shared documentation is commit-ready; local transcripts/backups/access hints are excluded.
- [x] Instruction-only skill with metadata/references and scoped MIT license; custom checker and tests removed.
- [x] Affected documents/links and final diff reviewed; product gates unchanged.
- [x] Domain examples are non-exhaustive; unfamiliar projects derive contracts/checks from real artifacts/tools without mandatory app/UI scaffolding.
- [x] Git ignore adaptation is part of setup, with relevant commented sections, excluded/kept path checks and no automatic untracking.
- [x] Short role-aware continuation and named feature/transfer rules resolve from durable records without mandatory IDs; reporting identifies readiness/open work/next role. Independent read-only code/design context recovery tested on a web project; full feature/design execution remains untested.

## Verification and limits

Documentation/source inspection, affected local links/anchors, skill metadata/resource/version consistency and `git diff --check`; no Rebind app build, runtime/hardware test or live Sketch edit in this task. The skill's [validation guide](../../.agents/skills/agent-workflow-setup/references/validation.md) covers adoption and role-aware continuation cases; version-specific checks are below. Earlier reviews were author-performed. Subsequent web adoption and independent read-only continuation checks are scoped below; they do not establish a full feature/design delivery cycle.

The 1.0.2 review checked 60 Markdown files and 258 local links/anchors without missing targets/anchors. Shared Markdown scan found no Cyrillic text, personal workstation paths or removed checker references. The manifest preserves all 11 third-party records; local raw backups/access hints are ignored and not tracked. The 1.1.0 checks below cover the added guidance and current ignore policy.

## Final workflow review — 2026-10-10

- Root README describes the actual product, availability/limits, stack, source build/run and first launch. Commands match `scripts/dev.sh`; internal prompts and session state are routed to docs. The skill's document contract teaches this same public-facing role without inventing releases or an app license.
- AGENTS routes both agents to current state, affected requirements/task, actual artifacts and relevant skills. The portable contract covers detected stack, exact commands, boundaries, verification and completion rather than copying Rebind's platform rules.
- STATE/PLAN/tasks distinguish implemented artifacts, reported subsets and open acceptance. Design source/version and saved design remain separate from native implementation and runtime checks. Continuation does not require an old transcript.
- Fixed stale snapshot references and a docs-index sentence that incorrectly routed session transcripts into shared documents. Preserved the older software-check commands/results as a concise technical register and corrected evidence-link labels. Local raw backups/access hints remain ignored, while shared tasks/state/evidence remain versioned.
- Added explicit refresh instructions for already-open chats, neutral confirmation guidance directly in the task template, and staged-diff review when committing is requested. Unknown test conditions remain unknown; design acceptance does not become runtime verification.
- Skill 1.0.2 carries these rules into other projects, retains selective licensed skill installation and has no project/runtime dependency. No extra workflow files, validators or Python helpers added by this review.

Raw migration snapshots and workstation access hints are retained only in ignored local storage. The discarded helper code was removed. The delivered skill has no scripts, runtime, package or CI dependency. No publication, global settings, unrelated skill install or app-wide license change.

## Domain adaptation and repository hygiene — 2026-10-10

- Skill 1.1.0 derives the workflow from actual deliverables, editable inputs, tools, target environments and acceptance evidence. The examples are not a platform/language allowlist. README/setup/checks and contract handoffs adapt to the project; a visual design pipeline is conditional.
- Added [repository hygiene](../../.agents/skills/agent-workflow-setup/references/repository-hygiene.md) as part of setup: inspect existing/nested rules and tracked artifacts, write relevant commented sections, preserve justified exceptions and test both excluded and kept inputs. No blanket stack template, whole-agent-directory ignore, global Git mutation or automatic untracking.
- Rebind `.gitignore` now explains shared-file policy and separates build, transient verification, editor/OS, local-agent and package state. Removed the unrelated IPA rule. Actual Git checks caught root-only SPM cache/security exclusions missing the standalone probe; changed them to cover root and nested packages. Shared skills/docs/tasks, source, assets, schemes and lockfiles remain visible.
- During this session another checkout writer advanced HEAD to `f549764` (`feat: phase 5`), including the earlier ignore reorganization. Preserved that commit and current product records. This task did not create a commit or change application code.
- Final verification: Git matching passed 19 excluded and 20 kept representative paths, including root/nested SPM state; `git ls-files --cached --ignored --exclude-standard` found no tracked-rule conflicts. The initial sample traversed an SPM symlink and was corrected to a direct output path; initial missing nested cache/security rules were fixed before the passing run. Skill Creator's built-in `quick_validate.py` passed using its existing external runtime; no helper/runtime was added to the project. Document check passed 62 Markdown files / 280 local links and anchors. Nine skill instruction/metadata/license files, version 1.1.0 consistency, unchanged 11 third-party records and `git diff --check` pass. Author-reviewed scenarios remain distinct from independent adoption tests.

## Short-request continuation review — 2026-10-10

Findings resolved in skill 1.2.0 and project instructions:

- Global next-task selection could route a designer to the highest-priority hardware gate. Added role-first selection and role-specific STATE recommendations referencing the existing tasks/plan.
- Examples required the user to supply `UI-001` and internal file names. Replaced them with sufficient short requests; agents resolve outcomes, IDs and handoffs themselves. Specific features select their outcome ahead of the default next item, while “continue the task” preserves the current chat's task.
- Partially saved design could be mistaken for whole-task implementation readiness. The task template and first-run/permissions handoff now identify ready scope, design dependency and next action per relevant role. Current umbrella acceptance remains open.
- User-facing completion lacked a concrete role-transfer contract. Agents now report meaningful outcome names, readiness, open checks and the next responsible role, with an optional short transfer request. Saving the handoff is automatic completion work.
- Clarified that explicit design continuation authorizes bounded edits to an established source; setup alone does not. Known sources/frames are resolved from project records and live tools without asking for omitted IDs. Missing access or actual ambiguity remains a legitimate question.
- Added seven role/feature/transfer/block scenarios to the existing 16-case review guide. No new runtime, script, task-board duplicate, agent spawning or app/Sketch changes.

Author walkthrough against the current project records:

| Short request | Record-based selection and preserved limit |
| --- | --- |
| Continue the design | First-run/permissions: missing-permission main-window and Settings → Permissions states; preserves input hardware gates and delivered icons. |
| Continue development | Existing core acceptance first when usable evidence/access is available, otherwise independent engineering or a verified ready bounded handoff; never treats the full permissions flow as ready. |
| Continue the task | Preserves this chat's workflow-review outcome; a fresh chat with ambiguous competing outcomes uses role/default and asks only a material outcome question. |
| Add first-run permissions / implement the prepared permissions flow | Matches the existing named task instead of creating a duplicate; refreshes its partial design/source and scope before implementation. |

Final checks: Skill Creator's built-in validator passed; metadata/README/manifest version 1.2.0 and nine instruction/metadata/license files are consistent. All 11 third-party skill records match HEAD. Local document check passed 62 Markdown files / 280 links and anchors. STATE stays below 8 KiB with dated role recommendations; outdated ID-dependent prompts and global input-first continuation text were removed from current entry points. `git diff --check` passes. Concurrent input-task/code changes were preserved. These checks and the 23-scenario author review do not claim an independently executed live design-to-code cycle or automatic shared chat memory.

Semantic request review: the instruction-only skill contains no executable request parser or alias table. Project/skill rules now explicitly interpret intended action/outcome and established context in the user's language; examples are illustrative. Tool/language qualifiers constrain sources/modules and do not independently select a role or authorize migration/install. Reviewed equivalent wording, design inspection versus edits, and language-qualified implementation as an additional scenario. Exact user phrases were not copied into routing rules. Final checks passed the built-in skill validator, 62 Markdown files / 284 local links and anchors, nine skill files and a 24-scenario review guide; the shared instruction scan found no Cyrillic text or personal workstation paths. The review remains instruction/artifact inspection, not a live independent-agent execution guarantee.

## Portable adoption feedback — 2026-10-10

An independent agent used skill 1.2.0 on a public company-news frontend with TanStack Start, React, TypeScript, Tailwind, Query and Nitro; Strapi belongs to a separate unavailable repository. The initial setup connected project-specific instructions, public README, state, combined product requirements/plan, design/API contracts and tasks. The combined document roles were appropriate for the small scaffold; missing product details remained unknown rather than fabricated.

First-pass findings and evaluator repairs are distinct:

- The author deferred additional skill selection until feature implementation without actual candidate research. This left the setup's project-skill assessment incomplete, despite useful context documents. Version 1.2.1 requires documented discovery for upcoming work even in documentation-only setup, with reviewed choices or a visible pending gap; it imposes no installation quota.
- Review corrected a draft README claim that the lockfile was committed while the repository had no commits. Final validation now explicitly compares version-control and installed/prepared claims with observed artifacts.
- The applying reviewer closed the setup task/state but missed its remaining installation gate in the roadmap. Version 1.2.1 requires reconciliation of affected current owning records after a gate closes, with staged-delivery responsibility explicit. This was a reviewer omission, not a failed role-selection check.
- Two fresh agents without prior history independently selected code runtime-baseline work and design reader-proposal work from disk. Both matched the source/configuration digest, preserved unknown design/API decisions and distinguished isolated build checks from unrun runtime/CMS checks. Their read-only scope did not exercise automatic post-feature persistence, client auto-discovery or a full design-to-code cycle.

The isolated scaffold build and compiler checks passed, with bundler warnings retained in the receiving project's evidence. No Rebind source, existing third-party skill or live Sketch artwork was changed. The adoption prompted a narrow four-file instruction update, two regression scenarios and version/provenance updates; no helper runtime or scripts were added.

Independent regression audit: a fresh agent used 1.2.1 on an isolated dependency-free copy, retained the combined document mapping, researched/pinned candidates, installed a licensed instruction-only framework subset and repaired the stale roadmap/manifest without guidance about the intended findings. Its checks covered 18 Markdown files / 46 local links, 16 excluded / 19 kept Git samples, whitespace and preservation of its index plus 35 unrelated inputs. This was actual setup/audit execution; feature/design continuation in that run was a written review. A later package-resource inventory clarification was author-reviewed.

Receiving-project follow-up retained six reviewed package-supplied resources and installed three instruction-only skills for missing React routing/Query composition and web interface review, with pinned sources, full MIT notices and compatibility overrides. Final client-format validation rejected the official TanStack snapshots' top-level `requires`/`sources` extensions; they were preserved as string metadata with attribution, then passed validation. This was a local adaptation under the existing review/validation contract, not a reason to impose those skills on other stacks. Installed checks passed four project skill validators, six bundled path/version/digest checks, 23 Markdown files / 66 local links and anchors, whitespace, unchanged Git index and 27 unrelated pre-setup inputs. Existing setup instructions were intentionally updated; app source/dependencies/editor inputs were preserved. Runtime/client auto-discovery/full feature-cycle limits remain open.

## Next handoff

Maintain the canonical package in the standalone skills repository, under `agent-workflow-setup/`; Rebind retains a versioned project-local snapshot and provenance entry. Next skill check: exercise guided initialization on a real new project, especially a missing product decision, before claiming behavioral validation. Existing chats can refresh the updated skill when configuring workflow; ordinary Rebind development continues under project instructions. Input, permissions and icon runtime tasks retain open acceptance.

## Direct Sketch workflow simplification — 2026-10-11

AGENTS, WORKFLOW and the task template now make the editable Sketch document self-contained and require the implementation agent to inspect it through MCP. Design completion uses a short source/date/readiness/next-step note; routine PNG export, mirrored frame/style inventory and separate visual implementation manuals are not required. DESIGN and the materials record were shortened. Removed 79 obsolete Sketch-only PNG copies (13,779,189 bytes) and redirected their links to the live-source locator. Kept native screenshots, behavioral/resize history, historical localization fixtures, the compile-only API probe and shipped icon assets. Advanced copy is in Sketch Foundations, so its temporary duplicate JSON was removed. No reusable skill installation/version change, app build/runtime test or Git commit. Reviewed 261 affected local links/anchors, repaired two historical material-review anchors, and passed `git diff --check`; native acceptance remains separate.

## Verification screenshots local by default — 2026-10-11

- Skill 1.2.2 and AGENTS/WORKFLOW/DESIGN/ENGINEERING now keep verification screenshots and exports local by default, including native app regression checks. Use ignored `.local/agent-context/verification/` or temporary storage. Git keeps concise, self-contained results identifying the tested artifact/environment, commands, observations and limits.
- A versioned image needs a specific documented purpose: requested deliverable, shipped asset, required visual-test baseline, or defect evidence that a written result cannot adequately preserve. Ordinary visual review is insufficient. No blanket image ignore, automatic deletion/untracking or routine approval gate was added. Existing native images, fixtures and concurrent implementation are preserved.
- Portable design guidance now uses a short source/version/readiness note when the receiving agent can inspect the editable source directly; components/states/copy/annotations stay in that source. No routine PNG handoff, mirrored inventory or visual implementation manual. Skill README/metadata/manifest agree on 1.2.2; third-party skill records and licenses are unchanged.
- Verification: Skill Creator's built-in `quick_validate.py` passed using existing external PyYAML dependencies. The first system-Python attempt lacked PyYAML; no dependency/runtime was installed or added to the repository. Final checks passed: 149 local links/anchors across 14 affected Markdown files; 5 excluded and 9 kept Git path samples; no tracked-ignore conflicts; matching skill/README/manifest version 1.2.2 and unchanged third-party manifest records; `git diff --check`. Written review covers ordinary screenshots versus required assets/baselines; no independent agent execution, app build/runtime check, Sketch edit/save or Git commit.
- Ownership released on completion. Next: resume Mouse rules and editor in live Sketch; future visual checks follow this policy. Historical native-image cleanup is a separate scoped operation.

## Verification image cleanup — 2026-10-11

- User-authorized cleanup moved the remaining 29 native verification captures (24 PNG / 5 JPG, 4,819,923 bytes) out of repository output into ignored `.local/agent-context/verification/2026-10-11-cleanup/`. Every local copy was SHA-256 checked before removing its repository copy; no image was irreversibly discarded. This supersedes the earlier decision to retain those native screenshots in Git.
- `.gitignore` now excludes PNG/JPG/JPEG captures only under `docs/verification/`, in addition to the existing ignored local directory. App/brand assets, test fixtures, concise reports, shared instructions and skills remain visible; a justified versioned verification image requires a documented purpose and narrow exception.
- Replaced 29 capture links in five verification reports with the reviewed state names and a dated cleanup notice. Commands, observed results and acceptance limits are preserved. General/Input/Language task notes no longer advertise deleted Sketch PNG handoffs. Shipped icon/vector inputs, README/brand previews, historical localization data and the SwiftUI feasibility probe are retained. No application/test source, Sketch source, real configuration or permissions were changed.
- Final checks passed: 182 local links/anchors across 17 Markdown files; all 29 local copies match their recorded SHA-256; no verification PNG/JPG/JPEG files remain in the checkout; 9 excluded and 15 kept Git path samples; `git diff --check`. Git reports 57 tracked-ignore matches, all absent files with unstaged deletions (including the earlier Sketch cleanup), with no retained-file conflict. No app build/runtime check, Sketch save, staging, Git commit or history rewrite. Tracked image deletions remain ordinary unstaged changes for review/commit; ignore rules alone do not remove old Git history.
- Ownership released on completion. Next: resume Mouse rules and editor in live Sketch, storing future captures locally.

## Standalone skills repository and guided initialization — 2026-10-11

- Copied the complete nine-file MIT package into the dedicated skills repository as `agent-workflow-setup/`. Added a public repository README and a commented `.gitignore`; initialized local Git on `main` for the requested repository. No commit, remote, publication or global skill installation. Rebind's existing skill remains an installed snapshot, synchronized to 1.3.0; only its own manifest record changed, preserving all third-party records/licenses.
- Version 1.3.0 adds evidence-first guided initialization: inspect before asking, distinguish facts/defaults/material decisions, offer focused questions with recommendations and tradeoffs, reuse answers and persist distilled technical decisions. Unanswered required choices keep dependent work pending while independent setup continues. Clients without interactive input tools use ordinary conversation. No mandatory questionnaire, invented stack, duplicate answer registry or extra runtime.
- Added five written review scenarios: empty project, already-complete context, conflicting sources, unanswered required decision and interrupted setup. Author review confirms the intended distinctions; no fresh-agent conversation or real-project execution of the new question flow was performed. Existing document, candidate-skill, image and authorization contracts are retained.
- Installed checks: Skill Creator's existing `quick_validate.py` passed for the standalone and project-local packages using the already available external PyYAML environment. All 11 distributable files match the prepared outcome; the two nine-file skill packages match byte-for-byte, including the unchanged MIT notice and client metadata. Git matching passed 15 excluded / 20 kept paths in the installed repository, including nested IDE folders and shared skills/assets/scripts. No tracked-ignore conflicts in the new repository; per-file whitespace checks cover its untracked files. Local review passed 8 Markdown files / 19 links and anchors before transfer, and installed files match that review. Final local links/anchors passed across 18 Markdown files / 136 references; `git diff --check` passed in both repositories, with separate whitespace checks for the new untracked files. During this task Rebind HEAD advanced independently from `b453d8d` to `33b54a1`; that commit and the other work were preserved. This task made no Git commit.
- Ownership: `/root`, scoped to this skill/package, its provenance entry and this task/state/history update; released on completion. Existing concurrent image cleanup and application work are preserved. Next: validate the new question flow during an actual project setup, then make evidence-based refinements in the standalone source and deliberately update installed snapshots.
