# Rebind documentation

The [root README](../README.md) is the public project overview: what Rebind does, current availability, technology, building and first launch. Keep detailed development status, operational notes and agent instructions here.

| Document | Purpose |
| --- | --- |
| [DEVELOPMENT](DEVELOPMENT.md) | Build/test commands, toolchain/signing, permissions and detailed rule semantics |
| [SPEC](SPEC.md) | Required product behavior and acceptance |
| [CAPABILITIES](CAPABILITIES.md) | Actual implementation/evidence and limits |
| [PLAN](PLAN.md) | Roadmap and remaining phase gates |
| [DESIGN](DESIGN.md) | Modern macOS direction and current Sketch source/frame index |
| [ENGINEERING](ENGINEERING.md) | Platform, input/concurrency, localization/security and dependency conventions |
| [verification](verification/) | Detailed behavior contracts and software/native/hardware checks |
| [research](research/README.md) | Current mechanism decisions and dependency/license references |

For agents and multi-session contribution, start with [AGENTS](../AGENTS.md) and [STATE](STATE.md), then the relevant [task](tasks/README.md). [WORKFLOW](WORKFLOW.md) defines ownership, fresh context, design/code handoff and completion updates. [History](history/README.md) records dated technical outcomes and earlier evidence, which may contain superseded decisions.

Reusable setup: [Agent Workflow Setup](../.agents/skills/agent-workflow-setup/README.md) is a self-contained MIT skill for configuring this pattern in other new/existing projects. Its license covers only that folder. [DOC-002](tasks/DOC-002-workflow-review-skill.md) records the review, corrections and verification limits.

Update the root README when the public feature set, supported platform or basic setup changes. Keep scoped test results, task owners, evolving thresholds and agent prompts in their owning documents; link rather than duplicating them in the front page. Raw chat/tool transcripts and verbatim replies stay out of shared documentation.
