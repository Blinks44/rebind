# Validation and realistic review

## Document review

Review affected local links/anchors, document-role consistency and skill metadata/resources/licenses. Use existing documentation tooling when available, and run `git diff --check` for a Git project. Check that the entry point reaches current state/contracts/tasks without depending on local backups or previous chats.

Review publishability as part of completion: shared files use the chosen repository language, contain technical summaries instead of quoted replies, and omit raw chat/tool logs, personal absolute paths, real user data and temporary artifacts. Confirm that relevant ignore rules cover local-only material without hiding shared project context.

This instruction-only skill adds no checker scripts, runtime, packages, CI job or test framework. Use meaningful existing build/test checks for actual code/assets when required by the project; documentation-only setup does not need an application launch.

## Semantic audit

Check the process against actual artifacts and evidence:

- Does a new agent discover the intended entry point and reach all necessary current contracts without reading archives?
- Are implementation/capability claims consistent with source/artifacts and dated evidence? Are requirements and proposals separate?
- Can a reader identify the next actionable unfinished slice, owner/access needs and acceptance?
- Can another machine find the design source and code revision? Are session IDs lookup hints, not identity?
- Do design/copy states cover the bounded interaction and applicable responsive/accessibility/localization behavior?
- Do checks refer to the final artifact? Are failing/unrun/runtime/hardware checks still visible?
- Did migration preserve previous information and uncommitted work? Will another run avoid duplicates/reinstalls/status resets?
- Are public README claims honest and the installed skill set licensed, relevant and free of conflicting project rules?
- Can an already-open chat adopt changed instructions without losing its task? Are root README, AGENTS and shared docs each populated with project-specific content rather than template placeholders?

Fix concrete findings; do not claim a perfect or certified process from document completeness alone.

## Behavioral scenarios

Use the following to challenge the configured workflow. Distinguish a written scenario review from actual fresh-agent execution; report which was performed. If independent agent testing is authorized, use an isolated fixture and give only raw project artifacts, the skill and realistic request. Do not modify a live project during evaluation.

| Request / raw fixture | Expected observable result |
| --- | --- |
| “Set up this new SwiftUI app”; manifests and a few views | Detected Apple target; useful reviewed skills only; real build commands; no invented completed design/features |
| “Configure this existing web repo”; CONTRIBUTING/ADR/task tracker, dirty files | Reuses owning docs; preserves dirty files and old evidence; no duplicate backlog or macOS rules |
| “Set up backend agent work”; API/schema tests, no UI | API/data contract and relevant checks; no invented Sketch/design screen tree |
| “Continue the project”; old open task but partly implemented code | Reconciles diff/current source, retains existing code, chooses actionable acceptance or next bounded slice |
| High-priority item needs unavailable hardware | Retains that gate, moves independent authorized work forward; no mocked hardware-complete claim |
| Design document unavailable or later than implementation | Records missing access or revision discrepancy; no claim of design parity or invented latest source |
| Interrupted session with unsaved task status | Reads actual partial artifacts, distinguishes incomplete work/checks; no destructive restart |
| Two chats overlap a catalog/shared component | Recognizes advisory owner limits, coordinates or chooses independent surface; no silent takeover |
| Network unavailable for candidate skills | No guessed source/revision/review claims; useful docs created and install gap recorded |
| Invoke setup again on unchanged project | No duplicate IDs/files/backlogs or repeated installs; improves only demonstrated gaps |
| Informal success report with unknown build/conditions | Neutral scoped reported result, unknown fields retained, no quoted reply or broader verification/approval claim |
| Workflow updated while a feature chat is open | Re-reads changed instructions/current records, reconciles actual edits, preserves task/ownership and continues without rerunning setup |

Task completion and release readiness are separate. For shipping, use the project's real supported-platform, compatibility, meaningful tests, rendered UX and operational/distribution gates. Setting up this skill does not certify the resulting application or prove all agent-client behaviors.
