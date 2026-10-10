# Agent Workflow Setup

A reusable Agent Skill for setting up or reviewing project context for coding and design agents. It supports new and existing macOS/iOS, web, backend, library and mixed projects by adapting to their actual stack and documents.

It teaches an agent to inspect the repository, preserve existing work, select relevant reviewed skills, maintain a public README, establish current state/requirements/design/task handoffs, and verify the resulting workflow. It does not require every project to use the same filenames or install a catalog of skills.

## Use

Copy this **whole folder**, including references, metadata and LICENSE, into the target repository at `.agents/skills/agent-workflow-setup/` for Codex. Avoid nesting another copy inside it. Other Agent Skill clients need their supported skill location/discovery mechanism. Skill/tool discovery is separate from access to the project's design editor or task tracker.

Example prompt:

> Use $agent-workflow-setup to configure a modern development and design workflow in this project. Inspect the existing stack, implementation and documentation; preserve existing work, install relevant reviewed project-local skills where needed, and make it possible for a new agent to continue from current project records. Complete and verify the setup.

For an audit/update, specify that mode and existing constraints. For a brand-new project, also give the product goal and intended platform; the skill does not choose those for you.

After setup, use the project's entry point for ordinary work: “Follow AGENTS.md and continue the next actionable unfinished slice.” Tell already-open chats to re-read updated instructions and current records while preserving their task. Rerun this skill for a workflow audit or migration, not every feature request.

Repository documentation and skill content use English by default. You can communicate with the agent in any language. Setup produces commit-ready technical records; raw transcripts, quoted replies, personal paths and local user data stay out of shared docs. Localized product content is preserved.

## Checks and distribution

This is an instruction-only skill: no scripts, runtime or package dependencies. See [validation](references/validation.md) for document and scenario review using existing project tools.

Version **1.0.2**. Publish this folder independently; it has no dependency on Rebind files or other bundled skills. Its [MIT license](LICENSE) covers this folder only, not the host app or separately installed third-party skills. No external skills are redistributed here. For marketplace distribution, follow the current [Codex plugin guidance](https://learn.chatgpt.com/docs/build-skills#distribute-skills-with-plugins); no plugin/server is necessary for local repository use.
