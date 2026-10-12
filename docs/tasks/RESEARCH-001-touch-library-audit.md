# RESEARCH-001 — Reusable touch acquisition and gesture implementations

- Updated: 2026-10-12.
- Stage: `done` (bounded source audit; hardware/integration gates remain open).
- Owner: Unassigned; `/root` released the completed audit on 2026-10-12.
- Ownership checked: `main` / `59f5754` plus existing uncommitted UI/design records; no engine ownership claimed.
- Owned surfaces: scoped research/audit record, dependency register and affected status sections. Preserve app/probe dependencies, input code, rules and design.
- Requirements: SPEC §§3.4–3.5, 6; research/dependency policy; conditional conflict-free preset proposal.

## Outcome

Search Apple APIs, GitHub and Swift Package Index beyond prior candidates. Compare actual acquisition, recognizers and selective suppression; inspect manifests, license/provenance, maintenance and safety. Find reusable Swift packages or narrowly reusable permissive implementations without installing them. Evaluate a conflict-free initial preset pool as a proposal; do not silently remove existing bindings or reduce the final product contract.

## Acceptance

- [x] Broad candidate search, primary-source code/manifest/license and maintenance audit.
- [x] Recommend an actionable bounded reuse path with limits and no inferred hardware support.
- [x] Identify candidate/conflicting presets against Apple's current gesture documentation; retain real-device verification.
- [x] Research/register/STATE handoff, affected-link review and `git diff --check`.

## Next step

[Audit](../research/touch-library-audit.md) records twelve pinned repositories, native API and SPI limits, licenses/packaging/maintenance, actual callback/filter distinctions and the candidate first pool. No package/source installed or executed; no engine/settings/rules/SPEC change. Affected links and `git diff --check` pass.

Next evaluate an isolated MIT MagicBind reader/types + CalmMouseCore arbitration path on a named Magic Mouse, and compare the already pinned Subsurface acquisition in the standalone Trackpad probe. Preserve bounded synchronous callbacks, ordered loss-aware handoff and category-wide rules; verify click/scroll/native coexistence and lifecycle before app integration. Four-finger Trackpad stationary taps are the strongest proposed initial pool; absence from Apple documentation does not establish conflict-free hardware support.
